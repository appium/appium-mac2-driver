import _ from 'lodash';
import { util, fs, net } from 'appium/support';
import type { Mac2Driver } from '../driver';
import type { StringRecord } from '@appium/types';

export async function uploadRecordedMedia (
  this: Mac2Driver,
  localFile: string,
  remotePath: string | null,
  uploadOptions: StringRecord = {}
): Promise<string> {
  if (_.isEmpty(remotePath) || _.isNil(remotePath)) {
    const {size} = await fs.stat(localFile);
    this.log.debug(`The size of the resulting screen recording is ${util.toReadableSizeString(size)}`);
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
