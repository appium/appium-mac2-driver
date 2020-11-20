import wd from 'wd';
import { startServer } from '../..';
import chaiAsPromised from 'chai-as-promised';
import chai from 'chai';
import { HOST, PORT, MOCHA_TIMEOUT } from '../utils';

chai.should();
chai.use(chaiAsPromised);

const CAPS = {
  browserName: 'MozillaFirefox',
  platformName: 'linux',
};

describe('Desktop Gecko Driver', function () {
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
    await driver.get('https://appium.io/');
    const button = await driver.elementByCss('#downloadLink');
    await button.text().should.eventually.eql('Download Appium');
  });
});


