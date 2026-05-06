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

/**
 * Clears the content of the given array.
 * @param items The array to clear.
 */
export function clearArray<T>(items: T[]): void {
  items.length = 0;
}

/**
 * Removes all occurrences of the given value from the array.
 * @param items The array to remove the value from.
 * @param value The value to remove.
 */
export function removeAllOccurrences<T>(items: T[], value: T): void {
  let index = items.indexOf(value);
  while (index >= 0) {
    items.splice(index, 1);
    index = items.indexOf(value);
  }
}

/**
 * Determines whether the given value is a plain object
 * (i.e., an object created by the Object constructor or with a null prototype).
 * @param value The value to check.
 * @returns True if the value is a plain object, false otherwise.
 */
export function isPlainObject(value: unknown): value is Record<string, unknown> {
  if (value === null || typeof value !== 'object') {
    return false;
  }
  const proto = Object.getPrototypeOf(value);
  return proto === Object.prototype || proto === null;
}
