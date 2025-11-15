import _ from 'lodash';
import type { Mac2Driver } from '../driver';
import type { StringRecord } from '@appium/types';

const EXECUTE_SCRIPT_PREFIX = 'macos:';

/**
 *
 * @param script - The script to execute
 * @param args - Arguments to pass to the script
 */
export async function execute(
  this: Mac2Driver,
  script: string,
  args?: readonly any[] | StringRecord
): Promise<any> {
  this.log.info(`Executing extension command '${script}'`);
  const formattedScript = String(script).trim().replace(/^macos:\s*/, `${EXECUTE_SCRIPT_PREFIX} `);
  const preprocessedArgs = preprocessExecuteMethodArgs(args);
  return await this.executeMethod(formattedScript, [preprocessedArgs]);
}

/**
 * Massages the arguments going into an execute method.
 *
 * @param args - Arguments to preprocess
 * @returns Preprocessed arguments as StringRecord
 */
function preprocessExecuteMethodArgs(args?: readonly any[] | StringRecord): StringRecord {
  return (_.isArray(args) ? _.first(args) : args) ?? {};
}

