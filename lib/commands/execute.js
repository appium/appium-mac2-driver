import _ from 'lodash';
import { errors } from 'appium-base-driver';
import log from '../logger';

const commands = {};

const DESKTOP_COMMANDS_MAPPING = {
  setValue: 'desktopSetValue',
  click: 'desktopClick',
  scroll: 'desktopScroll',
  rightClick: 'desktopRightClick',
  hover: 'desktopHover',
  doubleClick: 'desktopDoubleClick',
  clickAndDrag: 'desktopClickAndDrag',
  clickAndDragAndHold: 'desktopClickAndDragAndHold',
  clickAndHold: 'desktopClickAndHold',
  keys: 'desktopKeys',

  source: 'desktopSource',
};

commands.execute = async function execute (script, args) {
  if (script.match(/^desktop:/)) {
    log.info(`Executing native command '${script}'`);
    script = script.replace(/^desktop:/, '').trim();
    return await this.executeDesktopCommand(script, _.isArray(args) ? args[0] : args);
  }
  throw new errors.NotImplementedError();
};

commands.executeDesktopCommand = async function executeDesktopCommand (command, opts = {}) {
  if (!_.has(DESKTOP_COMMANDS_MAPPING, command)) {
    throw new errors.UnknownCommandError(`Unknown desktop command "${command}". ` +
      `Only ${_.keys(DESKTOP_COMMANDS_MAPPING)} commands are supported.`);
  }
  return await this[DESKTOP_COMMANDS_MAPPING[command]](opts);
};

export default commands;
