import { remote } from 'webdriverio';
import { startServer } from '../server';
import chaiAsPromised from 'chai-as-promised';
import chai from 'chai';
import os from 'os';
import path from 'path';
import { fs } from 'appium/support';
import { HOST, PORT, MOCHA_TIMEOUT, TEXT_EDIT_BUNDLE_ID } from '../utils';

chai.should();
chai.use(chaiAsPromised);

const TEST_FILE = path.resolve(os.tmpdir(), 'test.test');

const CAPS = {
  platformName: 'mac',
  'appium:bundleId': TEXT_EDIT_BUNDLE_ID,
  'appium:prerun': {command: `do shell script "touch ${TEST_FILE}"`},
  'appium:postrun': {command: `do shell script "rm ${TEST_FILE}"`},
};

describe('Mac2Driver - caps', function () {
  this.timeout(MOCHA_TIMEOUT);

  let server;
  let driver;
  before(async function () {
    server = await startServer(PORT, HOST, true);
  });
  after(async function () {
    if (server) {
      await server.close();
      server = null;
    }
  });
  beforeEach(async function () {
    driver = await remote({
      hostname: HOST,
      port: PORT,
      capabilities: CAPS,
    });
  });
  afterEach(async function () {
    if (driver) {
      try {
        await driver.deleteSession();
      } finally {
        driver = null;
      }
    }
  });

  it('should execute scripts from capabilities', async function () {
    await fs.exists(TEST_FILE).should.eventually.be.true;
    try {
      await driver.deleteSession();
    } finally {
      driver = null;
    }
    await fs.exists(TEST_FILE).should.eventually.be.false;
  });

});
