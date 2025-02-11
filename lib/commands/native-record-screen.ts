import _ from 'lodash';
import B, {TimeoutError} from 'bluebird';
import path from 'node:path';
import { fs, util } from 'appium/support';
import type { Mac2Driver } from '../driver';
import { uploadRecordedMedia } from './helpers';
import type { AppiumLogger, StringRecord } from '@appium/types';
import type EventEmitter from 'node:events';
import { waitForCondition } from 'asyncbox';
import { exec } from 'teen_process';
import { BIDI_EVENT_NAME } from './bidi/constants';
import { toNativeVideoChunkAddedEvent } from './bidi/models';

const RECORDING_STARTUP_TIMEOUT_MS = 5000;
const BUFFER_SIZE = 0xFFFF;
const MONITORING_INTERVAL_DURATION_MS = 1000;
const MAX_MONITORING_DURATION_MS = 24 * 60 * 60 * 1000; // 1 day

export class NativeVideoChunksBroadcaster {
  private _ee: EventEmitter;
  private _log: AppiumLogger;
  private _publishers: Map<string, Promise<void>>;
  private _terminated: boolean;

  constructor (ee: EventEmitter, log: AppiumLogger) {
    this._ee = ee;
    this._log = log;
    this._publishers = new Map();
    this._terminated = false;
  }

  get hasPublishers(): boolean {
    return this._publishers.size > 0;
  }

  schedule(uuid: string): void {
    if (!this._publishers.has(uuid)) {
      this._publishers.set(uuid, this._createPublisher(uuid));
    }
  }

  async waitFor(uuid: string): Promise<void> {
    const publisher = this._publishers.get(uuid);
    if (publisher) {
      await publisher;
    }
  }

  async shutdown(timeoutMs: number): Promise<void> {
    try {
      await this._wait(timeoutMs);
    } catch (e) {
      this._log.warn(e.message);
    }

    await this._cleanup();

    this._publishers = new Map();
  }

