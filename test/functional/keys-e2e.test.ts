import assert from 'node:assert/strict';
import {execFile} from 'node:child_process';
import {describe, it, beforeEach, afterEach} from 'node:test';
import {promisify} from 'node:util';

import {remote} from 'webdriverio';
import type {Browser} from 'webdriverio';

import {HOST, PORT, TEST_TIMEOUT, TEXT_EDIT_BUNDLE_ID} from '../utils.js';

const execFileAsync = promisify(execFile);
const CAPS = {
  platformName: 'mac',
  'appium:automationName': 'mac2',
  'appium:bundleId': TEXT_EDIT_BUNDLE_ID,
  'appium:showServerLogs': true,
};
const FLAG_CONTROL = 1 << 2;
const FLAG_FUNCTION = 1 << 5;
const MISSION_CONTROL_SETTLE_MS = 2000;

// Mission Control spawns extra WindowManager-owned windows (no Screen Recording needed to count them)
const JXA_WM_WINDOW_COUNT = `
ObjC.import('CoreGraphics');
const l = ObjC.deepUnwrap(ObjC.castRefToObject($.CGWindowListCopyWindowInfo($.kCGWindowListOptionOnScreenOnly, 0)));
l.filter((w) => w.kCGWindowOwnerName === 'WindowManager').length;
`;

async function windowManagerWindowCount(): Promise<number> {
  const {stdout} = await execFileAsync('osascript', ['-l', 'JavaScript', '-e', JXA_WM_WINDOW_COUNT]);
  return parseInt(stdout.trim(), 10);
}

// Mission Control shortcut (symbolic hotkey 32) must be enabled and bound to Control+UpArrow
const JXA_MISSION_CONTROL_SHORTCUT = `
ObjC.import('Foundation');
const d = ObjC.deepUnwrap($.NSUserDefaults.standardUserDefaults.persistentDomainForName('com.apple.symbolichotkeys'));
JSON.stringify(((d || {}).AppleSymbolicHotKeys || {})['32'] || null);
`;
const KEYCODE_UP_ARROW = 126;

async function isMissionControlShortcutAssigned(): Promise<boolean> {
  try {
    const {stdout} = await execFileAsync('osascript', ['-l', 'JavaScript', '-e', JXA_MISSION_CONTROL_SHORTCUT]);
    const hotkey = JSON.parse(stdout.trim());
    const [, keyCode, modifiers] = hotkey?.value?.parameters ?? [];
    return Boolean(hotkey?.enabled) && keyCode === KEYCODE_UP_ARROW && Boolean(modifiers & (FLAG_CONTROL << 16));
  } catch {
    return false;
  }
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

describe('Mac2Driver - system shortcuts via keys', {timeout: TEST_TIMEOUT}, () => {
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

  // Without the Function flag the shortcut does not match (and with it, XCTest's ~5s key hold closes it on release)
  it('should NOT trigger Mission Control with plain Control+UpArrow typed via XCTest', async () => {
    const before = await windowManagerWindowCount();
    await driver!.executeScript('macos: keys', [
      {keys: [{key: 'XCUIKeyboardKeyUpArrow', modifierFlags: FLAG_CONTROL}]},
    ]);
    await sleep(MISSION_CONTROL_SETTLE_MS);
    assert.equal(await windowManagerWindowCount(), before);
  });

  it('should keep Mission Control open with Control+Function+UpArrow and a short confirmationInterval', async (t) => {
    if (!(await isMissionControlShortcutAssigned())) {
      t.skip('The Mission Control shortcut is not enabled or is not bound to Control+UpArrow');
      return;
    }
    const before = await windowManagerWindowCount();
    try {
      await driver!.executeScript('macos: keys', [
        {
          keys: [{key: 'XCUIKeyboardKeyUpArrow', modifierFlags: FLAG_CONTROL | FLAG_FUNCTION}],
          confirmationInterval: 0.05,
        },
      ]);
      await sleep(MISSION_CONTROL_SETTLE_MS);
      assert.ok((await windowManagerWindowCount()) > before);
    } finally {
      await driver!
        .executeScript('macos: keys', [{keys: ['XCUIKeyboardKeyEscape'], confirmationInterval: 0.05}])
        .catch(() => {});
    }
    await sleep(MISSION_CONTROL_SETTLE_MS);
    assert.equal(await windowManagerWindowCount(), before);
  });

  for (const [title, value] of [
    ['negative', -1],
    ['a boolean', false],
  ] as const) {
    it(`should fail if confirmationInterval is ${title}`, async () => {
      await assert.rejects(
        driver!.executeScript('macos: keys', [{keys: ['a'], confirmationInterval: value}]),
        /non-negative number/,
      );
    });
  }
});
