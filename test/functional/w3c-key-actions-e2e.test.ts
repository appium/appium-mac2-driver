import assert from 'node:assert/strict';
import {execFile} from 'node:child_process';
import {mkdtemp, realpath, rm, writeFile} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {basename, join} from 'node:path';
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
const KEY_RIGHT_SHIFT = '\uE050';
const KEY_COMMAND = '\uE03D';
const KEY_ARROW_LEFT = '\uE012';
const FLAG_MASK_CONTROL = 0x40000;
const FLAG_MASK_SHIFT = 0x20000;
const FLAG_MASK_COMMAND = 0x100000;

// Modifier flags of the current login session (kCGEventSourceStateCombinedSessionState)
const JXA_SESSION_FLAGS = `
ObjC.import('CoreGraphics');
$.CGEventSourceFlagsState(0);
`;

async function sessionFlags(): Promise<number> {
  const {stdout} = await execFileAsync('osascript', ['-l', 'JavaScript', '-e', JXA_SESSION_FLAGS]);
  const flags = parseInt(stdout.trim(), 10);
  assert.ok(Number.isFinite(flags), `Cannot parse the session modifier flags from '${stdout}'`);
  return flags;
}

const EMPTY_RTF = '{\\rtf1\\ansi\\deff0 }';
const DOCUMENT_WINDOW_TIMEOUT_MS = 15000;
const CLOSE_DOCUMENT_TIMEOUT_MS = 10000;
// The fixture, the modifier flags and the cleanup all use the desktop of the test machine
const IS_LOCAL_HOST = ['127.0.0.1', 'localhost', '::1', '[::1]'].includes(HOST);

// Closes only the document that has the given file path
const closeDocumentJxa = (docPath: string) => `
const path = ${JSON.stringify(docPath)};
Application('TextEdit').documents().forEach((d) => {
  try {
    if (d.path() === path) {
      d.close({saving: 'no'});
    }
  } catch {}
});
`;

const down = (value: string) => ({type: 'keyDown', value});
const up = (value: string) => ({type: 'keyUp', value});
const press = (value: string) => [down(value), up(value)];
const keyActions = (actions: object[]) => [{type: 'key', id: 'keyboard', actions}];

describe(
  'Mac2Driver - W3C key actions',
  {timeout: TEST_TIMEOUT, skip: !IS_LOCAL_HOST && 'The suite needs the Appium server on the local machine'},
  () => {
    let driver: Browser | null = null;
    let textView = '';
    let tmpDir = '';
    let docPath = '';

    const getText = async () => await driver!.getElementText(textView);

    beforeEach(async () => {
      driver = await remote({
        hostname: HOST,
        port: PORT,
        capabilities: CAPS,
      });
      // Open a fresh empty document, so there is always an editor with a known content
      tmpDir = await mkdtemp(join(tmpdir(), 'w3c-keys-'));
      const docName = basename(tmpDir);
      docPath = join(await realpath(tmpDir), `${docName}.rtf`);
      await writeFile(docPath, EMPTY_RTF);
      await execFileAsync('open', ['-a', 'TextEdit', docPath]);
      const predicate = `elementType == 4 AND title BEGINSWITH '${docName}'`;
      const windowId = await driver.waitUntil(
        async () => {
          try {
            return elementId(await driver!.findElement('-ios predicate string', predicate));
          } catch {
            return false;
          }
        },
        {timeout: DOCUMENT_WINDOW_TIMEOUT_MS, timeoutMsg: `The '${docName}' document window did not appear`},
      );
      textView = elementId(await driver.findElementFromElement(windowId, 'class name', 'XCUIElementTypeTextView'));
      await driver.elementClick(textView);
    });

    afterEach(async () => {
      try {
        // The session deletion terminates TextEdit, so the document is closed first
        if (docPath) {
          await execFileAsync('osascript', ['-l', 'JavaScript', '-e', closeDocumentJxa(docPath)], {
            timeout: CLOSE_DOCUMENT_TIMEOUT_MS,
          }).catch(() => {});
        }
      } finally {
        try {
          if (driver) {
            await driver.deleteSession();
          }
        } finally {
          driver = null;
          docPath = '';
          if (tmpDir) {
            await rm(tmpDir, {recursive: true, force: true});
          }
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

    it('should keep several modifiers held at once', async () => {
      await driver!.elementSendKeys(textView, 'abc');
      // Command+Shift+Left selects the text up to the line start, so the next key replaces it
      await driver!.performActions(
        keyActions([
          down(KEY_COMMAND),
          down(KEY_SHIFT),
          ...press(KEY_ARROW_LEFT),
          up(KEY_SHIFT),
          up(KEY_COMMAND),
          ...press('x'),
        ]),
      );
      assert.equal(await getText(), 'x');
      assert.equal((await sessionFlags()) & (FLAG_MASK_SHIFT | FLAG_MASK_COMMAND), 0);
    });

    it('should apply a held right-hand modifier', async () => {
      await driver!.performActions(
        keyActions([down(KEY_RIGHT_SHIFT), ...press('a'), up(KEY_RIGHT_SHIFT), ...press('b')]),
      );
      assert.equal(await getText(), 'Ab');
      assert.equal((await sessionFlags()) & FLAG_MASK_SHIFT, 0);
    });

    it('should keep Shift applied while the other Shift key is still pressed', async () => {
      // Both Shift keys share one XCTest flag, so releasing one of them must not release the flag
      await driver!.performActions(
        keyActions([
          down(KEY_SHIFT),
          down(KEY_RIGHT_SHIFT),
          up(KEY_SHIFT),
          ...press('a'),
          up(KEY_RIGHT_SHIFT),
          ...press('b'),
        ]),
      );
      assert.equal(await getText(), 'Ab');
      assert.equal((await sessionFlags()) & FLAG_MASK_SHIFT, 0);
    });

    it('should honor pauses', async () => {
      // A pause-only request measures the pause itself, without key synthesis
      const started = Date.now();
      await driver!.performActions(keyActions([{type: 'pause', duration: 300}]));
      assert.ok(Date.now() - started >= 300);
      await driver!.performActions(keyActions([...press('a'), {type: 'pause', duration: 100}, ...press('b')]));
      assert.equal(await getText(), 'ab');
    });

    it('should fail if the total duration of pauses is too long', async () => {
      await assert.rejects(
        driver!.performActions(keyActions([{type: 'pause', duration: 301000}, ...press('a')])),
        /must not exceed 300 seconds/,
      );
    });

    it('should fail if a key down has no matching key up', async () => {
      await assert.rejects(driver!.performActions(keyActions([down('a')])), /must have a closing Key Up/);
    });

    it('should fail if a key up has no matching key down', async () => {
      await assert.rejects(driver!.performActions(keyActions([up('a')])), /is not balanced/);
    });
  },
);
