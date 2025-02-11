import type { NativeVideoChunkAddedEvent } from './types';
import { NATIVE_VIDEO_CHUNK_ADDED_EVENT } from './constants';

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
