import _ from 'lodash';
import { BaseDriver } from 'appium-base-driver';
import log from './logger';
import GeckoDriverServer from './gecko';
import { desiredCapConstraints } from './desired-caps';
import commands from './commands/index';
import { formatCapsForServer } from './utils';

const NO_PROXY = [
  ['GET', new RegExp('^/session/[^/]+/appium')],
  ['POST', new RegExp('^/session/[^/]+/appium')],
  ['POST', new RegExp('^/session/[^/]+/element/[^/]+/elements?$')],
  ['POST', new RegExp('^/session/[^/]+/elements?$')],
];

class Mac2Driver extends BaseDriver {
  constructor (opts = {}) {
    super(opts);
    this.desiredCapConstraints = desiredCapConstraints;
    this.locatorStrategies = [
      'xpath',
      'tag name',
      'link text',
      'partial link text',
      'css selector',
      // Let these two reach Gecko Driver and fail there with a proper error message
      'id',
      'name',
    ];
    this.resetState();

    for (const [cmd, fn] of _.toPairs(commands)) {
      GeckoDriver.prototype[cmd] = fn;
    }
  }

  resetState () {
    this.gecko = null;
    this.proxyReqRes = null;
    this.isProxyActive = false;
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
    this.gecko = new GeckoDriverServer(caps);
    try {
      await this.gecko.start(formatCapsForServer(caps));
    } catch (e) {
      await this.deleteSession();
      throw e;
    }
    this.proxyReqRes = this.gecko.proxy.proxyReqRes.bind(this.gecko.proxy);
    this.isProxyActive = true;
    return [sessionId, caps];
  }

  async deleteSession () {
    log.info('Ending Gecko Driver session');
    await this.gecko.stop();
    this.resetState();

    await super.deleteSession();
  }
}

export default Mac2Driver;
