import assert from 'node:assert/strict';
import {describe, it, beforeEach, afterEach} from 'node:test';

import {remote} from 'webdriverio';
import type {Browser} from 'webdriverio';

import {HOST, PORT, TEST_TIMEOUT, TEXT_EDIT_BUNDLE_ID, elementId} from '../utils.js';

const CAPS = {
  platformName: 'mac',
  'appium:automationName': 'mac2',
  'appium:bundleId': TEXT_EDIT_BUNDLE_ID,
  'appium:showServerLogs': true,
};

describe('Mac2Driver - elements interaction', {timeout: TEST_TIMEOUT}, () => {
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

  it('should set a text to a text view', async () => {
    const el = await driver!.findElement('class name', 'XCUIElementTypeTextView');
    await driver!.elementSendKeys(elementId(el), 'hello world');
    assert.equal(await driver!.getElementText(elementId(el)), 'hello world');
  });

  it('should click a button by absolute coordinate', async () => {
    const boldLocator = ['-ios predicate string', 'elementType == 12 AND label == "bold"'] as const;
    const [el] = await driver!.findElements(...boldLocator);
    assert.ok(el);
    assert.equal(await driver!.getElementAttribute(elementId(el), 'value'), '0');
    const {x, y, width, height} = (await driver!.getElementAttribute(elementId(el), 'frame')) as any;
    await driver!.executeScript('macos: click', [
      {
        x: x + width / 2,
        y: y + height / 2,
      },
    ]);
    const [boldButton] = await driver!.findElements(...boldLocator);
    assert.equal(await driver!.getElementAttribute(elementId(boldButton), 'value'), '1');
  });

  it('should clear a text view', async () => {
    const el = await driver!.findElement('class name', 'XCUIElementTypeTextView');
    await driver!.elementSendKeys(elementId(el), 'hello world');
    assert.equal(await driver!.getElementText(elementId(el)), 'hello world');
    await driver!.elementClear(elementId(el));
    assert.equal(await driver!.getElementText(elementId(el)), '');
  });

  it('should send keys with modifiers into a text view', async () => {
    const el = await driver!.findElement('class name', 'XCUIElementTypeTextView');
    await driver!.elementClick(elementId(el));
    const flagsShift = 1 << 1;
    await driver!.executeScript('macos: keys', [
      {
        keys: [
          {
            key: 'h',
            modifierFlags: flagsShift,
          },
          {
            key: 'i',
            modifierFlags: flagsShift,
          },
        ],
      },
    ]);
    assert.equal(await driver!.getElementText(elementId(el)), 'HI');
  });

  it('should open context menu if left click with Ctrl depressed', async () => {
    const el = await driver!.findElement('class name', 'XCUIElementTypeTextView');
    const flagsCtrl = 1 << 2;
    await driver!.executeScript('macos: click', [
      {
        elementId: elementId(el),
        keyModifierFlags: flagsCtrl,
      },
    ]);
    const els = await driver!.findElements('-ios predicate string', `title == 'Paste'`);
    // the Edit menu item + the context menu one
    assert.ok(els.length > 1);
  });
});
