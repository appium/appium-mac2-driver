import GeckoDriver from './lib/driver';
import { startServer } from './lib/server';
import yargs from 'yargs';
import { asyncify } from 'asyncbox';

const DEFAULT_HOST = 'localhost';
const DEFAULT_PORT = 4797;

async function main () {
  let port = yargs.argv.port || yargs.argv.p || DEFAULT_PORT;
  let host = yargs.argv.host || yargs.argv.h || DEFAULT_HOST;
  return await startServer(port, host);
}

if (require.main === module) {
  asyncify(main);
}

export default GeckoDriver;
export { GeckoDriver, startServer };
