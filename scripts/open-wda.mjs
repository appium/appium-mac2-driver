import path from 'node:path';
import {fileURLToPath} from 'node:url';

import {logger} from 'appium/support.js';
import {exec} from 'teen_process';
const XCODEPROJ_NAME = 'WebDriverAgentMac.xcodeproj';

const log = logger.getLogger('WDA');

async function openWda() {
  const __filename = fileURLToPath(import.meta.url);
  const __dirname = path.dirname(__filename);
  const dstPath = path.resolve(__dirname, '..', 'WebDriverAgentMac', XCODEPROJ_NAME);
  log.info(`Opening '${dstPath}'`);
  await exec('open', [dstPath]);
}

(async () => await openWda())();
