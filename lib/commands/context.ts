import path from 'node:path';

import type {TimeoutValue} from '@appium/types';
import {Chromedriver} from 'appium-chromedriver';
import type {ChromedriverOpts} from 'appium-chromedriver';
import {errors} from 'appium/driver.js';
import {net} from 'appium/support.js';
import axios from 'axios';

import type {Mac2Driver} from '../driver.js';
import {log} from '../logger.js';
import type {CdpPage, CdpVersionInfo, WebViewDetails} from '../types.js';
import {getModuleRoot} from '../utils.js';

declare module '../driver.js' {
  interface Mac2Driver {
    getCurrentContext(...args: Parameters<typeof getCurrentContext>): ReturnType<typeof getCurrentContext>;
    getContexts(...args: Parameters<typeof getContexts>): ReturnType<typeof getContexts>;
    setContext(...args: Parameters<typeof setContext>): ReturnType<typeof setContext>;
    getWebViewDetails(...args: Parameters<typeof getWebViewDetails>): ReturnType<typeof getWebViewDetails>;
    macosGetContexts(...args: Parameters<typeof macosGetContexts>): ReturnType<typeof macosGetContexts>;
  }
}

export const NATIVE_APP = 'NATIVE_APP';
export const WEBVIEW_PREFIX = 'WEBVIEW_';
export const DEBUGGING_PORT_FLAG = '--remote-debugging-port';
const CHROMEDRIVER_AUTODOWNLOAD_FEATURE = 'chromedriver_autodownload';
const CDP_HOST = '127.0.0.1';
const CDP_REQUEST_TIMEOUT_MS = 10000;
const PORT_RANGE_START = 10900;
const PORT_RANGE_END = 11000;
const WEBVIEW_POLL_INTERVAL_MS = 500;

/**
 * @returns The name of the current context: `NATIVE_APP` or `WEBVIEW_<id>`.
 */
export async function getCurrentContext(this: Mac2Driver): Promise<string> {
  return this._currentContext ?? NATIVE_APP;
}

/**
 * @returns `NATIVE_APP` followed by one `WEBVIEW_<id>` entry per page found via CDP.
 */
export async function getContexts(this: Mac2Driver): Promise<string[]> {
  if (!this.isWebviewEnabled()) {
    return [NATIVE_APP];
  }
  const {pages} = await this.getWebViewDetails();
  return [NATIVE_APP, ...pages.map((page) => `${WEBVIEW_PREFIX}${page.id}`)];
}

/**
 * Switches the context. `NATIVE_APP` (or an empty name) goes back to WebDriverAgentMac,
 * `WEBVIEW_<id>` starts a Chromedriver attached to the given CDP page and proxies to it.
 *
 * @param name - The context name
 */
