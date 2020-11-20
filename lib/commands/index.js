import findCmds from './find';

const commands = {};
Object.assign(
  commands,
  findCmds,
  // add other command types here
);

export { commands };
export default commands;
