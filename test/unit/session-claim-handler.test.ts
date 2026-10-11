import assert from 'node:assert/strict';
import {afterEach, describe, it} from 'node:test';

import {AppiumIpc} from 'appium/driver.js';

import {
  resetSharedIpcForTesting,
  SessionClaimHandler,
  sessionClaimHandler,
  setSharedIpcForTesting,
} from '../../lib/session-claim-handler.js';

const log = {debug() {}, info() {}, warn() {}, error() {}};

function makeDriver(sessionId: string, onDelete: () => Promise<void> = async () => {}) {
  const driver: any = {
    sessionId,
    log,
    startUnexpectedShutdown: async () => {
      sessionClaimHandler.unregisterActiveSession(driver);
      await onDelete();
      driver.sessionId = null;
    },
  };
  return driver;
}

describe('SessionClaimHandler', () => {
  afterEach(() => resetSharedIpcForTesting());

  it('terminates the previous session and waits for it to quit', async () => {
    setSharedIpcForTesting(new AppiumIpc());
    const events: string[] = [];
    const oldDriver = makeDriver('old', async () => {
      await new Promise((r) => setTimeout(r, 100));
      events.push('old-deleted');
    });
    await sessionClaimHandler.registerActiveSession(oldDriver);

    const newDriver = makeDriver('new');
    await sessionClaimHandler.registerActiveSession(newDriver);
    await sessionClaimHandler.claimHost(newDriver);
    events.push('claimed');

    assert.deepEqual(events, ['old-deleted', 'claimed']);
    assert.equal(oldDriver.sessionId, null);
    assert.equal(newDriver.sessionId, 'new');
  });

  it('does nothing if there is no other session', async () => {
    setSharedIpcForTesting(new AppiumIpc());
    const driver = makeDriver('only');
    await sessionClaimHandler.registerActiveSession(driver);
    await sessionClaimHandler.claimHost(driver);
    assert.equal(driver.sessionId, 'only');
  });

  it('does not terminate sessions that have quit already', async () => {
    setSharedIpcForTesting(new AppiumIpc());
    let deletions = 0;
    const oldDriver = makeDriver('old', async () => {
      deletions++;
    });
    await sessionClaimHandler.registerActiveSession(oldDriver);
    await oldDriver.startUnexpectedShutdown();

    const newDriver = makeDriver('new');
    await sessionClaimHandler.registerActiveSession(newDriver);
    await sessionClaimHandler.claimHost(newDriver);
    assert.equal(deletions, 1);
  });

  it('skips the claim if IPC is unavailable', async () => {
    setSharedIpcForTesting(undefined);
    const driver = makeDriver('s');
    await sessionClaimHandler.registerActiveSession(driver);
    await sessionClaimHandler.claimHost(driver);
    assert.equal(driver.sessionId, 's');
  });

  it('lets the newest of concurrently starting sessions win', async () => {
    setSharedIpcForTesting(new AppiumIpc());
    const events: string[] = [];
    const start = async (driver: any) =>
      await sessionClaimHandler.runExclusive(async () => {
        await sessionClaimHandler.registerActiveSession(driver);
        await sessionClaimHandler.claimHost(driver);
        events.push(`${driver.sessionId}-starting`);
        await new Promise((r) => setTimeout(r, 50));
        events.push(`${driver.sessionId}-started`);
      });
    const first = makeDriver('first', async () => {
      events.push('first-deleted');
    });
    const second = makeDriver('second', async () => {
      events.push('second-deleted');
    });

    await Promise.all([start(first), start(second)]);

    assert.deepEqual(events, ['first-starting', 'first-started', 'first-deleted', 'second-starting', 'second-started']);
    assert.equal(first.sessionId, null);
    assert.equal(second.sessionId, 'second');
  });

  it('waits for a session that is still quitting', async () => {
    setSharedIpcForTesting(new AppiumIpc());
    const events: string[] = [];
    const oldDriver = makeDriver('old');
    await sessionClaimHandler.registerActiveSession(oldDriver);
    // the old session has already left the claim channel, but its teardown is still running
    sessionClaimHandler.unregisterActiveSession(oldDriver);
    const teardown = sessionClaimHandler.trackTeardown(async () => {
      await new Promise((r) => setTimeout(r, 100));
      events.push('old-quit');
    });

    const newDriver = makeDriver('new');
    await sessionClaimHandler.registerActiveSession(newDriver);
    await sessionClaimHandler.claimHost(newDriver);
    events.push('claimed');
    await teardown;

    assert.deepEqual(events, ['old-quit', 'claimed']);
  });

  it('does not wait for a teardown that has finished with an error', async () => {
    setSharedIpcForTesting(new AppiumIpc());
    await assert.rejects(
      sessionClaimHandler.trackTeardown(async () => {
        throw new Error('boom');
      }),
      /boom/,
    );
    const driver = makeDriver('new');
    await sessionClaimHandler.registerActiveSession(driver);
    await sessionClaimHandler.claimHost(driver);
    assert.equal(driver.sessionId, 'new');
  });

  it('fails the startup if the previous session does not finish quitting in time', async () => {
    const handler = new SessionClaimHandler(async () => undefined, 50);
    // a teardown that never completes, e.g. a hanging postrun script
    void handler.trackTeardown(() => new Promise<void>(() => {}));

    await assert.rejects(handler.claimHost(makeDriver('new')), /did not finish quitting within 50ms/);
  });

  it('fails the startup if the previous session does not release the host in time', async () => {
    const ipc = new AppiumIpc();
    const handler = new SessionClaimHandler(async () => ipc, 100);
    const oldDriver = makeDriver('old', () => new Promise<void>(() => {}));
    await handler.registerActiveSession(oldDriver);

    await assert.rejects(handler.claimHost(makeDriver('new')), /\[old\] did not quit within 100ms/);
  });
});
