import {setTimeout as delay} from 'node:timers/promises';

import type {AppiumLogger, IAppiumIpc, IIpcSubscription, IpcMessage} from '@appium/types';
import {errors} from 'appium/driver.js';
import {node, util} from 'appium/support.js';
import AsyncLock from 'async-lock';
import {waitForCondition} from 'asyncbox';

import type {Mac2Driver} from './driver.js';

export type SessionIpcMessage = {
  sessionId: string;
};

type AppiumIpcConstructor = new () => IAppiumIpc;
type IpcProvider = () => Promise<IAppiumIpc | undefined>;

/** Lets a new session make the previous one quit, over a driver-wide IPC (per-session IPCs are isolated). */
export class SessionClaimHandler {
  static readonly CLAIMED_TOPIC = 'mac2:sessionClaimed';
  static readonly CONTENDED_TOPIC = 'mac2:sessionContended';
  static readonly RELEASED_TOPIC = 'mac2:sessionReleased';

  private static readonly STARTUP_LOCK_KEY = 'mac2:sessionStartup';

  private static readonly CONTENTION_PROBE_MS = 10;
  private static readonly DEFAULT_RELEASE_WAIT_MS = 15000;

  private readonly startupLock = new AsyncLock();
  private readonly pendingTeardowns = new Set<Promise<void>>();
  private readonly subscriptionsBySessionId = new Map<string, IIpcSubscription<SessionIpcMessage>>();

  constructor(
    private readonly getIpc: IpcProvider,
    private readonly releaseWaitMs: number = SessionClaimHandler.DEFAULT_RELEASE_WAIT_MS,
  ) {}

  /** Serializes session startups so the newest wins. Enter before registering the session. */
  async runExclusive<T>(fn: () => Promise<T>): Promise<T> {
    return await this.startupLock.acquire(SessionClaimHandler.STARTUP_LOCK_KEY, fn);
  }

  /** Subscribe the session to claim messages from newer sessions. */
  async registerActiveSession(driver: Mac2Driver): Promise<void> {
    const ipc = await this.getIpc();
    const sessionId = driver.sessionId;
    if (!ipc || !sessionId) {
      return;
    }

    this.unregisterActiveSession(driver);

    const subscription = ipc.subscribe<SessionIpcMessage>(
      SessionClaimHandler.CLAIMED_TOPIC,
      this.getPublisherId(driver),
    );
    subscription.on('message', (message) => {
      void this.dispatchClaimMessage(driver, sessionId, message);
    });
    this.subscriptionsBySessionId.set(sessionId, subscription);
  }

  /** Unsubscribe the session from claim messages. */
  unregisterActiveSession(driver: Mac2Driver): void {
    const sessionId = driver.sessionId;
    if (!sessionId) {
      return;
    }

    this.subscriptionsBySessionId.get(sessionId)?.unsubscribe();
    this.subscriptionsBySessionId.delete(sessionId);
  }

  /** Tracks a session teardown, so that a new session does not start before it is complete. */
  async trackTeardown(teardown: () => Promise<void>): Promise<void> {
    const promise = teardown();
    const tracked = (async () => {
      try {
        await promise;
      } catch {
        // the failure is reported to the caller of trackTeardown()
      }
    })();
    this.pendingTeardowns.add(tracked);
    try {
      await promise;
    } finally {
      this.pendingTeardowns.delete(tracked);
    }
  }

  /** Make any other active session quit and wait until it has released the host. */
  async claimHost(driver: Mac2Driver): Promise<void> {
    await this.requestRelease(driver);
    await this.waitForPendingTeardowns(driver);
  }

  private async waitForPendingTeardowns(driver: Mac2Driver): Promise<void> {
    if (this.pendingTeardowns.size === 0) {
      return;
    }

    driver.log.debug(`Waiting for ${util.pluralize('session', this.pendingTeardowns.size, true)} to finish quitting`);
    const timer = new AbortController();
    const timedOut = Symbol('timedOut');
    const timeout = (async () => {
      try {
        return await delay(this.releaseWaitMs, timedOut, {signal: timer.signal});
      } catch {
        return undefined; // aborted
      }
    })();
    try {
      if ((await Promise.race([Promise.all(this.pendingTeardowns), timeout])) === timedOut) {
        // Starting now could let the old teardown (e.g. postrun) interfere with this session
        throw new errors.SessionNotCreatedError(
          `The previous session did not finish quitting within ${this.releaseWaitMs}ms`,
        );
      }
    } finally {
      timer.abort();
    }
  }

