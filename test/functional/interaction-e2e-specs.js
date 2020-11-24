// import _ from 'lodash';
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

describe('Mac2Driver - elements interaction', function () {
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
      try {
        await driver.quit();
      } finally {
        driver = null;
      }
    }
  });

  it('should set a text to a text view', async function () {
    const el = await driver.elementByClassName('XCUIElementTypeTextView');
    await el.sendKeys('hello world');
    await el.text().should.eventually.eql('hello world');
  });

  it('should clear a text view', async function () {
    const el = await driver.elementByClassName('XCUIElementTypeTextView');
    await el.sendKeys('hello world');
    await el.text().should.eventually.eql('hello world');
    await el.clear();
    await el.text().should.eventually.eql('');
  });

  it('should send keys with modifiers into a text view', async function () {
    const el = await driver.elementByClassName('XCUIElementTypeTextView');
    await el.click();
    const flagsShift = 1 << 1;
    await driver.execute('macos: keys', {
      keys: [{
        key: 'h',
        modifierFlags: flagsShift,
      }, {
        key: 'i',
        modifierFlags: flagsShift,
      }]
    });
    await el.text().should.eventually.eql('HI');
  });

  it('should open context menu if left click with Ctrl depressed', async function () {
    const el = await driver.elementByClassName('XCUIElementTypeTextView');
    const flagsCtrl = 1 << 2;
    await driver.execute('macos: click', {
      element: el,
      keyModifierFlags: flagsCtrl,
    });
    const els = await driver.elements('-ios predicate string', `title == 'Import Image'`);
    els.length.should.be.above(1);
  });

});
