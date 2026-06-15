import {describe, it, beforeEach, afterEach} from 'node:test';
import assert from 'node:assert/strict';
import {remote} from 'webdriverio';
import type {Browser} from 'webdriverio';
import type {EventEmitter} from 'node:events';
import {setTimeout as delay} from 'node:timers/promises';
import {waitForCondition} from 'asyncbox';
import {HOST, PORT, TEST_TIMEOUT, TEXT_EDIT_BUNDLE_ID} from '../utils.js';

// `webSocketUrl: true` requests a W3C BiDi session, which makes Appium
// return a `webSocketUrl` in the new-session response and makes
// webdriverio auto-connect a BiDi client to it. We then use that
// connection both to send `sessionSubscribe` and to receive the
// appium-specific video chunk events.
const CAPS = {
  platformName: 'mac',
  'appium:automationName': 'mac2',
  'appium:bundleId': TEXT_EDIT_BUNDLE_ID,
  webSocketUrl: true,
};

// How long to let the recording run before stopping it. Must be long enough
// for the underlying XCTest video writer to flush at least one frame to disk.
const RECORDING_DURATION_MS = 3000;
// Minimum reasonable size of the produced base64 payload. A few hundred bytes
// of header are always present even for a sub-second recording.
const MIN_BASE64_PAYLOAD_SIZE = 1024;
// Upper bound on how long we wait for the WebSocket to deliver the last
// chunk frames after `stopNativeScreenRecording` returns. The publisher is
// guaranteed to have emitted every byte by then; this only covers the
// localhost loopback round-trip, which is typically a few milliseconds.
const BIDI_DELIVERY_TIMEOUT_MS = 5000;
const CHUNK_EVENT = 'appium:mac2.nativeVideoRecordingChunkAdded';

interface ChunkEventParams {
  uuid: string;
  payload: string;
}

describe('Mac2Driver - native screen recording', {timeout: TEST_TIMEOUT}, () => {
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

  it('should record a short clip and stream identical chunks over BiDi', async () => {
    // webdriverio's `Browser` overrides `on/once` to only accept W3C
    // BiDi event names, but the underlying object is a plain
    // EventEmitter that receives every BiDi event the server pushes —
    // including appium-specific ones. Cast to listen for the chunk event.
    const bidiEvents = driver! as unknown as EventEmitter;

    // Decoded chunks accumulated as they arrive on the BiDi socket,
    // filtered to our recording's uuid (set up after start below).
    const ownChunks: Buffer[] = [];
    let ownBytes = 0;
    let onChunk: ((params: ChunkEventParams) => void) | undefined;

    try {
      await driver!.sessionSubscribe({events: [CHUNK_EVENT]});

      const info = (await driver!.executeScript('macos: startNativeScreenRecording', [
        {fps: 24},
      ])) as {uuid: string; fps: number; startedAt: number};
      assert.ok(info !== null && typeof info === 'object');
      assert.equal(typeof info.uuid, 'string');
      assert.ok(info.uuid.length > 0);
      assert.equal(info.fps, 24);

      onChunk = (params: ChunkEventParams) => {
        if (params.uuid !== info.uuid) {
          return;
        }
        const decoded = Buffer.from(params.payload, 'base64');
        ownChunks.push(decoded);
        ownBytes += decoded.length;
      };
      bidiEvents.on(CHUNK_EVENT, onChunk);

      await delay(RECORDING_DURATION_MS);

      const payload = (await driver!.executeScript(
        'macos: stopNativeScreenRecording',
        [],
      )) as string;
      assert.equal(typeof payload, 'string');
      assert.ok(payload.length >= MIN_BASE64_PAYLOAD_SIZE);

      // Decoded payload should be a valid mp4 (starts with an `ftyp` box).
      const stopBuffer = Buffer.from(payload, 'base64');
      assert.ok(stopBuffer.length >= 8);
      assert.equal(stopBuffer.subarray(4, 8).toString('ascii'), 'ftyp');

      // The publisher is contractually guaranteed by `notifyStopped` to
      // have emitted every byte of the recording before
      // `stopNativeScreenRecording` returns. We only need to wait for the
      // localhost WebSocket to deliver those frames to this client.
      await waitForCondition(() => ownBytes >= stopBuffer.length, {
        waitMs: BIDI_DELIVERY_TIMEOUT_MS,
        intervalMs: 25,
      });

      assert.ok(ownChunks.length >= 1, 'no BiDi chunks were received');

      const reassembled = Buffer.concat(ownChunks);
      assert.equal(
        reassembled.length,
        stopBuffer.length,
        'BiDi-reassembled video has a different size than the stop payload',
      );
      assert.equal(
        reassembled.equals(stopBuffer),
        true,
        'BiDi-reassembled video does not match the stop payload byte-for-byte',
      );
    } finally {
      if (onChunk) {
        bidiEvents.off(CHUNK_EVENT, onChunk);
      }
    }
  });
});
