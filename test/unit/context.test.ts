import assert from 'node:assert/strict';
import {describe, it} from 'node:test';

import {getChromedriverOpts, getContexts, prepareWebviewLaunch, setContext} from '../../lib/commands/context.js';
import {Mac2Driver} from '../../lib/driver.js';

function makeDriver(opts: Record<string, unknown> = {webviewEnabled: true}) {
  const driver = new Mac2Driver({} as any);
  driver.opts = opts as any;
  return driver;
}

describe('webview contexts', () => {
  describe('prepareWebviewLaunch', () => {
    it('leaves caps untouched when web views are disabled', async () => {
      const caps = {arguments: ['-a']};
      const result = await prepareWebviewLaunch(caps);
      assert.equal(result.caps, caps);
      assert.equal(result.port, null);
    });

    it('appends the debugging flag with the requested port', async () => {
      const caps = {webviewEnabled: true, webviewDevtoolsPort: 9333, arguments: ['-a']};
      const result = await prepareWebviewLaunch(caps);
      assert.deepEqual(result.caps.arguments, ['-a', '--remote-debugging-port=9333']);
      assert.equal(result.port, 9333);
      assert.deepEqual(caps.arguments, ['-a'], 'must not mutate the original caps');
    });

    it('picks a free port when none is given', async () => {
      const result = await prepareWebviewLaunch({webviewEnabled: true});
      assert.ok(result.port);
      assert.deepEqual(result.caps.arguments, [`--remote-debugging-port=${result.port}`]);
    });

    it('reuses a port supplied by the user in the arguments', async () => {
      const caps = {webviewEnabled: true, arguments: ['--remote-debugging-port=9444']};
      const result = await prepareWebviewLaunch(caps);
      assert.equal(result.caps, caps);
      assert.equal(result.port, 9444);
    });
  });

  describe('getContexts', () => {
    it('returns only NATIVE_APP when web views are disabled', async () => {
      const driver = makeDriver({});
      assert.deepEqual(await getContexts.call(driver), ['NATIVE_APP']);
    });

    it('lists the pages as WEBVIEW_<id>', async () => {
      const driver = makeDriver();
      driver.getWebViewDetails = (async () => ({port: 1, pages: [{id: 'A', type: 'page'}]})) as any;
      assert.deepEqual(await getContexts.call(driver), ['NATIVE_APP', 'WEBVIEW_A']);
    });
  });

  describe('setContext', () => {
    it('rejects an unknown web view', async () => {
      const driver = makeDriver();
      driver.getWebViewDetails = (async () => ({port: 1, pages: []})) as any;
      await assert.rejects(setContext.call(driver, 'WEBVIEW_X'), /Web view not found/);
    });

    it('requires webviewEnabled', async () => {
      await assert.rejects(setContext.call(makeDriver({}), 'WEBVIEW_X'), /webviewEnabled/);
    });

    it('stops Chromedriver and switches the proxy back on NATIVE_APP', async () => {
      const driver = makeDriver();
      let stopped = 0;
      driver.chromedriver = {
        stop: async () => {
          stopped++;
        },
      } as any;
      driver._currentContext = 'WEBVIEW_A';
      await setContext.call(driver, 'NATIVE_APP');
      assert.equal(stopped, 1);
      assert.equal(driver.chromedriver, null);
      assert.equal(await driver.getCurrentContext(), 'NATIVE_APP');
    });
  });

  describe('getChromedriverOpts', () => {
    const details = {port: 1, pages: [], info: {Browser: 'Chrome/150.0.0.1'}};

    it('does not download Chromedriver unless the feature is enabled', () => {
      const driver = makeDriver();
      driver.isFeatureEnabled = () => false;
      assert.equal(getChromedriverOpts.call(driver, details).isAutodownloadEnabled, false);
      driver.isFeatureEnabled = (name: string) => name === 'chromedriver_autodownload';
      assert.equal(getChromedriverOpts.call(driver, details).isAutodownloadEnabled, true);
    });

    it('uses the capabilities when provided', () => {
      const driver = makeDriver({
        webviewEnabled: true,
        chromedriverExecutable: '/bin/cd',
        chromedriverExecutableDir: '/cds',
      });
      const opts = getChromedriverOpts.call(driver, details);
      assert.equal(opts.executable, '/bin/cd');
      assert.equal(opts.executableDir, '/cds');
    });

    it('falls back to the default dir when no capabilities are provided', () => {
      const opts = getChromedriverOpts.call(makeDriver(), details);
      assert.equal(opts.executable, undefined);
      assert.match(String(opts.executableDir), /chromedriver$/);
    });
  });

  describe('proxy routing', () => {
    it('sends find and timeouts to Chromedriver only in a web view', () => {
      const driver = makeDriver();
      const routes = (list: ReturnType<Mac2Driver['getProxyAvoidList']>) => list.map(([, re]) => String(re));
      const native = routes(driver.getProxyAvoidList('s'));
      driver.chromedriver = {} as any;
      const web = routes(driver.getProxyAvoidList('s'));
      assert.ok(native.some((r) => r.includes('timeouts')));
      assert.ok(!web.some((r) => r.includes('timeouts') || r.includes('element')));
      assert.ok(web.some((r) => r.includes('context')));
    });

    it('stops Chromedriver on session teardown', async () => {
      const driver = makeDriver();
      let stopped = false;
      driver.chromedriver = {
        stop: async () => {
          stopped = true;
        },
      } as any;
      await driver.deleteSession();
      assert.ok(stopped);
      assert.equal(driver.chromedriver, null);
    });
  });
});
