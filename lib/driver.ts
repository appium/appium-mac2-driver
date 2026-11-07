import type {
  RouteMatcher,
  HTTPMethod,
  HTTPBody,
  DefaultCreateSessionResult,
  InitialOpts,
  StringRecord,
  ExternalDriver,
  DriverCaps,
  DriverOpts,
  W3CDriverCaps,
  TimeoutValue,
} from '@appium/types';
import type {Chromedriver} from 'appium-chromedriver';
import {BaseDriver, DeviceSettings, errors} from 'appium/driver.js';

import * as appManagemenetCommands from './commands/app-management.js';
import * as appleScriptCommands from './commands/applescript.js';
import * as auditCommands from './commands/audit.js';
import * as clipboardCommands from './commands/clipboard.js';
import * as contextCommands from './commands/context.js';
import * as executeCommands from './commands/execute.js';
import * as findCommands from './commands/find.js';
import * as gesturesCommands from './commands/gestures.js';
import * as nativeScreenRecordingCommands from './commands/native-record-screen.js';
import * as navigationCommands from './commands/navigation.js';
import * as recordScreenCommands from './commands/record-screen.js';
import * as screenshotCommands from './commands/screenshots.js';
import * as sourceCommands from './commands/source.js';
import * as windowCommands from './commands/windows.js';
import MAC2_CONSTRAINTS, {type Mac2Constraints} from './constraints.js';
import {executeMethodMap} from './execute-method-map.js';
import log from './logger.js';
import {newMethodMap} from './method-map.js';
import {sessionClaimHandler} from './session-claim-handler.js';
import {WDA_MAC_SERVER, type WDAMacServer} from './wda-mac.js';

const NO_PROXY: RouteMatcher[] = [
  ['GET', new RegExp('^/session/[^/]+/appium')],
  ['POST', new RegExp('^/session/[^/]+/appium')],
  ['POST', new RegExp('^/session/[^/]+/element/[^/]+/elements?$')],
  ['POST', new RegExp('^/session/[^/]+/elements?$')],
  ['POST', new RegExp('^/session/[^/]+/execute')],
  ['POST', new RegExp('^/session/[^/]+/execute/sync')],
  ['GET', new RegExp('^/session/[^/]+/timeouts$')],
  ['POST', new RegExp('^/session/[^/]+/timeouts$')],
];

// In a web view everything but these routes goes to Chromedriver, including find and timeouts
const WEBVIEW_NO_PROXY: RouteMatcher[] = [
  ['GET', new RegExp('^/session/[^/]+/appium')],
  ['POST', new RegExp('^/session/[^/]+/appium')],
  ['GET', new RegExp('^/session/[^/]+/context')],
  ['POST', new RegExp('^/session/[^/]+/context')],
  ['POST', new RegExp('^/session/[^/]+/execute')],
  ['POST', new RegExp('^/session/[^/]+/execute/sync')],
  // Handled by the driver to keep the session timeouts across contexts
  ['POST', new RegExp('^/session/[^/]+/timeouts$')],
];

interface PrerunCapability {
  command?: string;
  script?: string;
}

interface PostrunCapability {
  command?: string;
  script?: string;
}

type Mac2DriverOpts = DriverOpts<Mac2Constraints>;

