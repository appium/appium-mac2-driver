import assert from 'node:assert/strict';
import {describe, it, before, after} from 'node:test';

import {remote} from 'webdriverio';
import type {Browser} from 'webdriverio';

import {HOST, PORT, TEST_TIMEOUT, TEXT_EDIT_BUNDLE_ID} from '../utils.js';

const CAPS = {
  platformName: 'mac',
  'appium:automationName': 'mac2',
  'appium:bundleId': TEXT_EDIT_BUNDLE_ID,
};

describe('Mac2Driver - windows', {timeout: TEST_TIMEOUT}, () => {
  let driver: Browser;

  before(async () => {
    driver = await remote({hostname: HOST, port: PORT, capabilities: CAPS});
  });

  after(async () => {
    await driver?.deleteSession();
  });

  it('should list displays with rects', async () => {
    const displays = (await driver.executeScript('macos: listDisplays', [])) as Record<string, any>;
    const main = Object.values(displays).find((d) => d.isMain);
    assert.ok(main.rect.width > 0 && main.rect.height > 0);
  });

  it('should list windows', async () => {
    const windows = (await driver.executeScript('macos: listWindows', [])) as any[];
    assert.ok(windows.length > 0);
    assert.ok(windows[0].rect.width > 0);
  });

  it('should resize and move a window', async () => {
    const win = (await driver.executeScript('macos: adjustWindow', [{x: 120, y: 140, width: 640, height: 480}])) as any;
    assert.deepEqual(win.rect, {x: 120, y: 140, width: 640, height: 480});
  });

  it('should minimize and restore a window', async () => {
    const minimized = (await driver.executeScript('macos: adjustWindow', [{state: 'minimized'}])) as any;
    assert.equal(minimized.isMinimized, true);
    const restored = (await driver.executeScript('macos: adjustWindow', [{state: 'normal'}])) as any;
    assert.equal(restored.isMinimized, false);
  });

  it('should maximize a window on a display', async () => {
    const displays = Object.values((await driver.executeScript('macos: listDisplays', [])) as Record<string, any>);
    const win = (await driver.executeScript('macos: adjustWindow', [
      {state: 'maximized', displayId: displays[0].id},
    ])) as any;
    assert.equal(win.displayId, displays[0].id);
    assert.ok(win.rect.width <= displays[0].rect.width && win.rect.height <= displays[0].rect.height);
  });

  it('should reject state combined with geometry', async () => {
    await assert.rejects(
      driver.executeScript('macos: adjustWindow', [{state: 'minimized', x: 10}]),
      /cannot be combined/,
    );
  });

  it('should move a window to a display', async () => {
    const displays = Object.values((await driver.executeScript('macos: listDisplays', [])) as Record<string, any>);
    const win = (await driver.executeScript('macos: adjustWindow', [{displayId: displays[0].id, x: 50, y: 60}])) as any;
    assert.equal(win.displayId, displays[0].id);
    assert.equal(win.rect.x, displays[0].rect.x + 50);
  });

  it('should reject an unknown display', async () => {
    await assert.rejects(
      driver.executeScript('macos: adjustWindow', [{displayId: 999999, x: 0}]),
      /display .* is unknown/,
    );
  });
});
