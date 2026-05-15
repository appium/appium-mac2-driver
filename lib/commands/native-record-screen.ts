import path from 'node:path';
import {fs, util} from 'appium/support';
import type {Mac2Driver} from '../driver';
import {uploadRecordedMedia} from './helpers';
import type {AppiumLogger, StringRecord} from '@appium/types';
import type EventEmitter from 'node:events';
import type {CancellablePromise} from 'asyncbox';
import {TimeoutError, sleep, waitForCondition, withTimeout} from 'asyncbox';
import {exec} from 'teen_process';
import {BIDI_EVENT_NAME} from './bidi/constants';
import {toNativeVideoChunkAddedEvent} from './bidi/models';
import {isPlainObject} from '../utils';
import os from 'node:os';

const RECORDING_STARTUP_TIMEOUT_MS = 5000;
const BUFFER_SIZE = 0xffff;
const MONITORING_INTERVAL_DURATION_MS = 1000;
const MAX_MONITORING_DURATION_MS = 24 * 60 * 60 * 1000; // 1 day
const STOP_WAIT_TIMEOUT_MS = 5000;

/**
 * XCTest daemon stores native screen recording attachments under `Data/Attachments` (legacy) or
 * `Data/tmp/Attachments` (Xcode 26.5+). Brace `{,tmp/}` matches both in a single glob.
 */
const DAEMON_NATIVE_RECORDING_ATTACHMENT_GLOB = '*/Data/{,tmp/}Attachments/*';

interface ActiveVideoInfo {
  fps: number;
  codec: number;
  displayId: number;
  uuid: string;
  startedAt: number;
}

interface DisplayInfo {
  id: number;
  isMain: boolean;
}

export class NativeVideoChunksBroadcaster {
  private readonly _ee: EventEmitter;
  private readonly _log: AppiumLogger;
  private readonly _publishers: Map<string, Promise<void>>;
  // The currently scheduled polling sleep of each publisher, indexed by uuid.
  // Cancelling it wakes the publisher up before the next polling tick so it
  // can perform a final stat + read + emit pass and exit.
  private readonly _wakeups: Map<string, CancellablePromise<void>>;
  // Set of uuids whose underlying recording has been explicitly stopped via
  // `notifyStopped`. The publisher uses this as the primary completion
  // signal; the `lsof` check is only consulted as a fallback for the case
  // where the host XCTest process disappears without anyone telling us.
  private readonly _terminationRequests: Set<string>;
  private _terminated: boolean;

  constructor(ee: EventEmitter, log: AppiumLogger) {
    this._ee = ee;
    this._log = log;
    this._publishers = new Map();
    this._wakeups = new Map();
    this._terminationRequests = new Set();
    this._terminated = false;
  }

  get hasPublishers(): boolean {
    return this._publishers.size > 0;
  }

  schedule(uuid: string): void {
    if (!this._publishers.has(uuid)) {
      this._publishers.set(uuid, this._runPublisher(uuid));
    }
  }

  /**
   * Signals the publisher for `uuid` that its underlying recording has been
   * stopped. The publisher wakes from its current polling sleep, performs a
   * final stat + read + emit pass to flush any remaining bytes of the
   * recording file to BiDi consumers, and exits.
   *
   * Idempotent and safe to call for an unknown uuid (no-op in that case).
   *
   * Callers SHOULD invoke this immediately after the recording has been
   * stopped on the underlying XCTest side; `waitFor(uuid)` is then
   * contractually guaranteed to resolve as soon as the publisher has
   * finished flushing, without having to wait for the next polling tick.
   */
  notifyStopped(uuid: string): void {
    if (!this._publishers.has(uuid)) {
      return;
    }
    this._terminationRequests.add(uuid);
    this._wakeups.get(uuid)?.cancel();
  }

  async waitFor(uuid: string): Promise<void> {
    const publisher = this._publishers.get(uuid);
    if (publisher) {
      await publisher;
    }
  }

  async shutdown(timeoutMs: number): Promise<void> {
    // Snapshot keys before publishers remove themselves from `_publishers`
    // in `_finishPublisher`, so we still know which attachment files to
    // delete after `_wait` completes.
    const uuidsAtShutdown = [...this._publishers.keys()];
    // Wake up every active publisher so they don't have to wait for their
    // next polling tick before flushing and exiting.
    for (const uuid of uuidsAtShutdown) {
      this.notifyStopped(uuid);
    }
    try {
      await this._wait(timeoutMs);
    } catch (e) {
      this._log.warn(e instanceof Error ? e.message : String(e));
    }

    await this._cleanup(uuidsAtShutdown);

    this._publishers.clear();
    this._wakeups.clear();
    this._terminationRequests.clear();
  }

