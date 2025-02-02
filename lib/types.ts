import type { StringRecord } from '@appium/types';

export interface LaunchAppOptions {
  /**
   * Bundle identifier of the app to be launched
   * or activated. Either this property or `path` must be provided
   */
  bundleId?: string;
  /**
   * Full path to the app bundle. Either this property
   * or `bundleId` must be provided
   */
  path?: string;
  /**
   * The list of command line arguments
   * for the app to be be launched with. This parameter is ignored if the app
   * is already running.
   */
  arguments?: string[];
  /**
   * Environment variables mapping. Custom
   * variables are added to the default process environment.
   */
  environment?: StringRecord;
}

export interface ActivateAppOptions {
  /**
   * Bundle identifier of the app to be activated.
   * Either this property or `path` must be provided
   */
  bundleId?: string;
  /**
   * Full path to the app bundle. Either this property
   * or `bundleId` must be provided
   */
  path?: string;
}

export interface TerminateAppOptions {
  /**
   * Bundle identifier of the app to be terminated.
   * Either this property or `path` must be provided
   */
  bundleId?: string;
  /**
   * Full path to the app bundle. Either this property
   * or `bundleId` must be provided
   */
  path?: string;
}

export interface QueryAppStateOptions {
  /**
   * Bundle identifier of the app whose state should be queried.
   * Either this property or `path` must be provided
   */
  bundleId?: string;
  /**
   * Full path to the app bundle. Either this property
   * or `bundleId` must be provided
   */
  path?: string;
}

export interface ExecAppleScriptOptions {
  /**
   * A valid AppleScript to execute
   */
  script?: string;
  /**
   * Overrides the scripting language. Basically, sets the value of `-l` command
   * line argument of `osascript` tool. If unset the AppleScript language is assumed.
   */
  language?: string;
  /**
   * A valid AppleScript as a single command (no line breaks) to execute
   */
  command?: string;
  /**
   * [20000] The number of seconds to wait until a long-running command is
   * finished. An error is thrown if the command is still running after this timeout expires.
   */
  timeout?: number;
  /**
   * The path to an existing folder, which is going to be set as the
   * working directory for the command/script being executed.
   */
  cwd?: string;
}

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

export interface DeepLinkOptions {
  /** The URL to be opened. This parameter is manadatory. */
  url: string;
  /**
   * The bundle identifier of an application to open the given url with.
   * If not provided then the default application for the given url scheme is going to be used.
   */
  bundleId?: string;
}

export interface StopRecordingOptions {
  /**
   * The path to the remote location, where the resulting video should be uploaded.
   * The following protocols are supported: http/https, ftp.
   * Null or empty string value (the default setting) means the content of resulting
   * file should be encoded as Base64 and passed as the endpoint response value.
   * An exception will be thrown if the generated media file is too big to
   * fit into the available process memory.
   */
  remotePath?: string;
  /**
   * The name of the user for the remote authentication.
   */
  user?: string;
  /**
   * The password for the remote authentication.
   */
  pass?: string;
  /**
   * The http multipart upload method name. The 'PUT' one is used by default.
   */
  method?: string;
  /**
   * Additional headers mapping for multipart http(s) uploads
   */
  headers?: StringRecord | [string, any][];
  /**
   * [file] The name of the form field, where the file content BLOB should be stored for
   *  http(s) uploads
   */
  fileFieldName?: string;
  /**
   * Additional form fields for multipart http(s) uploads
   */
  formFields?: StringRecord | [string, string][];
}

export interface StartRecordingOptions {
  /**
   * The video filter spec to apply for ffmpeg.
   * See https://trac.ffmpeg.org/wiki/FilteringGuide for more details on the possible values.
   * Example: Set it to `scale=ifnot(gte(iw\,1024)\,iw\,1024):-2` in order to limit the video width
   * to 1024px. The height will be adjusted automatically to match the actual ratio.
   */
  videoFilter?: string;
  /**
   * The count of frames per second in the resulting video.
   * The greater fps it has the bigger file size is. 15 by default.
   */
  fps?: number | string;
  /**
   * One of the supported encoding presets. A preset is a collection of options that will provide a
   * certain encoding speed to compression ratio.
   * A slower preset will provide better compression (compression is quality per filesize).
   * This means that, for example, if you target a certain file size or constant bit rate, you will achieve better
   * quality with a slower preset. Read https://trac.ffmpeg.org/wiki/Encode/H.264 for more details.
   * `veryfast` by default
   */
  preset?: 'ultrafast'|'superfast'|'veryfast'|'faster'|'fast'|'medium'|'slow'|'slower'|'veryslow';
  /**
   * Whether to capture the mouse cursor while recording
   * the screen. false by default
   */
  captureCursor?: boolean;
  /**
   * Whether to capture mouse clicks while recording the
   * screen. False by default.
   */
  captureClicks?: boolean;
  /**
   * Screen device index to use for the recording.
   * The list of available devices could be retrieved using
   * `ffmpeg -f avfoundation -list_devices true -i` command.
   */
  deviceId: string | number;
  /**
   * The maximum recording time, in seconds. The default
   * value is 600 seconds (10 minutes).
   */
  timeLimit?: string | number;
  /**
   * Whether to ignore the call if a screen recording is currently running
   * (`false`) or to start a new recording immediately and terminate the existing one if running (`true`).
   * The default value is `true`.
   */
  forceRestart?: boolean;
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

export interface ScreenshotsOpts {
  /**
   * macOS display identifier to take a screenshot for.
   * If not provided then screenshots of all displays are going to be returned.
   * If no matches were found then an error is thrown.
   */
  displayId?: number;
}