export async function setContext(this: Mac2Driver, name?: string | null): Promise<void> {
  if (!name || name === NATIVE_APP) {
    await this.stopChromedriver();
    return;
  }

  this.assertWebviewEnabled();
  const pageId = name.startsWith(WEBVIEW_PREFIX) ? name.slice(WEBVIEW_PREFIX.length) : name;
  const details = await this.getWebViewDetails();
  const page = details.pages.find((p) => p.id === pageId);
  if (!page) {
    throw new errors.InvalidArgumentError(`Web view not found: ${name}`);
  }
  if (/\bEdg\//.test(details.info?.Browser ?? '')) {
    throw new errors.InvalidArgumentError('Microsoft Edge web views are not supported');
  }
  const debuggerAddress = (page.webSocketDebuggerUrl ?? '').replace(/^wss?:\/\//, '').split('/')[0];
  if (!debuggerAddress) {
    throw new errors.InvalidArgumentError(`Web view '${name}' does not expose a debugger address`);
  }

  // Only one Chromedriver may be alive at a time, so a webview-to-webview switch replaces it
  await this.stopChromedriver();

  const cd = new Chromedriver(getChromedriverOpts.call(this, details));
  cd.on(Chromedriver.EVENT_CHANGED, (msg: {state: string}) => {
    // An unexpected exit must not leave the proxy pointing at a dead process
    if (msg.state === Chromedriver.STATE_STOPPED && this.chromedriver === cd) {
      this.log.warn('Chromedriver has stopped unexpectedly. Switching back to the native context');
      this.resetWebviewState();
    }
  });

  try {
    await cd.start({'goog:chromeOptions': {debuggerAddress}});
    await switchToPage(cd, page.id);
    // Timeouts belong to the session, but a new Chromedriver session starts with its defaults
    await cd.jwproxy.command('/timeouts', 'POST', getSessionTimeouts.call(this));
  } catch (e) {
    try {
      await cd.stop();
    } catch {}
    throw e;
  }
  this.chromedriver = cd;
  this._currentContext = `${WEBVIEW_PREFIX}${page.id}`;
}

/**
 * The session timeouts, including explicit `null` (no timeout), to apply to a new Chromedriver session.
 */
export function getSessionTimeouts(this: Mac2Driver): {
  implicit: TimeoutValue;
  pageLoad: TimeoutValue;
  script: TimeoutValue;
} {
  return {implicit: this.implicitWaitMs, pageLoad: this.pageLoadTimeoutMs, script: this.scriptTimeoutMs};
}

/**
 * Chromedriver attaches to the browser, so the requested page must be selected explicitly.
 *
 * @param cd - Started Chromedriver
 * @param pageId - The CDP target id of the page
 */
export async function switchToPage(cd: Pick<Chromedriver, 'jwproxy'>, pageId: string): Promise<void> {
  const handles: string[] = await cd.jwproxy.command('/window/handles', 'GET');
  const handle = handles.find((h) => h === pageId || h === `CDwindow-${pageId}`);
  if (!handle) {
    throw new errors.NoSuchWindowError(`Chromedriver does not see the web view '${pageId}'`);
  }
  await cd.jwproxy.command('/window', 'POST', {handle});
}

/**
 * @param details - The web view details
 * @returns Chromedriver options. The download is only enabled by the `chromedriver_autodownload` feature.
 */
export function getChromedriverOpts(this: Mac2Driver, details: WebViewDetails): ChromedriverOpts {
  const {chromedriverExecutable, chromedriverExecutableDir} = this.opts;
  return {
    details: details.info ? {info: {Browser: details.info.Browser}} : undefined,
    ...(chromedriverExecutable ? {executable: chromedriverExecutable} : {}),
    // Any explicit dir makes Chromedriver select a version matching the app instead of a fixed default
    executableDir: chromedriverExecutableDir ?? path.join(getModuleRoot(), 'chromedriver'),
    isAutodownloadEnabled: this.isFeatureEnabled(CHROMEDRIVER_AUTODOWNLOAD_FEATURE),
    ...(this.basePath ? {reqBasePath: this.basePath} : {}),
  };
}

/**
 * @returns Browser info and the list of pages reported by the CDP endpoint of the app.
 * Unreachable endpoint yields no pages.
 */
export async function getWebViewDetails(this: Mac2Driver): Promise<WebViewDetails> {
  this.assertWebviewEnabled();
  const port = this._webviewDevtoolsPort;
  if (!port) {
    throw new errors.InvalidArgumentError('The web view debugging port is not known');
  }
  const [info, pages] = await Promise.all([
    cdpRequest<CdpVersionInfo>(this, port, '/json/version'),
    cdpRequest<CdpPage[]>(this, port, '/json/list'),
  ]);
  return {
    port,
    info: info ?? undefined,
    pages: (pages ?? []).filter((page) => page.type === 'page'),
  };
}

/**
 * Same as `getContexts`, but returns the details of each web view.
 *
 * @param waitForWebviewMs - How long to wait for at least one web view to appear
 */
export async function macosGetContexts(
  this: Mac2Driver,
  waitForWebviewMs: number = 0,
): Promise<{id: string; [key: string]: unknown}[]> {
  this.assertWebviewEnabled();
  const deadline = Date.now() + waitForWebviewMs;
  let details = await this.getWebViewDetails();
  while (!details.pages.length && Date.now() < deadline) {
    await new Promise((resolve) => setTimeout(resolve, WEBVIEW_POLL_INTERVAL_MS));
    details = await this.getWebViewDetails();
  }
  return [{id: NATIVE_APP}, ...details.pages.map((page) => ({...page, id: `${WEBVIEW_PREFIX}${page.id}`}))];
}

/**
 * Picks the debugging port and makes sure the app is launched with it. The driver owns the flag,
 * so one passed in the app arguments is replaced.
 *
 * @param caps - The session capabilities
 * @returns The capabilities to start the WDA session with and the port, if web views are enabled
 */
export async function prepareWebviewLaunch<T extends {arguments?: unknown}>(
  caps: T & {webviewEnabled?: boolean; webviewDevtoolsPort?: number; noReset?: boolean},
): Promise<{caps: T; port: number | null}> {
  if (!caps.webviewEnabled) {
    return {caps, port: null};
  }
  // The arguments are ignored if the already running app is just activated
  if (caps.noReset && !caps.webviewDevtoolsPort) {
    throw new errors.InvalidArgumentError(
      `'webviewDevtoolsPort' capability must be set along with 'noReset', since the app arguments ` +
        `might be ignored and the debugging port cannot be chosen by the driver`,
    );
  }
  const port =
    caps.webviewDevtoolsPort ?? (await net.getFreePort({port: [PORT_RANGE_START, PORT_RANGE_END], host: CDP_HOST}));
  const args = Array.isArray(caps.arguments) ? (caps.arguments as unknown[]).map(String) : [];
  const userArgs = removeDebuggingPortArgs(args);
  if (userArgs.length !== args.length) {
    log.warn(`Ignoring '${DEBUGGING_PORT_FLAG}' in the app arguments. Use 'webviewDevtoolsPort' capability instead`);
  }
  return {caps: {...caps, arguments: [...userArgs, `${DEBUGGING_PORT_FLAG}=${port}`]}, port};
}

// Handles both the `--flag=value` and the `--flag value` forms
function removeDebuggingPortArgs(args: string[]): string[] {
  const result: string[] = [];
  for (let i = 0; i < args.length; i++) {
    if (args[i] === DEBUGGING_PORT_FLAG) {
      if (i + 1 < args.length && !args[i + 1].startsWith('-')) {
        i++;
      }
    } else if (!args[i].startsWith(`${DEBUGGING_PORT_FLAG}=`)) {
      result.push(args[i]);
    }
  }
  return result;
}

async function cdpRequest<T>(driver: Mac2Driver, port: number, endpoint: string): Promise<T | null> {
  try {
    const {data} = await axios.get<T>(`http://${CDP_HOST}:${port}${endpoint}`, {
      timeout: CDP_REQUEST_TIMEOUT_MS,
    });
    return data;
  } catch (e: any) {
    driver.log.debug(`CDP request to ${CDP_HOST}:${port}${endpoint} failed: ${e.message}`);
    return null;
  }
}
