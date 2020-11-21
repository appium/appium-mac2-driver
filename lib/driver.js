import _ from 'lodash';
import { BaseDriver } from 'appium-base-driver';
import WDA_MAC_SERVER from './wda-mac';
import { desiredCapConstraints } from './desired-caps';
import commands from './commands/index';

const NO_PROXY = [
  ['GET', new RegExp('^/session/[^/]+/appium')],
  ['POST', new RegExp('^/session/[^/]+/appium')],
  ['POST', new RegExp('^/session/[^/]+/element/[^/]+/elements?$')],
  ['POST', new RegExp('^/session/[^/]+/elements?$')],
  ['POST', new RegExp('^/session/[^/]+/execute')],
  ['POST', new RegExp('^/session/[^/]+/execute/sync')],
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

    for (const [cmd, fn] of _.toPairs(commands)) {
      Mac2Driver.prototype[cmd] = fn;
    }
  }

  resetState () {
    this.wda = null;
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
    this.wda = WDA_MAC_SERVER;
    try {
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
    await this.wda.stopSession();
    this.resetState();

    await super.deleteSession();
  }
}

export default Mac2Driver;
