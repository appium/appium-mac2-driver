import _ from 'lodash';
import { exec } from 'teen_process';
import path from 'path';
import _fs from 'fs';

/**
 * Calculates the path to the current module's root folder
 *
 * @returns {string} The full path to module root
 * @throws {Error} If the current module root folder cannot be determined
 */
const getModuleRoot = _.memoize(function getModuleRoot () {
  let currentDir = path.dirname(path.resolve(__filename));
  let isAtFsRoot = false;
  while (!isAtFsRoot) {
    const manifestPath = path.join(currentDir, 'package.json');
    try {
      if (_fs.existsSync(manifestPath) &&
          JSON.parse(_fs.readFileSync(manifestPath, 'utf8')).name === 'appium-mac2-driver') {
        return currentDir;
      }
    } catch (ign) {}
    currentDir = path.dirname(currentDir);
    isAtFsRoot = currentDir.length <= path.dirname(currentDir).length;
  }
  throw new Error('Cannot find the root folder of the appium-mac2-driver Node.js module');
});

/**
 * Retrieves process ids of all the children processes created by the given
 * parent process identifier
 *
 * @param {number|string} parentPid parent process ID
 * @returns {Array<string>} the list of matched children process ids
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