type Mac2DriverCaps = DriverCaps<Mac2Constraints>;
type W3CMac2DriverCaps = W3CDriverCaps<Mac2Constraints>;
export class Mac2Driver
  extends BaseDriver<Mac2Constraints, StringRecord>
  implements ExternalDriver<Mac2Constraints, string, StringRecord>
{
  static newMethodMap = newMethodMap;
  static executeMethodMap = executeMethodMap;

  macosLaunchApp = appManagemenetCommands.macosLaunchApp;
  macosActivateApp = appManagemenetCommands.macosActivateApp;
  macosTerminateApp = appManagemenetCommands.macosTerminateApp;
  macosQueryAppState = appManagemenetCommands.macosQueryAppState;

  macosExecAppleScript = appleScriptCommands.macosExecAppleScript;

  execute = executeCommands.execute;

  getCurrentContext = contextCommands.getCurrentContext;
  getContexts = contextCommands.getContexts;
  setContext = contextCommands.setContext;
  getWebViewDetails = contextCommands.getWebViewDetails;
  macosGetContexts = contextCommands.macosGetContexts;

  findElOrEls = findCommands.findElOrEls;

  macosSetValue = gesturesCommands.macosSetValue;
  macosClick = gesturesCommands.macosClick;
  macosScroll = gesturesCommands.macosScroll;
  macosSwipe = gesturesCommands.macosSwipe;
  macosRightClick = gesturesCommands.macosRightClick;
  macosHover = gesturesCommands.macosHover;
  macosDoubleClick = gesturesCommands.macosDoubleClick;
  macosClickAndDrag = gesturesCommands.macosClickAndDrag;
  macosClickAndDragAndHold = gesturesCommands.macosClickAndDragAndHold;
  macosKeys = gesturesCommands.macosKeys;
  macosPressAndHold = gesturesCommands.macosPressAndHold;
  macosTap = gesturesCommands.macosTap;
  macosDoubleTap = gesturesCommands.macosDoubleTap;
  macosPressAndDrag = gesturesCommands.macosPressAndDrag;
  macosPressAndDragAndHold = gesturesCommands.macosPressAndDragAndHold;

  macosGetClipboard = clipboardCommands.macosGetClipboard;
  macosSetClipboard = clipboardCommands.macosSetClipboard;
  macosPerformAccessibilityAudit = auditCommands.macosPerformAccessibilityAudit;

  macosDeepLink = navigationCommands.macosDeepLink;

  startRecordingScreen = recordScreenCommands.startRecordingScreen;
  stopRecordingScreen = recordScreenCommands.stopRecordingScreen;
  macosStartRecordingScreen = recordScreenCommands.macosStartRecordingScreen;
  macosStopRecordingScreen = recordScreenCommands.macosStopRecordingScreen;

  macosStartNativeScreenRecording = nativeScreenRecordingCommands.macosStartNativeScreenRecording;
  macosGetNativeScreenRecordingInfo = nativeScreenRecordingCommands.macosGetNativeScreenRecordingInfo;
  macosStopNativeScreenRecording = nativeScreenRecordingCommands.macosStopNativeScreenRecording;
  macosListDisplays = nativeScreenRecordingCommands.macosListDisplays;

  macosScreenshots = screenshotCommands.macosScreenshots;

  macosSource = sourceCommands.macosSource;

  macosListWindows = windowCommands.macosListWindows;
  macosAdjustWindow = windowCommands.macosAdjustWindow;

  _videoChunksBroadcaster!: nativeScreenRecordingCommands.NativeVideoChunksBroadcaster;
  _screenRecorder: recordScreenCommands.ScreenRecorder | null = null;
  public proxyReqRes!: (...args: any) => any;

  chromedriver: Chromedriver | null = null;
  _currentContext: string | null = null;
  _pageLoadTimeoutMs: number | null = null;
  _scriptTimeoutMs: number | null = null;
  _webviewDevtoolsPort: number | null = null;

  private isProxyActive: boolean = false;
  private _wda: WDAMacServer | null = null;
  private _wdaSessionId: string | null = null;
  private _hasClaimedHost: boolean = false;

  constructor(opts: InitialOpts = {} as InitialOpts) {
    super(opts);
    this.desiredCapConstraints = structuredClone(MAC2_CONSTRAINTS);
    this.locatorStrategies = [
      'id',
      'name',
      'accessibility id',

      'xpath',

      'class name',

      '-ios predicate string',
      'predicate string',

      '-ios class chain',
      'class chain',
    ];
    this.resetState();
    this.settings = new DeviceSettings({}, this.onSettingsUpdate.bind(this));
  }

  get wda(): WDAMacServer {
    if (!this._wda) {
      throw new Error('WDA server is not initialized');
    }
    // The WDA server is shared and only supports a single session, so a newer
    // session replaces this one. Never send commands on its behalf after that.
    if (this._wdaSessionId && !this._wda.isSessionActive(this._wdaSessionId)) {
      throw new errors.NoSuchDriverError(
        'This session has been replaced by a newer one, because this driver only supports a single session',
      );
    }
    return this._wda;
  }

  async onSettingsUpdate(key: string, value: unknown): Promise<void> {
    if (!this._wda) {
      return;
    }
    return await this.wda.proxy.command('/appium/settings', 'POST', {
      settings: {[key]: value},
    });
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  override proxyActive(sessionId: string): boolean {
    return this.isProxyActive;
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  override getProxyAvoidList(sessionId: string): RouteMatcher[] {
    return this.chromedriver ? WEBVIEW_NO_PROXY : NO_PROXY;
  }

  override canProxy(): boolean {
    return true;
  }

  async proxyCommand(url: string, method: HTTPMethod, body: HTTPBody = null): Promise<any> {
    if (this.chromedriver) {
      return await this.chromedriver.jwproxy.command(url, method, body);
    }
    return await this.wda.proxy.command(url, method, body);
  }

  // Timeouts belong to the session: keep them here and mirror to Chromedriver in a web view
  override async timeouts(
    type?: string,
    ms?: number | string,
    script?: TimeoutValue,
    pageLoad?: TimeoutValue,
    implicit?: TimeoutValue,
    command?: number,
  ): Promise<void> {
    if (type && ms !== undefined) {
      // Deprecated 'type'/'ms' form: normalize to the W3C one
      const legacyMs = this.parseTimeoutArgument(ms);
      ({script, pageLoad, implicit} = {
        script: type === 'script' ? legacyMs : undefined,
        pageLoad: type === 'page load' ? legacyMs : undefined,
        implicit: type === 'implicit' ? legacyMs : undefined,
      });
      command = type === 'command' ? legacyMs : undefined;
      type = ms = undefined;
    }
    if (pageLoad !== undefined && !this.chromedriver) {
      throw new errors.NotImplementedError('Not implemented: page load timeout is only supported in web view contexts');
    }
    await super.timeouts(type, ms, script, pageLoad, implicit, command);
    if (script !== undefined) {
      this._scriptTimeoutMs = script;
    }
    if (pageLoad !== undefined) {
      this._pageLoadTimeoutMs = pageLoad;
    }
    for (const [name, value] of Object.entries({script, pageLoad, implicit})) {
      if (value !== undefined) {
        await this.chromedriver?.jwproxy.command('/timeouts', 'POST', {[name]: value});
      }
    }
  }

  isWebviewEnabled(): boolean {
    return !!this.opts?.webviewEnabled;
  }

  assertWebviewEnabled(): void {
    if (!this.isWebviewEnabled()) {
      throw new errors.InvalidArgumentError(`Web view support must be enabled with the 'webviewEnabled' capability`);
    }
  }

  /** Stops Chromedriver, if any, and routes the commands back to WebDriverAgentMac */
  async stopChromedriver(): Promise<void> {
    const cd = this.chromedriver;
    this.resetWebviewState();
    if (cd) {
      try {
        await cd.stop();
      } catch (e: any) {
        log.warn(`Chromedriver cannot be stopped: ${e.message}`);
      }
    }
  }

  resetWebviewState(): void {
    this.chromedriver = null;
    this._currentContext = null;
  }

  override async getStatus(): Promise<any> {
    if (!this._wda) {
      throw new Error('WDA server is not initialized');
    }
    return await this._wda.proxy.command('/status', 'GET');
  }

  // needed to make image plugin work
  async getWindowRect(): Promise<any> {
    return await this.wda.proxy.command('/window/rect', 'GET');
  }

  override async createSession(
    w3cCapabilities: W3CMac2DriverCaps,
  ): Promise<DefaultCreateSessionResult<Mac2Constraints>> {
    const [sessionId, caps] = await super.createSession(w3cCapabilities);
    this._wda = WDA_MAC_SERVER;
    this.caps = caps as Mac2DriverCaps;
    // oxlint-disable-next-line no-self-assign -- narrows this.opts' type for the rest of the method
    this.opts = this.opts as Mac2DriverOpts;
    // The host supports a single session: the previous one has to quit first
    await sessionClaimHandler.runExclusive(async () => {
      // The session might have been deleted while it was waiting for its turn
      if (!this._wda || !this.sessionId) {
        throw new errors.NoSuchDriverError('The session has been deleted before it could start');
      }
      try {
        await sessionClaimHandler.registerActiveSession(this);
        await sessionClaimHandler.claimHost(this);
        this._hasClaimedHost = true;
        const prerun = caps.prerun as PrerunCapability | undefined;
        if (prerun) {
          if (typeof prerun.command !== 'string' && typeof prerun.script !== 'string') {
            throw new Error(`'prerun' capability value must either contain 'script' or 'command' entry of string type`);
          }
          log.info('Executing prerun AppleScript');
          const output = await this.macosExecAppleScript(prerun.script, undefined, prerun.command);
          if (output.trim()) {
            log.info(`Prerun script output: ${output}`);
          }
        }
        const launch = await contextCommands.prepareWebviewLaunch(caps);
        this._webviewDevtoolsPort = launch.port;
        this._wdaSessionId = await this.wda.startSession(launch.caps, {
          reqBasePath: this.basePath,
        });
      } catch (e: any) {
        await this.deleteSession();
        throw e;
      }
    });
    this.proxyReqRes = (...args: any[]) =>
      this.chromedriver
        ? (this.chromedriver.proxyReq as (...a: any[]) => any).apply(this.chromedriver, args)
        : (this.wda.proxy.proxyReqRes as (...a: any[]) => any).apply(this.wda.proxy, args);
    this.isProxyActive = true;
    return [sessionId, caps];
  }

  override async deleteSession(): Promise<void> {
    sessionClaimHandler.unregisterActiveSession(this);
    // A new session waits for the teardown to complete before it starts
    await sessionClaimHandler.trackTeardown(async () => await this.teardownSession());
  }

  private async teardownSession(): Promise<void> {
    await this.stopChromedriver();
    await this._screenRecorder?.stop(true);
    if (this._videoChunksBroadcaster.hasPublishers) {
      if (this._wda?.isSessionActive(this._wdaSessionId)) {
        try {
          await this.wda.proxy.command('/wda/video/stop', 'POST', {});
        } catch {}
      }
      await this._videoChunksBroadcaster.shutdown(5000);
    }
    if (this._wda) {
      await this._wda.stopSession(this._wdaSessionId);
    }

    // Skip postrun if the host was never acquired, as the previous session might still be using it
    const postrun = this._hasClaimedHost ? (this.opts.postrun as PostrunCapability | undefined) : undefined;
    if (postrun) {
      if (typeof postrun.command !== 'string' && typeof postrun.script !== 'string') {
        log.error(`'postrun' capability value must either contain 'script' or 'command' entry of string type`);
      } else {
        log.info('Executing postrun AppleScript');
        try {
          const output = await this.macosExecAppleScript(postrun.script, undefined, postrun.command);
          if (output.trim()) {
            log.info(`Postrun script output: ${output}`);
          }
        } catch (e: any) {
          log.error(e.message);
        }
      }
    }

    this.resetState();

    await super.deleteSession();
  }

  private resetState(): void {
    this._wda = null;
    this._wdaSessionId = null;
    this._hasClaimedHost = false;
    this.isProxyActive = false;
    this.resetWebviewState();
    this._pageLoadTimeoutMs = null;
    this._scriptTimeoutMs = null;
    this._webviewDevtoolsPort = null;
    this._videoChunksBroadcaster = new nativeScreenRecordingCommands.NativeVideoChunksBroadcaster(
      this.eventEmitter,
      this.log,
    );
    this._screenRecorder = null;
  }
}

export default Mac2Driver;
