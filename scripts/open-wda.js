const path = require('node:path');
const {exec} = require('teen_process');
const {logger} = require('appium/support');
const XCODEPROJ_NAME = 'WebDriverAgentMac.xcodeproj';

const log = logger.getLogger('WDA');

async function openWda() {
  const dstPath = path.resolve(__dirname, '..', 'WebDriverAgentMac', XCODEPROJ_NAME);
  log.info(`Opening '${dstPath}'`);
  await exec('open', [dstPath]);
}

(async () => await openWda())();
