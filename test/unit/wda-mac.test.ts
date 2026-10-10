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

describe('WDAMacServer single session', () => {
  function mockSessionCreation(t: any, ids: (string | Error)[]) {
    t.mock.method(WDAMacProxy.prototype, 'command', async function (this: WDAMacProxy, url: string, method: string) {
      if (url === '/session' && method === 'POST') {
        const next = ids.shift() as string | Error;
        if (next instanceof Error) {
          throw next;
        }
        this.sessionId = next;
      }
      return {};
    });
  }

  function makeServer() {
    const server = new WDAMacServer();
    (server as any)._process = {
      proc: new EventEmitter(),
      isRunning: true,
      init: async () => true,
      pid: null,
      listChildrenPids: async () => [],
    };
    return server;
  }

  it('a newer session replaces the previous one', async (t) => {
    mockSessionCreation(t, ['s1', 's2']);
    const server = makeServer();
    const first = await server.startSession({});
    assert.equal(server.isSessionActive(first), true);
    const second = await server.startSession({});
    assert.notEqual(first, second);
    assert.equal(server.isSessionActive(first), false);
    assert.equal(server.isSessionActive(second), true);
  });

  it('stopping a replaced session does not delete the newer one', async (t) => {
    mockSessionCreation(t, ['s1', 's2']);
    const server = makeServer();
    const first = await server.startSession({});
    const second = await server.startSession({});
    const commandMock = (WDAMacProxy.prototype.command as any).mock;
    commandMock.resetCalls();
    await server.stopSession(first);
    assert.equal(commandMock.callCount(), 0);
    assert.equal(server.isSessionActive(second), true);
    await server.stopSession(second);
    assert.equal(commandMock.calls[0].arguments[0], '/session/s2');
    assert.equal(commandMock.calls[0].arguments[1], 'DELETE');
    assert.equal(server.isSessionActive(second), false);
  });

  it('a pending DELETE of a replaced session does not clear the newer session', async (t) => {
    let resolveDelete!: () => void;
    const deleteDone = new Promise<void>((resolve) => {
      resolveDelete = resolve;
    });
    const ids = ['s1', 's2'];
    t.mock.method(WDAMacProxy.prototype, 'command', async function (this: WDAMacProxy, url: string, method: string) {
      if (url === '/session' && method === 'POST') {
        this.sessionId = ids.shift() as string;
      } else if (method === 'DELETE') {
        await deleteDone;
      }
      return {};
    });
    const server = makeServer();
    // the already running server is reused, so both sessions share the same proxy
    let isFirstInit = true;
    (server as any)._process.init = async () => {
      const result = isFirstInit;
      isFirstInit = false;
      return result;
    };
    const first = await server.startSession({});
    const stopping = server.stopSession(first);
    const second = await server.startSession({});
    resolveDelete();
    await stopping;
    assert.equal(server.isSessionActive(second), true);
  });

  it('a failed creation leaves no active session', async (t) => {
    mockSessionCreation(t, ['s1', new Error('boom')]);
    const server = makeServer();
    const first = await server.startSession({});
    await assert.rejects(server.startSession({}), /boom/);
    assert.equal(server.isSessionActive(first), false);
  });
});

describe('WDAMacServer launch isolation', () => {
  it('keeps a late exit from an earlier launch off the new proxy', async (t) => {
    t.mock.method(WDAMacProxy.prototype, 'command', async function (this: WDAMacProxy) {
      this.sessionId = 'sid';
      return {};
    });
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
    t.mock.method(WDAMacProxy.prototype, 'command', async function (this: WDAMacProxy) {
      this.sessionId = 'sid';
      return {};
    });
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
