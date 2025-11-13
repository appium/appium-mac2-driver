import _ from 'lodash';
import type {
  RouteMatcher,
  HTTPMethod,
  HTTPBody,
  DefaultCreateSessionResult,
  DriverData,
  InitialOpts,
  StringRecord,
  ExternalDriver,
  DriverCaps,
  DriverOpts,
  W3CDriverCaps,
} from '@appium/types';
import { BaseDriver, DeviceSettings } from 'appium/driver';
import { WDA_MAC_SERVER, type WDAMacServer } from './wda-mac';
import MAC2_CONSTRAINTS, {type Mac2Constraints} from './constraints';
import * as appManagemenetCommands from './commands/app-management';
import * as appleScriptCommands from './commands/applescript';
import * as executeCommands from './commands/execute';
import * as findCommands from './commands/find';
import * as gesturesCommands from './commands/gestures';
import * as navigationCommands from './commands/navigation';
import * as recordScreenCommands from './commands/record-screen';
import * as screenshotCommands from './commands/screenshots';
import * as sourceCommands from './commands/source';
import * as clipboardCommands from './commands/clipboard';
import * as nativeScreenRecordingCommands from './commands/native-record-screen';
import log from './logger';
import { newMethodMap } from './method-map';
import { executeMethodMap } from './execute-method-map';

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

export class Mac2Driver
  extends BaseDriver<Mac2Constraints, StringRecord>
  implements ExternalDriver<Mac2Constraints, string, StringRecord>
{
  private isProxyActive: boolean;
  private _wda: WDAMacServer | null;
  _videoChunksBroadcaster: nativeScreenRecordingCommands.NativeVideoChunksBroadcaster;
  _screenRecorder: recordScreenCommands.ScreenRecorder | null;
  public proxyReqRes: (...args: any) => any;

  static newMethodMap = newMethodMap;
  static executeMethodMap = executeMethodMap;

  constructor(opts: InitialOpts = {} as InitialOpts) {
    super(opts);
    this.desiredCapConstraints = _.cloneDeep(MAC2_CONSTRAINTS);
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

  async onSettingsUpdate(key: string, value: unknown): Promise<void> {
    if (!this._wda) {
      return;
    }
    return await this._wda.proxy.command('/appium/settings', 'POST', {
      settings: {[key]: value}
    });
  }

  get wda(): WDAMacServer {
    if (!this._wda) {
      throw new Error('WDA server is not initialized');
    }
    return this._wda;
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  override proxyActive(sessionId: string): boolean {
    return this.isProxyActive;
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  override getProxyAvoidList(sessionId: string): RouteMatcher[] {
    return NO_PROXY;
  }

  override canProxy(): boolean {
    return true;
  }

  async proxyCommand(url: string, method: HTTPMethod, body: HTTPBody = null): Promise<any> {
    if (!this._wda) {
      throw new Error('WDA server is not initialized');
    }
    return await this._wda.proxy.command(url, method, body);
  }

  override async getStatus(): Promise<any> {
    if (!this._wda) {
      throw new Error('WDA server is not initialized');
    }
    return await this._wda.proxy.command('/status', 'GET');
  }

  // needed to make image plugin work
  async getWindowRect(): Promise<any> {
    if (!this._wda) {
      throw new Error('WDA server is not initialized');
    }
    return await this._wda.proxy.command('/window/rect', 'GET');
  }

  override async createSession(
    w3cCaps1: W3CMac2DriverCaps,
    w3cCaps2?: W3CMac2DriverCaps,
    w3cCaps3?: W3CMac2DriverCaps,
    driverData?: DriverData[]
  ): Promise<DefaultCreateSessionResult<Mac2Constraints>> {
    const [sessionId, caps] = await super.createSession(w3cCaps1, w3cCaps2, w3cCaps3, driverData);
    this._wda = WDA_MAC_SERVER;
    this.caps = caps as Mac2DriverCaps;
    this.opts = this.opts as Mac2DriverOpts;
    try {
      const prerun = caps.prerun as PrerunCapability | undefined;
      if (prerun) {
        if (!_.isString(prerun.command) && !_.isString(prerun.script)) {
          throw new Error(`'prerun' capability value must either contain ` +
            `'script' or 'command' entry of string type`);
        }
        log.info('Executing prerun AppleScript');
        const output = await this.macosExecAppleScript(
          prerun.script,
          undefined,
          prerun.command
        );
        if (_.trim(output)) {
          log.info(`Prerun script output: ${output}`);
        }
      }
      await this._wda.startSession(caps, {
        reqBasePath: this.basePath,
      });
    } catch (e: any) {
      await this.deleteSession();
      throw e;
    }
    this.proxyReqRes = this.wda.proxy.proxyReqRes.bind(this._wda.proxy);
    this.isProxyActive = true;
    return [sessionId, caps];
  }

  override async deleteSession(): Promise<void> {
    await this._screenRecorder?.stop(true);
    if (this._videoChunksBroadcaster.hasPublishers) {
      if (this._wda) {
        try {
          await this.wda.proxy.command('/wda/video/stop', 'POST', {});
        } catch {}
      }
      await this._videoChunksBroadcaster.shutdown(5000);
    }
    if (this._wda) {
      await this.wda.stopSession();
    }

    const postrun = this.opts.postrun as PostrunCapability | undefined;
    if (postrun) {
      if (!_.isString(postrun.command) && !_.isString(postrun.script)) {
        log.error(`'postrun' capability value must either contain ` +
          `'script' or 'command' entry of string type`);
      } else {
        log.info('Executing postrun AppleScript');
        try {
          const output = await this.macosExecAppleScript(
            postrun.script,
            undefined,
            postrun.command
          );
          if (_.trim(output)) {
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
    this.isProxyActive = false;
    this._videoChunksBroadcaster = new nativeScreenRecordingCommands.NativeVideoChunksBroadcaster(
      this.eventEmitter, this.log
    );
    this._screenRecorder = null;
  }

  macosLaunchApp = appManagemenetCommands.macosLaunchApp;
  macosActivateApp = appManagemenetCommands.macosActivateApp;
  macosTerminateApp = appManagemenetCommands.macosTerminateApp;
  macosQueryAppState = appManagemenetCommands.macosQueryAppState;

  macosExecAppleScript = appleScriptCommands.macosExecAppleScript;

  execute = executeCommands.execute;

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

  macosDeepLink = navigationCommands.macosDeepLink;

  startRecordingScreen = recordScreenCommands.startRecordingScreen;
  stopRecordingScreen = recordScreenCommands.stopRecordingScreen;

  macosStartNativeScreenRecording = nativeScreenRecordingCommands.macosStartNativeScreenRecording;
  macosGetNativeScreenRecordingInfo = nativeScreenRecordingCommands.macosGetNativeScreenRecordingInfo;
  macosStopNativeScreenRecording = nativeScreenRecordingCommands.macosStopNativeScreenRecording;
  macosListDisplays = nativeScreenRecordingCommands.macosListDisplays;

  macosScreenshots = screenshotCommands.macosScreenshots;

  macosSource = sourceCommands.macosSource;
}

export default Mac2Driver;

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
