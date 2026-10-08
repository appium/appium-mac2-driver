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
    t.mock.method(WDAMacProxy.prototype, 'command', async (_url: string, method: string) =>
      method === 'POST' ? {sessionId: 'WDA-1', capabilities: {}} : {},
    );
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
    await server.stopSession();

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
    t.mock.method(WDAMacProxy.prototype, 'command', async (_url: string, method: string) =>
      method === 'POST' ? {sessionId: 'WDA-1', capabilities: {}} : {},
    );
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
    await server.stopSession();
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

  it('rejects an overlapping creation before it can replace the pending session', async (t) => {
    let finish: ((value: unknown) => void) | undefined;
    let creations = 0;
    const deleted: string[] = [];
    t.mock.method(WDAMacProxy.prototype, 'command', async function (this: WDAMacProxy, url: string, method: string) {
      if (url === '/session' && method === 'POST') {
        creations++;
        await new Promise((resolve) => {
          finish = resolve;
        });
        this.sessionId = 'WDA-1';
        return {sessionId: 'WDA-1', capabilities: {}};
      }
      if (method === 'DELETE') {
        deleted.push(url);
      }
      return {};
    });
    const server = new WDAMacServer();
    const caps = {webDriverAgentMacUrl: 'http://127.0.0.1:10101'};
    const first = server.startSession(caps);
    while (!finish) {
      await new Promise((resolve) => setImmediate(resolve));
    }
    await assert.rejects(server.startSession(caps), /Only one WebDriverAgentMac session/);
    assert.equal(creations, 1);
    finish(undefined);
    assert.equal(await first, 'WDA-1');
    await server.stopSession('WDA-1');
    assert.deepEqual(deleted, ['/session/WDA-1']);
  });

  it('rejects a second active remote session and allows a new one after cleanup', async (t) => {
    const deleted = mockWda(t);
    const server = new WDAMacServer();
    const caps = {webDriverAgentMacUrl: 'http://127.0.0.1:10101'};
    const first = await server.startSession(caps);
    await assert.rejects(server.startSession(caps), /Only one WebDriverAgentMac session/);
    await server.stopSession('not-the-owner');
    assert.deepEqual(deleted, []);
    await assert.rejects(server.startSession(caps), /Only one WebDriverAgentMac session/);
    await server.stopSession(first);
    assert.equal(await server.startSession(caps), 'WDA-2');
  });

  it('rejects a second active local session before reinitializing the host process', async (t) => {
    mockWda(t);
    const server = new WDAMacServer();
    let initializations = 0;
    (server as any)._process = {
      proc: new EventEmitter(),
      init: async () => {
        initializations++;
        return false;
      },
      isRunning: true,
      pid: null,
      listChildrenPids: async () => [],
    };
    await server.startSession({});
    await assert.rejects(server.startSession({}), /Only one WebDriverAgentMac session/);
    assert.equal(initializations, 1);
  });

  it('allows creation to retry after a failed start', async (t) => {
    let attempts = 0;
    t.mock.method(WDAMacProxy.prototype, 'command', async function (this: WDAMacProxy, _url: string, method: string) {
      if (method === 'POST') {
        if (++attempts === 1) {
          throw new Error('failed creation');
        }
        this.sessionId = 'WDA-1';
        return {sessionId: 'WDA-1', capabilities: {}};
      }
      return {};
    });
    const server = new WDAMacServer();
    const caps = {webDriverAgentMacUrl: 'http://127.0.0.1:10101'};
    await assert.rejects(server.startSession(caps), /failed creation/);
    assert.equal(await server.startSession(caps), 'WDA-1');
  });

  it('does not admit another session when deletion fails', async (t) => {
    let failDelete = true;
    t.mock.method(WDAMacProxy.prototype, 'command', async function (this: WDAMacProxy, _url: string, method: string) {
      if (method === 'POST') {
        this.sessionId = 'WDA-1';
        return {sessionId: 'WDA-1', capabilities: {}};
      }
      if (method === 'DELETE' && failDelete) {
        throw new Error('failed deletion');
      }
      return {};
    });
    const server = new WDAMacServer();
    const caps = {webDriverAgentMacUrl: 'http://127.0.0.1:10101'};
    await server.startSession(caps);
    await server.stopSession('WDA-1');
    await assert.rejects(server.startSession(caps), /Only one WebDriverAgentMac session/);
    failDelete = false;
    await server.stopSession('WDA-1');
    assert.equal(await server.startSession(caps), 'WDA-1');
  });

  it('deletes the active session when no session id is given', async (t) => {
    const deleted = mockWda(t);
    const server = new WDAMacServer();
    await server.startSession({webDriverAgentMacUrl: 'http://127.0.0.1:10101'});
    await server.stopSession();
    assert.deepEqual(deleted, ['/session/WDA-1']);
  });
});
