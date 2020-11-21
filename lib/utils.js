import _ from 'lodash';
import { exec } from 'teen_process';

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

export { listChildrenProcessIds };
