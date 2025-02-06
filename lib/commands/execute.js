import _ from 'lodash';

const EXECUTE_SCRIPT_PREFIX = 'macos:';

/**
 *
 * @this {Mac2Driver}
 * @param {string} script
 * @param {any[]|import('@appium/types').StringRecord} [args]
 * @returns {Promise<any>}
 */
export async function execute (script, args) {
  this.log.info(`Executing extension command '${script}'`);
  const formattedScript = String(script).trim().replace(/^macos:\s*/, `${EXECUTE_SCRIPT_PREFIX} `);
  const preprocessedArgs = preprocessExecuteMethodArgs(args);
  return await this.executeMethod(formattedScript, [preprocessedArgs]);
};

/**
 * Massages the arguments going into an execute method.
 *
 * @param {ExecuteMethodArgs} [args]
 * @returns {StringRecord}
 */
function preprocessExecuteMethodArgs(args) {
  return /** @type {StringRecord} */ ((_.isArray(args) ? _.first(args) : args) ?? {});
}

/**
 * @typedef {import('../driver').Mac2Driver} Mac2Driver
 * @typedef {import('@appium/types').StringRecord} StringRecord
 * @typedef {readonly any[] | readonly [StringRecord] | Readonly<StringRecord>} ExecuteMethodArgs
 */