  private async _createPublisher(uuid: string): Promise<void> {
    let fullPath = '';
    let bytesRead = 0n;
    try {
      await waitForCondition(async () => {
        const paths = await listAttachments();
        const result = paths.find((name) => name.endsWith(uuid));
        if (result) {
          fullPath = result;
          return true;
        }
        return false;
      }, {
        waitMs: RECORDING_STARTUP_TIMEOUT_MS,
        intervalMs: 300,
      });
    } catch {
      throw new Error(
        `The video recording identified by ${uuid} did not ` +
        `start within ${RECORDING_STARTUP_TIMEOUT_MS}ms timeout`
      );
    }

    const startedMs = performance.now();
    while (!this._terminated && performance.now() - startedMs < MAX_MONITORING_DURATION_MS) {
      const isCompleted = !(await isFileUsed(fullPath, 'testman'));

      const { size } = await fs.stat(fullPath, {bigint: true});
      if (bytesRead < size) {
        const handle = await fs.open(fullPath, 'r');
        try {
          while (bytesRead < size) {
            const bufferSize = Number(size - bytesRead > BUFFER_SIZE ? BUFFER_SIZE : size - bytesRead);
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
          `The native video recording identified by ${uuid} has been detected as completed`
        );
        return;
      }

      await B.delay(MONITORING_INTERVAL_DURATION_MS);
    }

    this._log.warn(
      `Stopped monitoring of the native video recording identified by ${uuid} ` +
      `because of the timeout`
    );
  }

  private async _wait(timeoutMs: number): Promise<void> {
    if (!this.hasPublishers) {
      return;
    }

    const timer = setTimeout(() => {
      this._terminated = true;
    }, timeoutMs);
    const publishingErrors: string[] = [];
    for (const publisher of this._publishers.values()) {
      try {
        await publisher;
      } catch (e) {
        publishingErrors.push(e.message);
      }
    }
    clearTimeout(timer);

    if (!_.isEmpty(publishingErrors)) {
      throw new Error(publishingErrors.join('\n'));
    }
  }

  private async _cleanup(): Promise<void> {
    if (!this.hasPublishers) {
      return;
    }

    const attachments = await listAttachments();
    if (_.isEmpty(attachments)) {
      return;
    }
    const tasks: Promise<any>[] = attachments
      .map((attachmentPath) => [path.basename(attachmentPath), attachmentPath])
      .filter(([name,]) => this._publishers.has(name))
      .map(([, attachmentPath]) => fs.rimraf(attachmentPath));
    if (_.isEmpty(tasks)) {
      return;
    }
    try {
      await Promise.all(tasks);
      this._log.debug(
        `Successfully deleted ${util.pluralize('leftover video recording', tasks.length, true)}`
      );
    } catch (e) {
      this._log.warn(`Could not cleanup some leftover video recordings: ${e.message}`);
    }
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
  const result = await this.wda.proxy.command('/wda/video/start', 'POST', {
    fps,
    codec,
    displayId,
  }) as ActiveVideoInfo;
  this._videoChunksBroadcaster.schedule(result.uuid);
  return result;
}

/**
 * @since Xcode 15
 * @returns The information about the asynchronously running video recording or
 * null if no native video recording has been started.
 */
export async function macosGetNativeScreenRecordingInfo(
  this: Mac2Driver
): Promise<ActiveVideoInfo | null> {
  return await this.wda.proxy.command('/wda/video', 'GET') as ActiveVideoInfo | null;
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
  headers?: StringRecord|[string, any][],
  fileFieldName?: string,
  formFields?: StringRecord|[string, string][],
  ignorePayload?: boolean,
): Promise<string> {
  const response: ActiveVideoInfo | null = (
    await this.wda.proxy.command('/wda/video/stop', 'POST', {})
  ) as ActiveVideoInfo | null;
  if (!response || !_.isPlainObject(response)) {
    throw new Error(
      'There is no active screen recording, thus nothing to stop. Did you start it before?'
    );
  }

  const { uuid } = response;
  try {
    await B.resolve(this._videoChunksBroadcaster.waitFor(uuid)).timeout(5000);
  } catch (e) {
    if (e instanceof TimeoutError) {
      this.log.debug(
        `The BiDi chunks broadcaster for the native screen recording identified ` +
        `by ${uuid} cannot complete within 5000ms timeout`
      );
    } else {
      this.log.debug(e.stack);
    }
  }

  if (ignorePayload) {
    return '';
  }

  const matchedVideoPath = _.first(
    (await listAttachments()).filter((name) => name.endsWith(uuid))
  );
  if (!matchedVideoPath) {
    throw new Error(
      `The screen recording identified by ${uuid} cannot be retrieved. ` +
      `Make sure the Appium Server process or its parent process (e.g. Terminal) ` +
      `has Full Disk Access permission enabled in 'System Preferences' -> 'Privacy & Security' tab. ` +
      `You may verify the presence of the recorded video manually by running the ` +
      `'find "$HOME/Library/Daemon Containers/" -type f -name "${uuid}"' command from Terminal ` +
      `if the latter has been granted the above access permission.`
    );
  }
  const options = {
    user,
    pass,
    method,
    headers,
    fileFieldName,
    formFields
  };
  return await uploadRecordedMedia.bind(this)(matchedVideoPath, remotePath, options);
}

/**
 * Fetches information about available displays
 *
 * @returns A map where keys are display identifiers and values are display infos
 */
export async function macosListDisplays(this: Mac2Driver): Promise<StringRecord<DisplayInfo>> {
  return await this.wda.proxy.command('/wda/displays/list', 'GET') as StringRecord<DisplayInfo>;
}

// #region Private functions

async function listAttachments(): Promise<string[]> {
  // The expected path looks like
  // $HOME/Library/Daemon Containers/EFDD24BF-F856-411F-8954-CD5F0D6E6F3E/Data/Attachments/CAE7E5E2-5AC9-4D33-A47B-C491D644DE06
  const deamonContainersRoot = path.resolve(process.env.HOME as string, 'Library', 'Daemon Containers');
  return await fs.glob(`*/Data/Attachments/*`, {
    cwd: deamonContainersRoot,
    absolute: true,
  });
}

async function isFileUsed(fpath: string, userProcessName: string): Promise<boolean> {
  const { stdout } = await exec('lsof', [fpath]);
  return stdout.includes(userProcessName);
}

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

// #endregion