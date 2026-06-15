import {describe, it, beforeEach, afterEach} from 'node:test';
import assert from 'node:assert/strict';
import {remote} from 'webdriverio';
import type {Browser} from 'webdriverio';
import {HOST, PORT, TEST_TIMEOUT, TEXT_EDIT_BUNDLE_ID} from '../utils.js';

const CAPS = {
  platformName: 'mac',
  'appium:automationName': 'mac2',
  'appium:bundleId': TEXT_EDIT_BUNDLE_ID,
};

describe('Mac2Driver - find elements', {timeout: TEST_TIMEOUT}, () => {
  let driver: Browser | null = null;

  beforeEach(async () => {
    driver = await remote({
      hostname: HOST,
      port: PORT,
      capabilities: CAPS,
    });
  });

  afterEach(async () => {
    if (driver) {
      try {
        await driver.deleteSession();
      } finally {
        driver = null;
      }
    }
  });

  it('should find by accessibility id', async () => {
    const el = await driver!.findElement('accessibility id', 'duplicateDocument:');
    assert.ok(el);
  });

  it('should find multiple by accessibility id', async () => {
    const els = await driver!.findElements('accessibility id', 'duplicateDocument:');
    assert.equal(els.length, 1);
    assert.equal(
      await driver!.getElementAttribute(String(els[0]), 'identifier'),
      'duplicateDocument:',
    );
  });

  it('should find by class name', async () => {
    const el = await driver!.findElement('class name', 'XCUIElementTypeTextView');
    assert.ok(el);
  });

  it('should find by multiple by class name', async () => {
    const els = await driver!.findElements('class name', 'XCUIElementTypeRulerMarker');
    assert.ok(els.length > 1);
  });

  it('should find by predicate', async () => {
    const els = await driver!.findElements('-ios predicate string', 'elementType == 2');
    assert.ok(els.length > 0);
    assert.equal(await driver!.getElementAttribute(String(els[0]), 'elementType'), '2');
  });

  it('should find by class chain', async () => {
    const els = await driver!.findElements('-ios class chain', '**/XCUIElementTypePopUpButton');
    assert.ok(els.length > 0);
    assert.equal(await driver!.getElementAttribute(String(els[0]), 'elementType'), '14');
  });

  it('should find by xpath', async () => {
    const el = await driver!.findElement(
      'xpath',
      '//XCUIElementTypePopUpButton[@value="Regular" and @label="type face"]',
    );
    assert.ok(el);
  });

  it('should find by absolute xpath', async () => {
    const el = await driver!.findElement(
      'xpath',
      '/XCUIElementTypeApplication[@title="TextEdit"]/XCUIElementTypeWindow[1]/XCUIElementTypeScrollView[1]',
    );
    assert.ok(el);
  });

  it('should find multiple by xpath', async () => {
    const els = await driver!.findElements(
      'xpath',
      '//XCUIElementTypePopUpButton[@enabled="true"]',
    );
    assert.ok(els.length > 1);
    assert.equal(await driver!.getElementAttribute(String(els[0]), 'elementType'), '14');
  });

  it('should find subelements', async () => {
    const el = await driver!.findElement('class name', 'XCUIElementTypeRuler');
    assert.ok(el);
    const subEls = await driver!.findElementsFromElement(String(el), '-ios class chain', '*');
    assert.ok(subEls.length > 1);
    assert.equal(await driver!.getElementAttribute(String(subEls[0]), 'elementType'), '72');
  });
});
