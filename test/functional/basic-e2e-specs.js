import _ from 'lodash';
import { remote } from 'webdriverio';
import { HOST, PORT, MOCHA_TIMEOUT, TEXT_EDIT_BUNDLE_ID } from '../utils';

const CAPS = {
  platformName: 'mac',
  'appium:automationName': 'mac2',
  'appium:bundleId': TEXT_EDIT_BUNDLE_ID,
};

describe('Mac2Driver - basic', function () {
  this.timeout(MOCHA_TIMEOUT);

  let driver;
  let chai;

  before(async function () {
    chai = await import('chai');
    const chaiAsPromised = await import('chai-as-promised');

    chai.should();
    chai.use(chaiAsPromised.default);
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

  it('should retrieve xml source', async function () {
    const source = await driver.getPageSource();
    _.includes(source, '<?xml version="1.0" encoding="UTF-8"?>').should.be.true;
  });

  it('should take screenshots', async function () {
    const screenshot = await driver.takeScreenshot();
    _.startsWith(screenshot, 'iVBOR').should.be.true;
  });

  it('should retrieve description source', async function () {
    const source = await driver.executeScript('macos: source', [{
      format: 'description',
    }]);
    _.includes(source, 'Element subtree').should.be.true;
  });

});


