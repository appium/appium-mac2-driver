import _ from 'lodash';
import { remote } from 'webdriverio';
import type { Browser } from 'webdriverio';
import { HOST, PORT, MOCHA_TIMEOUT, TEXT_EDIT_BUNDLE_ID } from '../utils';
import { expect, use } from 'chai';
import chaiAsPromised from 'chai-as-promised';

const CAPS = {
  platformName: 'mac',
  'appium:automationName': 'mac2',
  'appium:bundleId': TEXT_EDIT_BUNDLE_ID,
};

use(chaiAsPromised);

describe('Mac2Driver - find elements', function () {
  this.timeout(MOCHA_TIMEOUT);

  let driver: Browser | null;

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
    const el = await driver!.findElement('accessibility id', 'duplicateDocument:');
    expect(el).exist;
  });

  it('should find multiple by accessibility id', async function () {
    const els = await driver!.findElements('accessibility id', 'duplicateDocument:');
    expect(els.length).eql(1);
    await expect(driver!.getElementAttribute(els[0] as any, 'identifier')).eventually.eql('duplicateDocument:');
  });

  it('should find by class name', async function () {
    const el = await driver!.findElement('class name', 'XCUIElementTypeTextView');
    expect(el).exist;
  });

  it('should find by multiple by class name', async function () {
    const els = await driver!.findElement('class name', 'XCUIElementTypeRulerMarker');
    expect((els as unknown as any[]).length).be.above(1);
  });

  it('should find by predicate', async function () {
    const els = await driver!.findElements('-ios predicate string', 'elementType == 2');
    expect(els.length).be.above(0);
    await expect(driver!.getElementAttribute(els[0] as any, 'elementType')).eventually.eql('2');
  });

  it('should find by class chain', async function () {
    const els = await driver!.findElements('-ios class chain', '**/XCUIElementTypePopUpButton');
    expect(els.length).be.above(0);
    await expect(driver!.getElementAttribute(_.first(els)! as any, 'elementType')).eventually.eql('14');
    await expect(driver!.getElementAttribute(_.last(els)! as any, 'elementType')).eventually.eql('14');
  });

  it('should find by xpath', async function () {
    const el = await driver!.findElement(
      'xpath',
      '//XCUIElementTypePopUpButton[@value="Regular" and @label="type face"]'
    );
    expect(el).exist;
  });

  it('should find by absolute xpath', async function () {
    // xpath index starts from 1
    const el = await driver!.findElement(
      'xpath',
      '/XCUIElementTypeApplication[@title="TextEdit"]/XCUIElementTypeWindow[1]/XCUIElementTypeScrollView[1]'
    );
    expect(el).exist;
  });

  it('should find multiple by xpath', async function () {
    const els = await driver!.findElements(
      'xpath',
      '//XCUIElementTypePopUpButton[@enabled="true"]'
    );
    expect(els.length).be.above(1);
    await expect(driver!.getElementAttribute(_.first(els)! as any, 'elementType')).eventually.eql('14');
    await expect(driver!.getElementAttribute(_.last(els)! as any, 'elementType')).eventually.eql('14');
  });

  it('should find subelements', async function () {
    const el = await driver!.findElement('class name', 'XCUIElementTypeRuler');
    expect(el).exist;
    const subEls = await driver!.findElementsFromElement(el as any, '-ios class chain', '*');
    expect(subEls.length).be.above(1);
    await expect(driver!.getElementAttribute(_.first(subEls)! as any, 'elementType')).eventually.eql('72');
    await expect(driver!.getElementAttribute(_.last(subEls)! as any, 'elementType')).eventually.eql('72');
  });

});
