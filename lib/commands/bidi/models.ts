import type {NativeVideoChunkAddedEvent} from './types';
import {NATIVE_VIDEO_CHUNK_ADDED_EVENT} from './constants';

/**
 * Converts the given UUID and video chunk payload into a NativeVideoChunkAddedEvent object.
 * @param uuid The unique identifier for the video chunk.
 * @param payload The video chunk data as a Buffer.
 * @returns A NativeVideoChunkAddedEvent object containing the UUID and encoded video chunk.
 */
export function toNativeVideoChunkAddedEvent(
  uuid: string,
  payload: Buffer,
): NativeVideoChunkAddedEvent {
  return {
    method: NATIVE_VIDEO_CHUNK_ADDED_EVENT,
    params: {
      uuid,
      payload: payload.toString('base64'),
    },
  };
}
