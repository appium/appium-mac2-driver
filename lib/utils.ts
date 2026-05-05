import {exec} from 'teen_process';
import {node} from 'appium/support';

const MODULE_NAME = 'appium-mac2-driver';

/**
 * Calculates the path to the current module's root folder
 *
 * @returns The full path to module root
 * @throws If the current module root folder cannot be determined
 */
let moduleRootCache: string | null = null;

export const getModuleRoot = function getModuleRoot(): string {
  if (moduleRootCache) {
    return moduleRootCache;
  }
  const root = node.getModuleRootSync(MODULE_NAME, __filename);
  if (!root) {
    throw new Error(`Cannot find the root folder of the ${MODULE_NAME} Node.js module`);
  }
  moduleRootCache = root;
  return moduleRootCache;
};

/**
 * Retrieves process ids of all the children processes created by the given
 * parent process identifier
 *
 * @param parentPid parent process ID
 * @returns the list of matched children process ids
 * or an empty list if none matched
 */
export async function listChildrenProcessIds(parentPid: number | string): Promise<string[]> {
  const {stdout} = await exec('ps', ['axu', '-o', 'ppid']);
  // USER  PID  %CPU %MEM  VSZ  RSS   TT  STAT STARTED  TIME COMMAND  PPID
  return stdout
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line: string) => {
      const [, pid, ...rest] = line.split(/\s+/).filter(Boolean);
      return [pid, rest.at(-1)];
    })
    .filter(([, ppid]) => ppid === `${parentPid}`)
    .map(([pid]) => String(pid));
}
