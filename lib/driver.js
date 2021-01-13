import _ from 'lodash';
import { BaseDriver, DeviceSettings } from 'appium-base-driver';
import WDA_MAC_SERVER from './wda-mac';
import { desiredCapConstraints } from './desired-caps';
import commands from './commands/index';
import log from './logger';

const NO_PROXY = [
  ['GET', new RegExp('^/session/[^/]+/appium')],
  ['POST', new RegExp('^/session/[^/]+/appium')],
  ['POST', new RegExp('^/session/[^/]+/element/[^/]+/elements?$')],
  ['POST', new RegExp('^/session/[^/]+/elements?$')],
  ['POST', new RegExp('^/session/[^/]+/execute')],
  ['POST', new RegExp('^/session/[^/]+/execute/sync')],
  ['GET', new RegExp('^/session/[^/]+/timeouts$')],
  ['POST', new RegExp('^/session/[^/]+/timeouts$')],
];

class Mac2Driver extends BaseDriver {
  constructor (opts = {}) {
    super(opts);
    this.desiredCapConstraints = desiredCapConstraints;
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

    for (const [cmd, fn] of _.toPairs(commands)) {
      Mac2Driver.prototype[cmd] = fn;
    }
  }

  async onSettingsUpdate (key, value) {
    return await this.wda.proxy.command('/appium/settings', 'POST', {
      settings: {[key]: value}
    });
  }

  resetState () {
    this.wda = null;
    this.proxyReqRes = null;
    this.isProxyActive = false;
    this._screenRecorder = null;
  }

  proxyActive () {
    return this.isProxyActive;
  }

  getProxyAvoidList () {
    return NO_PROXY;
  }

  canProxy () {
    return true;
  }

  async createSession (...args) {
    const [sessionId, caps] = await super.createSession(...args);
    this.wda = WDA_MAC_SERVER;
    try {
      if (caps.prerun) {
        if (!_.isString(caps.prerun.command) && !_.isString(caps.prerun.script)) {
          throw new Error(`'prerun' capability value must either contain ` +
            `'script' or 'command' entry of string type`);
        }
        log.info('Executing prerun AppleScript');
        const output = await this.macosExecAppleScript(caps.prerun);
        if (_.trim(output)) {
          log.info(`Prerun script output: ${output}`);
        }
      }
      await this.wda.startSession(caps);
    } catch (e) {
      await this.deleteSession();
      throw e;
    }
    this.proxyReqRes = this.wda.proxy.proxyReqRes.bind(this.wda.proxy);
    this.isProxyActive = true;
    return [sessionId, caps];
  }

  async deleteSession () {
    await this._screenRecorder?.stop(true);
    await this.wda?.stopSession();

    if (this.opts.postrun) {
      if (!_.isString(this.opts.postrun.command) && !_.isString(this.opts.postrun.script)) {
        log.error(`'postrun' capability value must either contain ` +
          `'script' or 'command' entry of string type`);
      } else {
        log.info('Executing postrun AppleScript');
        try {
          const output = await this.macosExecAppleScript(this.opts.postrun);
          if (_.trim(output)) {
            log.info(`Postrun script output: ${output}`);
          }
        } catch (e) {
          log.error(e.message);
        }
      }
    }

    this.resetState();

    await super.deleteSession();
  }
}

export default Mac2Driver;
