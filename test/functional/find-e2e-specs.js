import _ from 'lodash';
import { remote } from 'webdriverio';
import chaiAsPromised from 'chai-as-promised';
import chai from 'chai';
import { HOST, PORT, MOCHA_TIMEOUT, TEXT_EDIT_BUNDLE_ID } from '../utils';

chai.should();
chai.use(chaiAsPromised);

const CAPS = {
  platformName: 'mac',
  'appium:automationName': 'mac2',
  'appium:bundleId': TEXT_EDIT_BUNDLE_ID,
};

describe('Mac2Driver - find elements', function () {
  this.timeout(MOCHA_TIMEOUT);

  let driver;
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

  it('should find by accessibility id', async function () {
    const el = await driver.findElement('accessibility id', 'duplicateDocument:');
    el.should.exist;
  });

  it('should find multiple by accessibility id', async function () {
    const els = await driver.findElements('accessibility id', 'duplicateDocument:');
    els.length.should.eql(1);
    await driver.getElementAttribute(els[0], 'identifier').should.eventually.eql('duplicateDocument:');
  });

  it('should find by class name', async function () {
    const el = await driver.findElement('class name', 'XCUIElementTypeTextView');
    el.should.exist;
  });

  it('should find by multiple by class name', async function () {
    const els = await driver.findElement('class name', 'XCUIElementTypeRulerMarker');
    els.length.should.be.above(1);
  });

  it('should find by predicate', async function () {
    const els = await driver.findElements('-ios predicate string', 'elementType == 2');
    els.length.should.be.above(0);
    await driver.getElementAttribute(els[0], 'elementType').should.eventually.eql('2');
  });

  it('should find by class chain', async function () {
    const els = await driver.findElements('-ios class chain', '**/XCUIElementTypePopUpButton');
    els.length.should.be.above(0);
    await driver.getElementAttribute(_.first(els), 'elementType').should.eventually.eql('14');
    await driver.getElementAttribute(_.last(els), 'elementType').should.eventually.eql('14');
  });

  it('should find by xpath', async function () {
    const el = await driver.findElement(
      'xpath',
      '//XCUIElementTypePopUpButton[@value="Regular" and @label="type face"]'
    );
    el.should.exist;
  });

  it('should find by absolute xpath', async function () {
    // xpath index starts from 1
    const el = await driver.findElement(
      'xpath',
      '/XCUIElementTypeApplication[@title="TextEdit"]/XCUIElementTypeWindow[1]/XCUIElementTypeScrollView[1]'
    );
    el.should.exist;
  });

  it('should find multiple by xpath', async function () {
    const els = await driver.findElements(
      'xpath',
      '//XCUIElementTypePopUpButton[@enabled="true"]'
    );
    els.length.should.be.above(1);
    await driver.getElementAttribute(_.first(els), 'elementType').should.eventually.eql('14');
    await driver.getElementAttribute(_.last(els), 'elementType').should.eventually.eql('14');
  });

  it('should find subelements', async function () {
    const el = await driver.findElement('class name', 'XCUIElementTypeRuler');
    el.should.exist;
    const subEls = await driver.findElementsFromElement(el, '-ios class chain', '*');
    subEls.length.should.be.above(1);
    await driver.getElementAttribute(_.first(subEls), 'elementType').should.eventually.eql('72');
    await driver.getElementAttribute(_.last(subEls), 'elementType').should.eventually.eql('72');
  });

});


