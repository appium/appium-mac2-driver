import assert from 'node:assert/strict';
import {EventEmitter} from 'node:events';
import {describe, it} from 'node:test';

import {WDAMacServer, WDAMacProxy, WDA_MAC_SERVER} from '../../lib/wda-mac.js';

describe('WDAMacServer', () => {
  describe('parseProxyProperties', () => {
    it('should default', () => {
      assert.deepEqual((WDA_MAC_SERVER as any).parseProxyProperties({}), {
        scheme: 'http',
        host: '127.0.0.1',
        port: 10100,
        path: '',
      });
    });

    it('should follow WebDriverAgentMacUrl', () => {
      assert.deepEqual(
        (WDA_MAC_SERVER as any).parseProxyProperties({
          webDriverAgentMacUrl: 'http://customhost:9999',
        }),
        {scheme: 'http', host: 'customhost', port: 9999, path: ''},
      );
    });

    it('should follow WebDriverAgentMacUrl with custom path', () => {
      assert.deepEqual(
        (WDA_MAC_SERVER as any).parseProxyProperties({
          webDriverAgentMacUrl: 'https://customhost/path',
        }),
        {scheme: 'https', host: 'customhost', port: 10100, path: '/path'},
      );
    });

    it('should follow WebDriverAgentMacUrl with invalid url', () => {
      assert.throws(
        () => (WDA_MAC_SERVER as any).parseProxyProperties({webDriverAgentMacUrl: 'invalid url'}),
        /is invalid/,
      );
    });
  });
});

describe('WDAMacServer launch isolation', () => {
  it('keeps a late exit from an earlier launch off the new proxy', async (t) => {
    t.mock.method(WDAMacProxy.prototype, 'command', async () => ({}));
    const server = new WDAMacServer();
    const oldProcess = new EventEmitter();
    const processStub = {
      proc: oldProcess,
      init: async () => true,
      pid: null,
      listChildrenPids: async () => [],
    };
    (server as any)._process = processStub;
    await server.startSession({});
    const oldProxy = server.proxy;
    oldProcess.emit('exit', 1);
    assert.equal(oldProxy.didProcessExit, true);

    const newProcess = new EventEmitter();
    processStub.proc = newProcess;
    await server.startSession({});
    assert.equal(server.proxy.didProcessExit, false);
    oldProcess.emit('exit', 1);
    assert.equal(server.proxy.didProcessExit, false);
    newProcess.emit('exit', 1);
    assert.equal(server.proxy.didProcessExit, true);
  });

  it('keeps a local process exit off a replacement remote proxy', async (t) => {
    t.mock.method(WDAMacProxy.prototype, 'command', async () => ({}));
    const server = new WDAMacServer();
    const proc = new EventEmitter();
    (server as any)._process = {
      proc,
      init: async () => true,
      kill: async () => {},
      pid: null,
      listChildrenPids: async () => [],
    };
    await server.startSession({});
    const localProxy = server.proxy;
    await server.startSession({webDriverAgentMacUrl: 'http://localhost:10101'});
    proc.emit('exit', 1);
    assert.equal(localProxy.didProcessExit, true);
    assert.equal(server.proxy.didProcessExit, false);
  });
});