  /**
   * Background monitor for a native screen recording attachment.
   *
   * This is scheduled as a fire-and-forget task by {@link schedule}; the
   * promise is removed from `_publishers` when the monitor exits (see
   * {@link _finishPublisher}). To make sure a failure here can never surface as an
   * unhandled promise rejection (which terminates the Appium server process
   * on Node.js 24+), this method MUST never reject: every error path logs a
   * warning and returns normally.
   */
  private async _createPublisher(uuid: string): Promise<void> {
    let fullPath = '';
    try {
      await waitForCondition(
        async () => {
          const {hasAccess, paths} = await listAttachments();
          if (!hasAccess) {
            this._log.info(
              `Cannot access native video recordings folder. ` +
                `Make sure to grant Full Disk Access to the Appium server process.`,
            );
            throw new Error('Access denied');
          }
          const result = paths.find((fp) => pathMatchesUuid(fp, uuid));
          if (!result) {
            return false;
          }
          fullPath = result;
          return true;
        },
        {
          waitMs: RECORDING_STARTUP_TIMEOUT_MS,
          intervalMs: 300,
        },
      );
    } catch {
      this._log.warn(
        `The video recording BiDi broadcast identified by ${uuid} did not ` +
          `start within ${RECORDING_STARTUP_TIMEOUT_MS}ms timeout`,
      );
      return;
    }

    let bytesRead = 0n;
    const startedMs = performance.now();
    try {
      while (!this._terminated && performance.now() - startedMs < MAX_MONITORING_DURATION_MS) {
        // Primary completion signal: `notifyStopped(uuid)` was called.
        // Secondary fallback: lsof reports no `testman` process holding
        // the recording file open (e.g. the host process exited without
        // anyone telling us — see appium/appium#22269).
        const stopRequested = this._terminationRequests.has(uuid);
        const isCompleted = stopRequested || !(await isFileUsed(fullPath, 'testman'));

        let size: bigint;
        try {
          ({size} = await fs.stat(fullPath, {bigint: true}));
        } catch (e) {
          // The recording file may have been removed by the OS once the
          // host XCTest process owning the attachment has exited. In that
          // case there is nothing more to read and we should stop monitoring.
          if ((e as NodeJS.ErrnoException)?.code === 'ENOENT') {
            this._log.debug(
              `The native video recording file for ${uuid} is no longer available. ` +
                `Assuming the recording has been terminated`,
            );
            return;
          }
          throw e;
        }
        if (bytesRead < size) {
          const handle = await fs.open(fullPath, 'r');
          try {
            while (bytesRead < size) {
              const bufferSize = Number(
                size - bytesRead > BUFFER_SIZE ? BUFFER_SIZE : size - bytesRead,
              );
              const buf = Buffer.alloc(bufferSize);
              await fs.read(handle, buf as any, 0, bufferSize, bytesRead as any);
              this._ee.emit(BIDI_EVENT_NAME, toNativeVideoChunkAddedEvent(uuid, buf));
              bytesRead += BigInt(bufferSize);
            }
          } finally {
            await fs.close(handle);
          }
        }

        if (isCompleted) {
          this._log.debug(
            `The native video recording identified by ${uuid} has been detected as completed`,
          );
          return;
        }

        // Cancellable sleep until the next polling tick. `notifyStopped`
        // cancels this wakeup so the loop re-runs immediately and detects
        // termination on the very next iteration. `cancelError: null` makes
        // the cancel resolve the promise instead of rejecting it.
        const wakeup = sleep({ms: MONITORING_INTERVAL_DURATION_MS, cancelError: null});
        this._wakeups.set(uuid, wakeup);
        try {
          // Guard against a notifyStopped() that landed between the
          // iteration's stop-check above and the wakeup being stored:
          // the cancel above would have been a no-op, so cancel here.
          if (this._terminationRequests.has(uuid)) {
            wakeup.cancel();
          }
          await wakeup;
        } finally {
          this._wakeups.delete(uuid);
        }
      }
    } catch (e) {
      this._log.warn(
        `Native video chunks publisher for ${uuid} stopped unexpectedly: ` +
          (e instanceof Error ? e.message : String(e)),
      );
      return;
    }

    this._log.warn(
      `Stopped monitoring of the native video recording identified by ${uuid} ` +
        `because of the timeout`,
    );
  }

