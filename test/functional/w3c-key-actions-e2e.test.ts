import assert from 'node:assert/strict';
import {execFile} from 'node:child_process';
import {describe, it, beforeEach, afterEach} from 'node:test';
import {promisify} from 'node:util';

import {remote} from 'webdriverio';
import type {Browser} from 'webdriverio';

import {HOST, PORT, TEST_TIMEOUT, TEXT_EDIT_BUNDLE_ID, elementId} from '../utils.js';

const execFileAsync = promisify(execFile);
const CAPS = {
  platformName: 'mac',
  'appium:automationName': 'mac2',
  'appium:bundleId': TEXT_EDIT_BUNDLE_ID,
  'appium:showServerLogs': true,
};
const KEY_CONTROL = '\uE009';
const KEY_SHIFT = '\uE008';
const FLAG_MASK_CONTROL = 0x40000;
const FLAG_MASK_SHIFT = 0x20000;

// Modifier flags of the current login session (kCGEventSourceStateCombinedSessionState)
const JXA_SESSION_FLAGS = `
ObjC.import('CoreGraphics');
$.CGEventSourceFlagsState(0);
`;

async function sessionFlags(): Promise<number> {
  const {stdout} = await execFileAsync('osascript', ['-l', 'JavaScript', '-e', JXA_SESSION_FLAGS]);
  return parseInt(stdout.trim(), 10);
}

const down = (value: string) => ({type: 'keyDown', value});
const up = (value: string) => ({type: 'keyUp', value});
const press = (value: string) => [down(value), up(value)];
const keyActions = (actions: object[]) => [{type: 'key', id: 'keyboard', actions}];

describe('Mac2Driver - W3C key actions', {timeout: TEST_TIMEOUT}, () => {
  let driver: Browser | null = null;
  let textView = '';

  const getText = async () => await driver!.getElementText(textView);

  beforeEach(async () => {
    driver = await remote({
      hostname: HOST,
      port: PORT,
      capabilities: CAPS,
    });
    textView = elementId(await driver.findElement('class name', 'XCUIElementTypeTextView'));
    await driver.elementClick(textView);
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

  it('should type plain keys', async () => {
    await driver!.performActions(keyActions([...press('a'), ...press('b'), ...press('c')]));
    assert.equal(await getText(), 'abc');
  });

  it('should keep a modifier held across several keys and release it afterwards', async () => {
    await driver!.elementSendKeys(textView, 'abcdef');
    // Control+A moves the caret to the line start, Control+D deletes the next char, Control+E moves it to the end
    await driver!.performActions(
      keyActions([down(KEY_CONTROL), ...press('a'), ...press('d'), ...press('e'), up(KEY_CONTROL), ...press('!')]),
    );
    assert.equal(await getText(), 'bcdef!');
    assert.equal((await sessionFlags()) & FLAG_MASK_CONTROL, 0);
  });

  it('should apply a held modifier only until it is released', async () => {
    await driver!.performActions(
      keyActions([down(KEY_SHIFT), ...press('a'), ...press('b'), up(KEY_SHIFT), ...press('c')]),
    );
    assert.equal(await getText(), 'ABc');
    assert.equal((await sessionFlags()) & FLAG_MASK_SHIFT, 0);
  });

  it('should honor pauses', async () => {
    const started = Date.now();
    await driver!.performActions(keyActions([...press('a'), {type: 'pause', duration: 1500}, ...press('b')]));
    assert.ok(Date.now() - started >= 1500);
    assert.equal(await getText(), 'ab');
  });

  it('should fail if a key down has no matching key up', async () => {
    await assert.rejects(driver!.performActions(keyActions([down('a')])), /must have a closing Key Up/);
  });

  it('should fail if a key up has no matching key down', async () => {
    await assert.rejects(driver!.performActions(keyActions([up('a')])), /is not balanced/);
  });
});
