import type {StringRecord} from '@appium/types';

import type {Mac2Driver} from '../driver.js';

declare module '../driver.js' {
  interface Mac2Driver {
    execute(...args: Parameters<typeof execute>): ReturnType<typeof execute>;
  }
}

const EXECUTE_SCRIPT_PREFIX = 'macos:';

/**
 *
 * @param script - The script to execute
 * @param args - Arguments to pass to the script
 */
export async function execute(this: Mac2Driver, script: string, args?: readonly any[] | StringRecord): Promise<any> {
  // Non-macos scripts belong to the web page when a web view is active
  if (this.chromedriver && !/^\s*macos:/.test(String(script))) {
    return await this.chromedriver.jwproxy.command('/execute/sync', 'POST', {script, args: args ?? []});
  }
  this.log.info(`Executing extension command '${script}'`);
  const formattedScript = String(script)
    .trim()
    .replace(/^macos:\s*/, `${EXECUTE_SCRIPT_PREFIX} `);
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
  return (Array.isArray(args) ? args[0] : args) ?? {};
}
