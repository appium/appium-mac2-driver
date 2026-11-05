import assert from 'node:assert/strict';
import {describe, it} from 'node:test';

import {macosGetClipboard} from '../../lib/commands/clipboard.js';
import {
  getChromedriverOpts,
  getContexts,
  prepareWebviewLaunch,
  setContext,
  switchToPage,
} from '../../lib/commands/context.js';
import {findElOrEls} from '../../lib/commands/find.js';
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

    it('replaces a debugging flag supplied by the user', async () => {
      const caps = {
        webviewEnabled: true,
        webviewDevtoolsPort: 9555,
        arguments: ['--remote-debugging-port=9444', '-a'],
      };
      const result = await prepareWebviewLaunch(caps);
      assert.deepEqual(result.caps.arguments, ['-a', '--remote-debugging-port=9555']);
      assert.equal(result.port, 9555);
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

    it('rejects Microsoft Edge web views', async () => {
      const driver = makeDriver();
      driver.getWebViewDetails = (async () => ({
        port: 1,
        info: {Browser: 'Edg/150.0.0.1'},
        pages: [{id: 'A', type: 'page', webSocketDebuggerUrl: 'ws://127.0.0.1:1/devtools/page/A'}],
      })) as any;
      await assert.rejects(setContext.call(driver, 'WEBVIEW_A'), /Edge/);
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

  describe('switchToPage', () => {
    function makeChromedriver(handles: string[]) {
      const calls: unknown[][] = [];
      const cd = {
        jwproxy: {
          command: async (...args: unknown[]) => {
            calls.push(args);
            return args[0] === '/window/handles' ? handles : null;
          },
        },
      } as any;
      return {cd, calls};
    }

    it('selects the requested page among several', async () => {
      const {cd, calls} = makeChromedriver(['PAGE_A', 'PAGE_B']);
      await switchToPage(cd, 'PAGE_B');
      assert.deepEqual(calls[1], ['/window', 'POST', {handle: 'PAGE_B'}]);
    });

    it('fails if Chromedriver does not see the page', async () => {
      const {cd} = makeChromedriver(['PAGE_A']);
      await assert.rejects(switchToPage(cd, 'PAGE_B'), /does not see the web view/);
    });
  });

  describe('timeouts', () => {
    function withChromedriver(driver: Mac2Driver) {
      const calls: unknown[][] = [];
      driver.chromedriver = {
        jwproxy: {
          command: async (...args: unknown[]) => {
            calls.push(args);
          },
        },
      } as any;
      return calls;
    }

    it('keeps the implicit wait in the driver and mirrors it to Chromedriver', async () => {
      const driver = makeDriver();
      const calls = withChromedriver(driver);
      await driver.timeouts(undefined, undefined, undefined, undefined, 5000);
      assert.equal(driver.implicitWaitMs, 5000);
      assert.deepEqual(calls, [['/timeouts', 'POST', {implicit: 5000}]]);
    });

    it('forwards page load and script timeouts to Chromedriver', async () => {
      const driver = makeDriver();
      const calls = withChromedriver(driver);
      await driver.timeouts(undefined, undefined, 3000, 4000);
      assert.deepEqual(calls, [
        ['/timeouts', 'POST', {script: 3000}],
        ['/timeouts', 'POST', {pageLoad: 4000}],
      ]);
    });

    it('does not support page load timeouts natively', async () => {
      await assert.rejects(makeDriver().timeouts(undefined, undefined, undefined, 4000), /Not implemented/);
    });

    it('routes POST timeouts to the driver in a web view', () => {
      const driver = makeDriver();
      driver.chromedriver = {} as any;
      assert.ok(driver.getProxyAvoidList('s').some(([method, re]) => method === 'POST' && /timeouts/.test(String(re))));
    });
  });

  describe('proxy routing', () => {
    it('keeps native clipboard commands on WDA in a web view', async () => {
      const driver = makeDriver();
      const calls: unknown[][] = [];
      (driver as any)._wda = {
        proxy: {
          command: async (...args: unknown[]) => {
            calls.push(args);
            return 'Zm9v';
          },
        },
      } as any;
      driver.chromedriver = {jwproxy: {command: async () => assert.fail('must stay native')}} as any;
      assert.equal(await macosGetClipboard.call(driver, 'plaintext'), 'Zm9v');
      assert.equal(calls[0][0], '/wda/getPasteboard');
    });

    it('sends find and timeout reads to Chromedriver only in a web view', () => {
      const driver = makeDriver();
      const routes = (list: ReturnType<Mac2Driver['getProxyAvoidList']>) =>
        list.map(([method, re]) => `${method} ${String(re)}`);
      const native = routes(driver.getProxyAvoidList('s'));
      driver.chromedriver = {} as any;
      const web = routes(driver.getProxyAvoidList('s'));
      assert.ok(native.some((r) => r.startsWith('GET') && r.includes('timeouts')));
      assert.ok(!web.some((r) => r.startsWith('GET') && r.includes('timeouts')));
      assert.ok(!web.some((r) => r.includes('element')));
      assert.ok(web.some((r) => r.includes('context')));
    });

    it('finds elements through Chromedriver in a web view', async () => {
      const driver = makeDriver();
      const calls: unknown[][] = [];
      driver.chromedriver = {
        jwproxy: {
          command: async (...args: unknown[]) => {
            calls.push(args);
            return [];
          },
        },
      } as any;
      await findElOrEls.call(driver, 'css selector', '#b', true);
      assert.deepEqual(calls, [['/elements', 'POST', {using: 'css selector', value: '#b'}]]);
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