  private async requestRelease(driver: Mac2Driver): Promise<void> {
    const ipc = await this.getIpc();
    if (!ipc) {
      driver.log.debug('Driver-instance IPC is unavailable. Skipping the session claim.');
      return;
    }

    const sessionId = driver.sessionId;
    if (!sessionId) {
      return;
    }

    const contendingSessionIds = new Set<string>();
    const releasedSessionIds = new Set<string>();
    const subscriptions: IIpcSubscription<SessionIpcMessage>[] = [];

    try {
      const contendedSubscription = ipc.subscribe<SessionIpcMessage>(
        SessionClaimHandler.CONTENDED_TOPIC,
        this.getPublisherId(driver),
      );
      subscriptions.push(contendedSubscription);
      const releasedSubscription = ipc.subscribe<SessionIpcMessage>(
        SessionClaimHandler.RELEASED_TOPIC,
        this.getPublisherId(driver),
      );
      subscriptions.push(releasedSubscription);
      contendedSubscription.on('message', (message) => {
        if (message.data.sessionId !== sessionId) {
          contendingSessionIds.add(message.data.sessionId);
        }
      });
      releasedSubscription.on('message', (message) => {
        if (message.data.sessionId !== sessionId) {
          releasedSessionIds.add(message.data.sessionId);
        }
      });

      await ipc.publish<SessionIpcMessage>(SessionClaimHandler.CLAIMED_TOPIC, this.getPublisherId(driver), {
        sessionId,
      });
      // Older sessions reply synchronously to the claim, so a short wait is enough to learn about them
      await delay(SessionClaimHandler.CONTENTION_PROBE_MS);

      if (contendingSessionIds.size === 0) {
        return;
      }

      try {
        await waitForCondition(() => [...contendingSessionIds].every((id) => releasedSessionIds.has(id)), {
          waitMs: this.releaseWaitMs,
          intervalMs: 50,
        });
        driver.log.debug(
          `Received release confirmation from ${util.pluralize('session', contendingSessionIds.size, true)}`,
        );
      } catch {
        const pendingSessionIds = [...contendingSessionIds].filter((id) => !releasedSessionIds.has(id));
        // Starting now could let the old session interfere with this one
        throw new errors.SessionNotCreatedError(
          `${util.pluralize('session', pendingSessionIds.length, true)} [${pendingSessionIds.join(', ')}] ` +
            `did not quit within ${this.releaseWaitMs}ms`,
        );
      }
    } finally {
      subscriptions.forEach((sub) => sub.unsubscribe());
    }
  }

  /** @internal Exposed for unit tests. */
  resetForTesting(): void {
    this.pendingTeardowns.clear();
    for (const subscription of this.subscriptionsBySessionId.values()) {
      subscription.unsubscribe();
    }
    this.subscriptionsBySessionId.clear();
  }

  private async dispatchClaimMessage(
    driver: Mac2Driver,
    sessionId: string,
    message: IpcMessage<SessionIpcMessage>,
  ): Promise<void> {
    try {
      await this.handleClaimMessage(driver, sessionId, message);
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      driver.log.warn(`Could not handle the session claim IPC message for session '${sessionId}': ${msg}`);
    }
  }

  private async handleClaimMessage(
    driver: Mac2Driver,
    sessionId: string,
    message: IpcMessage<SessionIpcMessage>,
  ): Promise<void> {
    if (message.data.sessionId === sessionId || driver.sessionId !== sessionId) {
      return;
    }

    // Tell the claimer that it has to wait for us
    await this.publish(driver, SessionClaimHandler.CONTENDED_TOPIC, sessionId);

    driver.log.warn(
      `Session '${message.data.sessionId}' is starting, while this session ('${sessionId}') is still active. ` +
        `Only one session at a time is supported, since XCTest is single-threaded. ` +
        `Consider enabling the Appium server's '--session-override' flag and make sure to properly ` +
        `quit the previous session before starting a new one. Terminating the obsolete session.`,
    );
    await this.terminateSession(driver, sessionId);
  }

  private async terminateSession(driver: Mac2Driver, sessionId: string): Promise<void> {
    const publisherId = this.getPublisherId(driver);
    const {log} = driver;

    try {
      // Unlike deleteSession(), this also makes the server drop the session from its list
      await driver.startUnexpectedShutdown(
        new errors.NoSuchDriverError(
          'This session has been replaced by a newer one, because only a single session is supported',
        ),
      );
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      log.warn(`Could not terminate session '${sessionId}' on IPC request: ${msg}`);
    }

    await this.publish(driver, SessionClaimHandler.RELEASED_TOPIC, sessionId, publisherId, log);
  }

  private async publish(
    driver: Mac2Driver,
    topic: string,
    sessionId: string,
    publisherId: string = this.getPublisherId(driver),
    log: AppiumLogger = driver.log,
  ): Promise<void> {
    try {
      const ipc = await this.getIpc();
      await ipc?.publish<SessionIpcMessage>(topic, publisherId, {sessionId});
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      log.warn(`Could not publish '${topic}' message for session '${sessionId}': ${msg}`);
    }
  }

  private getPublisherId(driver: Mac2Driver): string {
    return node.getObjectId(driver);
  }
}

let sharedIpc: Promise<IAppiumIpc | undefined> | undefined;

async function loadSharedIpc(): Promise<IAppiumIpc | undefined> {
  sharedIpc ??= (async () => {
    try {
      const {AppiumIpc} = (await import('appium/driver.js')) as {AppiumIpc?: AppiumIpcConstructor};
      return AppiumIpc ? new AppiumIpc() : undefined;
    } catch {
      return undefined;
    }
  })();
  return await sharedIpc;
}

export const sessionClaimHandler = new SessionClaimHandler(loadSharedIpc);

/**
 * @internal Exposed for unit tests.
 */
export function setSharedIpcForTesting(ipc: IAppiumIpc | undefined): void {
  sharedIpc = Promise.resolve(ipc);
}

/**
 * @internal Exposed for unit tests.
 */
export function resetSharedIpcForTesting(): void {
  sessionClaimHandler.resetForTesting();
  sharedIpc = undefined;
}
