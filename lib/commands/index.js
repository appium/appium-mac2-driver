import findCmds from './find';
import executeCmds from './execute';
import gestureCmds from './gestures';
import sourceCmds from './source';
import appManagementCmds from './app-management';
import appleScriptCmds from './applescript';
import screenRecordingCmds from './record-screen';

const commands = {};
Object.assign(
  commands,
  findCmds,
  executeCmds,
  gestureCmds,
  sourceCmds,
  appManagementCmds,
  appleScriptCmds,
  screenRecordingCmds,
  // add other command types here
);

export { commands };
export default commands;