  private async _wait(timeoutMs: number): Promise<void> {
    if (!this.hasPublishers) {
      return;
    }

    const timer = setTimeout(() => {
      this._terminated = true;
    }, timeoutMs);
    try {
      // Publishers are guaranteed by `_createPublisher` to never reject,
      // so we can simply await all of them.
      await Promise.all(this._publishers.values());
    } finally {
      clearTimeout(timer);
    }
  }

  private async _cleanup(uuids: readonly string[]): Promise<void> {
    if (uuids.length === 0) {
      return;
    }
    const uuidSet = new Set(uuids.map((uuid) => uuid.toUpperCase()));

    const {hasAccess, paths} = await listAttachments();
    if (!hasAccess || paths.length === 0) {
      return;
    }
    const tasks: Promise<void>[] = paths
      .map((attachmentPath) => [path.basename(attachmentPath), attachmentPath])
      .filter(([name]) => uuidSet.has(name.toUpperCase()))
      .map(([, attachmentPath]) => fs.rimraf(attachmentPath));
    if (tasks.length === 0) {
      return;
    }
    try {
      await Promise.all(tasks);
      this._log.debug(
        `Successfully deleted ${util.pluralize('leftover video recording', tasks.length, true)}`,
      );
    } catch (e) {
      this._log.warn(
        `Could not cleanup some leftover video recordings: ${e instanceof Error ? e.message : String(e)}`,
      );
    }
  }

  /**
   * Runs {@link _createPublisher} and always clears `_publishers` /
   * `_wakeups` / `_terminationRequests` for `uuid` when the monitor exits.
   */
  private async _runPublisher(uuid: string): Promise<void> {
    try {
      await this._createPublisher(uuid);
    } finally {
      this._finishPublisher(uuid);
    }
  }

  /**
   * Drops all bookkeeping for a finished publisher so {@link hasPublishers}
   * reflects reality and `notifyStopped` state does not leak across sessions.
   */
  private _finishPublisher(uuid: string): void {
    this._publishers.delete(uuid);
    this._wakeups.delete(uuid);
    this._terminationRequests.delete(uuid);
  }
}

/**
 * Initiates a new native screen recording session via XCTest.
 * If the screen recording is already running then this call results in noop.
 * A screen recording is running until a testing session is finished.
 * If a recording has never been stopped explicitly during a test session
 * then it would be stopped automatically upon test session termination,
 * and leftover videos would be deleted as well.
 *
 * @since Xcode 15
 * @param fps Frame Per Second setting for the resulting screen recording. 24 by default.
 * @param codec Possible codec value, where `0` means H264 (the default setting), `1` means HEVC
 * @param displayId Valid display identifier to record the video from. Main display is assumed
 * by default.
 * @returns The information about the asynchronously running video recording.
 */
export async function macosStartNativeScreenRecording(
  this: Mac2Driver,
  fps?: number,
  codec?: number,
  displayId?: number,
): Promise<ActiveVideoInfo> {
  const result = (await this.wda.proxy.command('/wda/video/start', 'POST', {
    fps,
    codec,
    displayId,
  })) as ActiveVideoInfo;
  this._videoChunksBroadcaster.schedule(result.uuid);
  return result;
}

/**
 * @since Xcode 15
 * @returns The information about the asynchronously running video recording or
 * null if no native video recording has been started.
 */
export async function macosGetNativeScreenRecordingInfo(
  this: Mac2Driver,
): Promise<ActiveVideoInfo | null> {
  return (await this.wda.proxy.command('/wda/video', 'GET')) as ActiveVideoInfo | null;
}

/**
 * Stops native screen recordind.
 * If no screen recording has been started before then the method throws an exception.
 *
 * @since Xcode 15
 * @param remotePath The path to the remote location, where the resulting video should be uploaded.
 *                              The following protocols are supported: http/https, ftp.
 *                              Null or empty string value (the default setting) means the content of resulting
 *                              file should be encoded as Base64 and passed as the endpoint response value.
 *                              An exception will be thrown if the generated media file is too big to
 *                              fit into the available process memory.
 * @param user The name of the user for the remote authentication.
 * @param pass The password for the remote authentication.
 * @param method The http multipart upload method name. The 'PUT' one is used by default.
 * @param headers  Additional headers mapping for multipart http(s) uploads
 * @param fileFieldName The name of the form field, where the file content BLOB should
 *                                 be stored for http(s) uploads
 * @param formFields Additional form fields for multipart http(s) uploads
 * @param ignorePayload Whether to ignore the resulting video payload
 * and return an empty string. Useful if you prefer to fetch
 * video chunks via a BiDi web socket.
 * @returns Base64-encoded content of the recorded media file if 'remotePath'
 * parameter is falsy or an empty string or ignorePayload is set to `true`.
 * @throws {Error} If there was an error while getting the name of a media file
 * or the file content cannot be uploaded to the remote location
 * or screen recording is not supported on the device under test.
 */
