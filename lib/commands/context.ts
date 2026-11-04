import {Chromedriver} from 'appium-chromedriver';
import {errors} from 'appium/driver.js';
import axios from 'axios';
import {findAPortNotInUse} from 'portscanner';

import type {Mac2Driver} from '../driver.js';
import type {CdpPage, CdpVersionInfo, WebViewDetails} from '../types.js';

export const NATIVE_APP = 'NATIVE_APP';
export const WEBVIEW_PREFIX = 'WEBVIEW_';
export const DEBUGGING_PORT_FLAG = '--remote-debugging-port';
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
  const debuggerAddress = (page.webSocketDebuggerUrl ?? '').replace(/^wss?:\/\//, '').split('/')[0];
  if (!debuggerAddress) {
    throw new errors.InvalidArgumentError(`Web view '${name}' does not expose a debugger address`);
  }

  const executable = this.opts.chromedriverExecutablePath as string | undefined;
  const storageDir = this.cliArgs?.chromedriverStorageDir as string | undefined;
  if (!executable && !storageDir) {
    throw new errors.InvalidArgumentError(
      `Either the 'chromedriverExecutablePath' capability or the '--driver-mac2-chromedriver-storage-dir' ` +
        `server argument must be provided to switch to a web view`,
    );
  }

  // Only one Chromedriver may be alive at a time, so a webview-to-webview switch replaces it
  await this.stopChromedriver();

  const cd = new Chromedriver({
    details: details.info ? {info: {Browser: details.info.Browser}} : undefined,
    ...(executable ? {executable} : {}),
    // A custom dir makes Chromedriver pick/download a version matching the app
    ...(storageDir ? {executableDir: storageDir, isAutodownloadEnabled: true} : {}),
    ...(this.basePath ? {reqBasePath: this.basePath} : {}),
  });
  cd.on(Chromedriver.EVENT_CHANGED, (msg: {state: string}) => {
    // An unexpected exit must not leave the proxy pointing at a dead process
    if (msg.state === Chromedriver.STATE_STOPPED && this.chromedriver === cd) {
      this.log.warn('Chromedriver has stopped unexpectedly. Switching back to the native context');
      this.resetWebviewState();
    }
  });

  try {
    await cd.start({'goog:chromeOptions': {debuggerAddress}});
    // Timeouts belong to the session, but a new Chromedriver session starts with implicit wait 0
    if (this.implicitWaitMs) {
      await cd.jwproxy.command('/timeouts', 'POST', {implicit: this.implicitWaitMs});
    }
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
 * Picks the debugging port and makes sure the app is launched with it.
 *
 * @param caps - The session capabilities
 * @returns The capabilities to start the WDA session with and the port, if web views are enabled
 */
export async function prepareWebviewLaunch<T extends {arguments?: unknown}>(
  caps: T & {webviewEnabled?: boolean; webviewDevtoolsPort?: number},
): Promise<{caps: T; port: number | null}> {
  if (!caps.webviewEnabled) {
    return {caps, port: null};
  }
  const args = Array.isArray(caps.arguments) ? (caps.arguments as unknown[]).map(String) : [];
  const userPort = parseDebuggingPort(args);
  const port =
    caps.webviewDevtoolsPort ?? userPort ?? (await findAPortNotInUse(PORT_RANGE_START, PORT_RANGE_END, CDP_HOST));
  if (userPort !== null) {
    return {caps, port};
  }
  return {caps: {...caps, arguments: [...args, `${DEBUGGING_PORT_FLAG}=${port}`]}, port};
}

function parseDebuggingPort(args: string[]): number | null {
  for (const arg of args) {
    const match = new RegExp(`^${DEBUGGING_PORT_FLAG}=(\\d+)$`).exec(arg);
    if (match) {
      return Number(match[1]);
    }
  }
  return null;
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
