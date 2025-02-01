import _ from 'lodash';
import { errors } from 'appium/driver';

const EXTENSION_COMMANDS_MAPPING = {
  clickAndDrag: 'macosClickAndDrag',
  clickAndDragAndHold: 'macosClickAndDragAndHold',
  keys: 'macosKeys',

  tap: 'macosTap',
  doubleTap: 'macosDoubleTap',
  press: 'macosPress',
  pressAndDrag: 'macosPressAndDrag',
  pressAndDragAndHold: 'macosPressAndDragAndHold',

  source: 'macosSource',

  launchApp: 'macosLaunchApp',
  activateApp: 'macosActivateApp',
  terminateApp: 'macosTerminateApp',
  queryAppState: 'macosQueryAppState',

  appleScript: 'macosExecAppleScript',

  startRecordingScreen: 'startRecordingScreen',
  stopRecordingScreen: 'stopRecordingScreen',

  screenshots: 'macosScreenshots',

  deepLink: 'macosDeepLink',
};

/**
 *
 * @this {Mac2Driver}
 * @param {string} script
 * @param {any[]|import('@appium/types').StringRecord} [args]
 * @returns {Promise<any>}
 */
export async function execute (script, args) {
  if (script.match(/^macos:/)) {
    this.log.info(`Executing extension command '${script}'`);
    script = script.replace(/^macos:/, '').trim();
    return await this.executeMacosCommand(script, _.isArray(args) ? args[0] : args);
  }
  throw new errors.NotImplementedError();
};

/**
 *
 * @this {Mac2Driver}
 * @param {string} command
 * @param {import('@appium/types').StringRecord} [opts={}]
 * @returns {Promise<any>}
 */
export async function executeMacosCommand (command, opts = {}) {
  if (!_.has(EXTENSION_COMMANDS_MAPPING, command)) {
    throw new errors.UnknownCommandError(`Unknown extension command "${command}". ` +
      `Only ${_.keys(EXTENSION_COMMANDS_MAPPING)} commands are supported.`);
  }
  return await this[/** @type {string} */ (EXTENSION_COMMANDS_MAPPING[command])](opts);
};

/**
 * @typedef {import('../driver').Mac2Driver} Mac2Driver
 */