export async function macosStopNativeScreenRecording(
  this: Mac2Driver,
  remotePath?: string,
  user?: string,
  pass?: string,
  method?: string,
  headers?: StringRecord | [string, any][],
  fileFieldName?: string,
  formFields?: StringRecord | [string, string][],
  ignorePayload?: boolean,
): Promise<string> {
  const response: ActiveVideoInfo | null = (await this.wda.proxy.command(
    '/wda/video/stop',
    'POST',
    {},
  )) as ActiveVideoInfo | null;
  if (!response || !isPlainObject(response)) {
    throw new Error(
      'There is no active screen recording, thus nothing to stop. Did you start it before?',
    );
  }

  const {uuid} = response;
  // Wake the publisher up so it stops polling and flushes any remaining
  // bytes immediately. Without this, `waitFor` below could still block
  // for up to `MONITORING_INTERVAL_DURATION_MS` while the publisher sits
  // in its polling sleep.
  this._videoChunksBroadcaster.notifyStopped(uuid);
  try {
    await withTimeout(this._videoChunksBroadcaster.waitFor(uuid), STOP_WAIT_TIMEOUT_MS);
  } catch (e) {
    if (e instanceof TimeoutError) {
      this.log.debug(
        `The BiDi chunks broadcaster for the native screen recording identified ` +
          `by ${uuid} cannot complete within ${STOP_WAIT_TIMEOUT_MS}ms timeout`,
      );
    } else {
      this.log.debug(e instanceof Error ? e.stack : String(e));
    }
  }

  if (ignorePayload) {
    return '';
  }

  const {hasAccess, paths: attachments} = await listAttachments();
  if (!hasAccess) {
    throw new Error(
      `The screen recording identified by ${uuid} cannot be retrieved. ` +
        `Make sure the Appium Server process or its parent process (e.g. Terminal) ` +
        `has Full Disk Access permission enabled in 'System Settings' -> 'Privacy & Security' tab. ` +
        `You may verify the presence of the recorded video manually (e.g. under ` +
        `*/Data/Attachments/ or */Data/tmp/Attachments/ within Daemon Containers) by running ` +
        `'find "$HOME/Library/Daemon Containers" -type f -name "${uuid}"' from Terminal ` +
        `if the latter has been granted the above access permission.`,
    );
  }
  const matchedVideoPath = attachments.find((fullPath) => pathMatchesUuid(fullPath, uuid));
  if (!matchedVideoPath) {
    throw new Error(
      `The screen recording identified by ${uuid} cannot be retrieved even ` +
        `though the Appium Server process has Full Disk Access permission.`,
    );
  }
  const options = {
    user,
    pass,
    method,
    headers,
    fileFieldName,
    formFields,
  };
  return await uploadRecordedMedia.bind(this)(matchedVideoPath, remotePath ?? null, options);
}

/**
 * Fetches information about available displays
 *
 * @returns A map where keys are display identifiers and values are display infos
 */
export async function macosListDisplays(this: Mac2Driver): Promise<StringRecord<DisplayInfo>> {
  return (await this.wda.proxy.command('/wda/displays/list', 'GET')) as StringRecord<DisplayInfo>;
}

async function listAttachments(): Promise<{hasAccess: boolean; paths: string[]}> {
  // e.g. .../Daemon Containers/<container-id>/Data/Attachments/<uuid>
  // or .../Daemon Containers/<container-id>/Data/tmp/Attachments/<uuid> (Xcode 26.5+)
  const daemonContainersRoot = path.resolve(os.homedir(), 'Library', 'Daemon Containers');
  try {
    await fs.access(daemonContainersRoot);
  } catch {
    return {hasAccess: false, paths: []};
  }
  try {
    const paths = await fs.glob(DAEMON_NATIVE_RECORDING_ATTACHMENT_GLOB, {
      cwd: daemonContainersRoot,
      absolute: true,
    });
    return {hasAccess: true, paths: [...new Set(paths)]};
  } catch {
    return {hasAccess: true, paths: []};
  }
}

function pathMatchesUuid(fullPath: string, uuid: string): boolean {
  return path.basename(fullPath).toUpperCase() === uuid.toUpperCase();
}

async function isFileUsed(fpath: string, userProcessName: string): Promise<boolean> {
  try {
    const {stdout} = await exec('lsof', [fpath]);
    return stdout.includes(userProcessName);
  } catch {
    return false;
  }
}
