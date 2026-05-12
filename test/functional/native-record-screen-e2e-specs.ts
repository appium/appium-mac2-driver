import {remote} from 'webdriverio';
import type {Browser} from 'webdriverio';
import {setTimeout as delay} from 'node:timers/promises';
import {HOST, PORT, MOCHA_TIMEOUT, TEXT_EDIT_BUNDLE_ID} from '../utils';
import {expect, use} from 'chai';
import chaiAsPromised from 'chai-as-promised';

const CAPS = {
  platformName: 'mac',
  'appium:automationName': 'mac2',
  'appium:bundleId': TEXT_EDIT_BUNDLE_ID,
};

// How long to let the recording run before stopping it. Must be long enough
// for the underlying XCTest video writer to flush at least one frame to disk.
const RECORDING_DURATION_MS = 3000;
// Minimum reasonable size of the produced base64 payload. A few hundred bytes
// of header are always present even for a sub-second recording.
const MIN_BASE64_PAYLOAD_SIZE = 1024;

use(chaiAsPromised);

describe('Mac2Driver - native screen recording', function () {
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
    if (!driver) {
      return;
    }
    try {
      await driver.deleteSession();
    } finally {
      driver = null;
    }
  });

  it('should record a short clip and return a base64-encoded mp4', async function () {
    const info = (await driver!.executeScript('macos: startNativeScreenRecording', [
      {fps: 24},
    ])) as {uuid: string; fps: number; startedAt: number};
    expect(info).to.be.an('object');
    expect(info.uuid).to.be.a('string').and.not.empty;
    expect(info.fps).to.equal(24);

    await delay(RECORDING_DURATION_MS);

    const payload = (await driver!.executeScript('macos: stopNativeScreenRecording', [])) as string;
    expect(payload).to.be.a('string');
    expect(payload.length).to.be.at.least(MIN_BASE64_PAYLOAD_SIZE);

    // An mp4 file always starts with an `ftyp` box. Bytes 4..8 of the decoded
    // payload should spell the ascii string "ftyp".
    const decoded = Buffer.from(payload, 'base64');
    expect(decoded.length).to.be.at.least(8);
    expect(decoded.subarray(4, 8).toString('ascii')).to.equal('ftyp');
  });
});
