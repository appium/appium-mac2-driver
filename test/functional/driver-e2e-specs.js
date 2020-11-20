import wd from 'wd';
import { startServer } from '../..';
import chaiAsPromised from 'chai-as-promised';
import chai from 'chai';
import { HOST, PORT, MOCHA_TIMEOUT } from '../utils';

chai.should();
chai.use(chaiAsPromised);

const CAPS = {
  platformName: 'mac',
  bundleId: 'com.apple.TextEdit',
};

describe('Mac2Driver', function () {
  this.timeout(MOCHA_TIMEOUT);

  let server;
  let driver;
  before(async function () {
    server = await startServer(PORT, HOST);
  });
  after(async function () {
    if (server) {
      await server.close();
      server = null;
    }
  });
  beforeEach(async function () {
    driver = wd.promiseChainRemote(HOST, PORT);
    await driver.init(CAPS);
  });
  afterEach(async function () {
    if (driver) {
      await driver.quit();
      driver = null;
    }
  });

  it('should start and stop a session', async function () {
    const source = await driver.source();
    source.should.not.be.empty;
  });
});


