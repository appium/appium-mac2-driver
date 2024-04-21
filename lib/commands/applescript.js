import { fs, tempDir, util } from 'appium/support';
import { exec } from 'teen_process';
import path from 'path';

const OSASCRIPT = 'osascript';
const APPLE_SCRIPT_FEATURE = 'apple_script';

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
 * @this {Mac2Driver}
 * @param {import('../types').ExecAppleScriptOptions} opts
 * @returns {Promise<string>} The actual stdout of the given command/script
 * @throws {Error} If the exit code of the given command/script is not zero.
 * The actual stderr output is set to the error message value.
 */
export async function macosExecAppleScript (opts = {}) {
  this.ensureFeatureEnabled(APPLE_SCRIPT_FEATURE);

  const {
    script,
    language,
    command,
    cwd,
    timeout,
  } = opts;
  if (!script && !command) {
    this.log.errorAndThrow('AppleScript script/command must not be empty');
  }
  if (/\n/.test(/** @type {string} */(command))) {
    this.log.errorAndThrow('AppleScript commands cannot contain line breaks');
  }
  // 'command' has priority over 'script'
  const shouldRunScript = !command;

  const args = [];
  if (language) {
    args.push('-l', language);
  }
  let tmpRoot;
  try {
    if (shouldRunScript) {
      tmpRoot = await tempDir.openDir();
      const tmpScriptPath = path.resolve(tmpRoot, 'appium_script.scpt');
      await fs.writeFile(tmpScriptPath, /** @type {string} */(script), 'utf8');
      args.push(tmpScriptPath);
    } else {
      args.push('-e', command);
    }
    this.log.info(`Running ${OSASCRIPT} with arguments: ${util.quote(args)}`);
    try {
      const {stdout} = await exec(OSASCRIPT, args, {cwd, timeout});
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

/**
 * @typedef {import('../driver').Mac2Driver} Mac2Driver
 */
