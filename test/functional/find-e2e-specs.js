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
};

describe('Mac2Driver - find elements', function () {
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

  it('should find by accessibility id', async function () {
    const el = await driver.elementByAccessibilityId('duplicateDocument:');
    el.should.exist;
  });

  it('should find multiple by accessibility id', async function () {
    const els = await driver.elementsByAccessibilityId('duplicateDocument:');
    els.length.should.eql(1);
    await els[0].getAttribute('identifier').should.eventually.eql('duplicateDocument:');
  });

  it('should find by class name', async function () {
    const el = await driver.elementByClassName('XCUIElementTypeTextView');
    el.should.exist;
  });

  it('should find by multiple by class name', async function () {
    const els = await driver.elementsByClassName('XCUIElementTypeRulerMarker');
    els.length.should.be.above(1);
  });

  it('should find by predicate', async function () {
    const els = await driver.elements('-ios predicate string', 'elementType == 2');
    els.length.should.be.above(0);
    await els[0].getAttribute('elementType').should.eventually.eql('2');
  });

  it('should find by class chain', async function () {
    const els = await driver.elements('-ios class chain', '**/XCUIElementTypePopUpButton');
    els.length.should.be.above(0);
    await _.first(els).getAttribute('elementType').should.eventually.eql('14');
    await _.last(els).getAttribute('elementType').should.eventually.eql('14');
  });

  it('should find by xpath', async function () {
    const el = await driver.elementByXPath(
      '//XCUIElementTypePopUpButton[@value="Regular" and @label="type face"]');
    el.should.exist;
  });

  it('should find by absolute xpath', async function () {
    // xpath index starts from 1
    const el = await driver.elementByXPath(
      '/XCUIElementTypeApplication[@title="TextEdit"]/XCUIElementTypeWindow[1]/XCUIElementTypeScrollView[1]');
    el.should.exist;
  });

  it('should find multiple by xpath', async function () {
    const els = await driver.elementsByXPath('//XCUIElementTypePopUpButton[@enabled="true"]');
    els.length.should.be.above(1);
    await _.first(els).getAttribute('elementType').should.eventually.eql('14');
    await _.last(els).getAttribute('elementType').should.eventually.eql('14');
  });

  it('should find subelements', async function () {
    const el = await driver.elementByClassName('XCUIElementTypeRuler');
    el.should.exist;
    const subEls = await el.elements('-ios class chain', '*');
    subEls.length.should.be.above(1);
    await _.first(subEls).getAttribute('elementType').should.eventually.eql('72');
    await _.last(subEls).getAttribute('elementType').should.eventually.eql('72');
  });

});


