import _ from 'lodash';
import { errors } from 'appium-base-driver';
import log from '../logger';

const commands = {};

const NATIVE_COMMANDS_MAPPING = {
  setValue: 'macosSetValue',
  click: 'macosClick',
  scroll: 'macosScroll',
  rightClick: 'macosRightClick',
  hover: 'macosHover',
  doubleClick: 'macosDoubleClick',
  clickAndDrag: 'macosClickAndDrag',
  clickAndDragAndHold: 'macosClickAndDragAndHold',
  clickAndHold: 'macosClickAndHold',
  keys: 'macosKeys',

  source: 'macosSource',

  launchApp: 'macosLaunchApp',
  activateApp: 'macosActivateApp',
  terminateApp: 'macosTerminateApp',
  queryAppState: 'macosQueryAppState',
};

commands.execute = async function execute (script, args) {
  if (script.match(/^macos:/)) {
    log.info(`Executing native command '${script}'`);
    script = script.replace(/^macos:/, '').trim();
    return await this.executeMacosCommand(script, _.isArray(args) ? args[0] : args);
  }
  throw new errors.NotImplementedError();
};

commands.executeMacosCommand = async function executeMacosCommand (command, opts = {}) {
  if (!_.has(NATIVE_COMMANDS_MAPPING, command)) {
    throw new errors.UnknownCommandError(`Unknown macos command "${command}". ` +
      `Only ${_.keys(NATIVE_COMMANDS_MAPPING)} commands are supported.`);
  }
  return await this[NATIVE_COMMANDS_MAPPING[command]](opts);
};

export default commands;
