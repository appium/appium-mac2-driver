import _ from 'lodash';
import path from 'node:path';
import { fs, util } from 'appium/support';
import type { Mac2Driver } from '../driver';
import { uploadRecordedMedia } from './helpers';
import type { StringRecord } from '@appium/types';

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
 * @param displayID Valid display identifier to record the video from. Main display is assumed
 * by default.
 * @returns The information about the asynchronously running video recording.
 */
export async function macosStartNativeScreenRecording(
  this: Mac2Driver,
  fps?: number,
  codec?: number,
  displayID?: number,
): Promise<ActiveVideoInfo> {
  const result = await this.wda.proxy.command('/wda/video/start', 'POST', {
    fps,
    codec,
    displayID,
  }) as ActiveVideoInfo;
  this._recordedVideoIds.add(result.uuid);
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
 * @returns Base64-encoded content of the recorded media file if 'remotePath'
 * parameter is falsy or an empty string.
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
  const matchedVideoPath = _.first(
    (await listAttachments()).filter((name) => name.endsWith(uuid))
  );
  if (!matchedVideoPath) {
    throw new Error(
      `The screen recording identified by ${uuid} has not been found. Is it accessible?`
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
  const result = await uploadRecordedMedia.bind(this)(matchedVideoPath, remotePath, options);
  await cleanupNativeRecordedVideos.bind(this)(uuid);
  this._recordedVideoIds.delete(uuid);
  return result;
}

/**
 * Deletes previously recorded videos with given ids.
 * This call is safe and does not raise any errors.
 *
 * @param uuids One or more video UUIDs to be deleted
 */
export async function cleanupNativeRecordedVideos(
  this: Mac2Driver,
  uuids: string | Set<string>,
): Promise<void> {
  const attachments = await listAttachments();
  if (_.isEmpty(attachments)) {
    return;
  }
  const tasks: Promise<any>[] = attachments
    .map((attachmentPath) => [path.basename(attachmentPath), attachmentPath])
    .filter(([name,]) => _.isString(uuids) ? uuids === name : uuids.has(name))
    .map(([, attachmentPath]) => fs.rimraf(attachmentPath));
  if (_.isEmpty(tasks)) {
    return;
  }
  try {
    await Promise.all(tasks);
    this.log.debug(
      `Successfully deleted ${util.pluralize('leftover video recording', tasks.length, true)}`
    );
  } catch (e) {
    this.log.warn(`Could not cleanup some leftover video recordings: ${e.message}`);
  }
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

interface ActiveVideoInfo {
  fps: number;
  codec: number;
  displayID: number;
  uuid: string;
  startedAt: number;
}

// #endregion