import wd from 'wd';
import { startServer } from '../..';
import chaiAsPromised from 'chai-as-promised';
import chai from 'chai';
import { HOST, PORT, MOCHA_TIMEOUT, TEXT_EDIT_BUNDLE_ID } from '../utils';

chai.should();
chai.use(chaiAsPromised);

const CAPS = {
  platformName: 'mac',
  bundleId: TEXT_EDIT_BUNDLE_ID,
};

describe('Mac2Driver - find elements', function () {
  this.timeout(MOCHA_TIMEOUT);

  const ACCESSIBILITY_ID = 'duplicateDocument:';

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

  it('should find by accessibility id', async function () {
    const el = await driver.elementByAccessibilityId(ACCESSIBILITY_ID);
    el.should.exist;
  });

  it('should find multiple by accessibility id', async function () {
    const els = await driver.elementsByAccessibilityId(ACCESSIBILITY_ID);
    els.length.should.eql(1);
    await els[0].getAttribute('identifier').should.eventually.eql(ACCESSIBILITY_ID);
  });
});


