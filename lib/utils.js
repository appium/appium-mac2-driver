import _ from 'lodash';
import { exec } from 'teen_process';
import { node } from 'appium/support';

const MODULE_NAME = 'appium-mac2-driver';

/**
 * Calculates the path to the current module's root folder
 *
 * @returns {string} The full path to module root
 * @throws {Error} If the current module root folder cannot be determined
 */
const getModuleRoot = _.memoize(function getModuleRoot () {
  const root = node.getModuleRootSync(MODULE_NAME, __filename);
  if (!root) {
    throw new Error(`Cannot find the root folder of the ${MODULE_NAME} Node.js module`);
  }
  return root;
});

/**
 * Retrieves process ids of all the children processes created by the given
 * parent process identifier
 *
 * @param {number|string} parentPid parent process ID
 * @returns {Promise<string[]>} the list of matched children process ids
 * or an empty list if none matched
 */
async function listChildrenProcessIds (parentPid) {
  const { stdout } = await exec('ps', ['axu', '-o', 'ppid']);
  // USER  PID  %CPU %MEM  VSZ  RSS   TT  STAT STARTED  TIME COMMAND  PPID
  return stdout.split('\n')
    .filter(_.trim)
    .map((line) => {
      const [, pid, ...rest] = line.split(/\s+/).filter(_.trim);
      return [pid, _.last(rest)];
    })
    .filter(([, ppid]) => ppid === `${parentPid}`)
    .map(([pid]) => pid);
}

export { listChildrenProcessIds, getModuleRoot };
