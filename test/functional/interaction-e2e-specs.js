import _ from 'lodash';
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
  showServerLogs: true,
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

  it('should click a button by absolute coordinate', async function () {
    const el = _.first(await driver.elements('-ios predicate string', 'elementType == 12 AND label == "bold"'));
    const {x, y, width, height} = await el.getAttribute('frame');
    await driver.execute('macos: click', {
      x: x + width / 2,
      y: y + height / 2,
    });
    const els = await driver.elements('-ios predicate string', 'value == "Bold" AND label == "type face"');
    els.length.should.eql(1);
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
      elementId: el,
      keyModifierFlags: flagsCtrl,
    });
    const els = await driver.elements('-ios predicate string', `title == 'Import Image'`);
    els.length.should.be.above(1);
  });

});
