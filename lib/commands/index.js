import findCmds from './find';
import executeCmds from './execute';
import gestureCmds from './gestures';
import sourceCmds from './source';

const commands = {};
Object.assign(
  commands,
  findCmds,
  executeCmds,
  gestureCmds,
  sourceCmds,
  // add other command types here
);

export { commands };
export default commands;
