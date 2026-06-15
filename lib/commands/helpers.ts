import {util, fs, net} from 'appium/support.js';
import type {Mac2Driver} from '../driver.js';
import type {StringRecord} from '@appium/types';

/**
 * Uploads the given local file to the specified remote path or returns
 * it as a base64 string if no remote path is provided.
 * @this Mac2Driver The Mac2Driver instance.
 * @param localFile The path to the local file to be uploaded.
 * @param remotePath The remote path where the file should be uploaded. If null, the file will be returned as a base64 string.
 * @param uploadOptions Additional options for the upload, such as authentication and headers.
 * @returns A promise that resolves to a base64 string if no remote path is provided, or an empty string if the file is uploaded.
 */
export async function uploadRecordedMedia(
  this: Mac2Driver,
  localFile: string,
  remotePath: string | null,
  uploadOptions: StringRecord = {},
): Promise<string> {
  if (remotePath == null || remotePath.length === 0) {
    const {size} = await fs.stat(localFile);
    this.log.debug(
      `The size of the resulting screen recording is ${util.toReadableSizeString(size)}`,
    );
    return (await util.toInMemoryBase64(localFile)).toString();
  }

  const {user, pass, method, headers, fileFieldName, formFields} = uploadOptions;
  const options: StringRecord = {
    method: method || 'PUT',
    headers,
    fileFieldName,
    formFields,
  };
  if (user && pass) {
    options.auth = {user, pass};
  }
  await net.uploadFile(localFile, remotePath, options);
  return '';
}
