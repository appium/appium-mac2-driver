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

describe('Mac2Driver - basic', {timeout: TEST_TIMEOUT}, () => {
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

  it('should retrieve xml source', async () => {
    const source = await driver!.getPageSource();
    assert.ok(source.includes('<?xml version="1.0" encoding="UTF-8"?>'));
  });

  it('should take screenshots', async () => {
    const screenshot = await driver!.takeScreenshot();
    assert.ok(screenshot.startsWith('iVBOR'));
  });

  it('should retrieve description source', async () => {
    const source = await driver!.executeScript('macos: source', [
      {
        format: 'description',
      },
    ]);
    assert.ok((source as string).includes('Element subtree'));
  });
});
