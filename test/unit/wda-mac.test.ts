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

describe('WDAMacServer session cleanup', () => {
  // WebDriverAgentMac keeps a single active session: a new session replaces the previous one
  function mockWda(t: any): string[] {
    const deleted: string[] = [];
    let count = 0;
    t.mock.method(WDAMacProxy.prototype, 'command', async function (this: WDAMacProxy, url: string, method: string) {
      if (url === '/session' && method === 'POST') {
        // the base proxy stores the new id, and the W3C response value carries it too
        this.sessionId = `WDA-${++count}`;
        return {sessionId: this.sessionId, capabilities: {}};
      } else if (method === 'DELETE') {
        deleted.push(url);
      }
      return {};
    });
    return deleted;
  }

  it('keeps the id of its own session when session starts overlap (remote server)', async (t) => {
    const deleted: string[] = [];
    const pending: Array<(id: string) => void> = [];
    t.mock.method(WDAMacProxy.prototype, 'command', async function (this: WDAMacProxy, url: string, method: string) {
      if (url === '/session' && method === 'POST') {
        const id = await new Promise<string>((resolve) => pending.push(resolve));
        this.sessionId = id;
        return {sessionId: id, capabilities: {}};
      }
      if (method === 'DELETE') {
        deleted.push(url);
      }
      return {};
    });
    const waitForPending = async (n: number) => {
      while (pending.length < n) {
        await new Promise((resolve) => setImmediate(resolve));
      }
    };
    const server = new WDAMacServer();
    const caps = {webDriverAgentMacUrl: 'http://127.0.0.1:10101'};
    const startFirst = server.startSession(caps);
    await waitForPending(1);
    const startSecond = server.startSession(caps);
    await waitForPending(2);
    // the second creation response arrives before the first one
    pending[1]('WDA-2');
    const second = await startSecond;
    pending[0]('WDA-1');
    const first = await startFirst;
    assert.equal(first, 'WDA-1');
    assert.equal(second, 'WDA-2');

    await server.stopSession(first);
    assert.deepEqual(deleted, []);
    await server.stopSession(second);
    assert.deepEqual(deleted, ['/session/WDA-2']);
  });

  it('does not delete a newer session when an older one stops (remote server)', async (t) => {
    const deleted = mockWda(t);
    const server = new WDAMacServer();
    const caps = {webDriverAgentMacUrl: 'http://127.0.0.1:10101'};
    const first = await server.startSession(caps);
    const second = await server.startSession(caps);
    assert.equal(first, 'WDA-1');
    assert.equal(second, 'WDA-2');

    await server.stopSession(first);
    assert.deepEqual(deleted, []);
    await server.stopSession(second);
    assert.deepEqual(deleted, ['/session/WDA-2']);
  });

  it('does not delete a newer session when an older one stops (shared host process)', async (t) => {
    const deleted = mockWda(t);
    const server = new WDAMacServer();
    (server as any)._process = {
      proc: new EventEmitter(),
      // the host process is already running, so both sessions share one proxy
      init: async () => false,
      isRunning: true,
      pid: null,
      listChildrenPids: async () => [],
    };
    const first = await server.startSession({});
    const second = await server.startSession({});

    await server.stopSession(first);
    assert.deepEqual(deleted, []);
    await server.stopSession(second);
    assert.deepEqual(deleted, ['/session/WDA-2']);
  });

  it('deletes the active session when no session id is given', async (t) => {
    const deleted = mockWda(t);
    const server = new WDAMacServer();
    await server.startSession({webDriverAgentMacUrl: 'http://127.0.0.1:10101'});
    await server.stopSession();
    assert.deepEqual(deleted, ['/session/WDA-1']);
  });
});
