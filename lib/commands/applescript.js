import { fs, tempDir, util } from 'appium-support';
import { exec } from 'teen_process';
import log from '../logger';
import path from 'path';

const OSASCRIPT = 'osascript';
const APPLE_SCRIPT_FEATURE = 'apple_script';

const commands = {};

/**
 * @typedef {Object} ExecAppleScriptOptions
 * @property {?string} script A valid AppleScript to execute
 * @property {?string} command A valid AppleScript as a single command (no line breaks) to execute
 */

/**
 * Executes the given AppleScript command or a whole script based on the
 * given options. Either of these options must be provided. If both are provided
 * then the `command` one gets the priority.
 * Note that AppleScript command cannot contain line breaks. Consider making it
 * to a script in such case.
 * Note that by default AppleScript engine blocks commands/scripts execution if your script
 * is trying to access some private entities, like cameras or the desktop screen
 * and no permissions to do it are given to the parent (for example, Appium or Terminal)
 * process in System Preferences -> Privacy list.
 *
 * @param {!ExecAppleScriptOptions} opts
 * @returns {string} The actual stdout of the given command/script
 * @throws {Error} If the exit code of the given command/script is not zero.
 * The actual stderr output is set to the error message value.
 */
commands.macosExecAppleScript = async function macosExecAppleScript (opts = {}) {
  this.ensureFeatureEnabled(APPLE_SCRIPT_FEATURE);

  const {
    script,
    command,
  } = opts;
  if (!script && !command) {
    log.errorAndThrow('AppleScript script/command must not be empty');
  }
  if (/\n/.test(command)) {
    log.errorAndThrow('AppleScript commands cannot contain line breaks');
  }
  const shouldRunScript = !command && !!script;

  let tmpRoot;
  try {
    let tmpScriptPath;
    if (shouldRunScript) {
      tmpRoot = await tempDir.openDir();
      tmpScriptPath = path.resolve(tmpRoot, 'appium_script.scpt');
      await fs.writeFile(tmpScriptPath, script, 'utf8');
    }
    const args = [];
    if (command) {
      args.push('-e', command);
    } else {
      args.push(tmpScriptPath);
    }
    log.info(`Running ${OSASCRIPT} with arguments: ${util.quote(args)}`);
    try {
      const {stdout} = await exec(OSASCRIPT, args);
      return stdout;
    } catch (e) {
      throw new Error(e.stderr || e.message);
    }
  } finally {
    if (tmpRoot) {
      await fs.rimraf(tmpRoot);
    }
  }
};

export { commands };
export default commands;
