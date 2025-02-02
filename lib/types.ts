import type { StringRecord } from '@appium/types';

export interface KeyOptions {
  /**
   * A string, that represents a key to type (see
   * https://developer.apple.com/documentation/xctest/xcuielement/1500604-typekey?language=objc
   * and https://developer.apple.com/documentation/xctest/xcuikeyboardkey?language=objc)
   */
  key: string;
  /**
   * A set of modifier flags
   * (https://developer.apple.com/documentation/xctest/xcuikeymodifierflags?language=objc)
   * to use when typing the key.
   */
  modifierFlags?: number;
}

export interface ScreenshotInfo {
  /** Display identifier */
  id: number;
  /** Whether this display is the main one */
  isMain: boolean;
  /** The actual PNG screenshot data encoded to base64 string */
  payload: string;
}

/** A dictionary where each key contains a unique display identifier */
export type ScreenshotsInfo = StringRecord<ScreenshotInfo>;
