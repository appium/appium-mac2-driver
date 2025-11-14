import {doctor} from 'appium/support';
import {exec} from 'teen_process';
import { getPath as getXcodePath } from 'appium-xcode';
import type {IDoctorCheck, AppiumLogger, DoctorCheckResult} from '@appium/types';
import '@colors/colors';


export class XcodeCheck implements IDoctorCheck {
  log!: AppiumLogger;

  async diagnose(): Promise<DoctorCheckResult> {
    try {
      const xcodePath = await getXcodePath();
      return doctor.ok(`xCode is installed at '${xcodePath}'`);
    } catch (err) {
      return doctor.nok((err as Error).message);
    }
  }

  async fix(): Promise<string> {
    return `Manually install ${'Xcode'.bold} and configure the active developer directory path using the xcode-select tool`;
  }

  hasAutofix(): boolean {
    return false;
  }

  isOptional(): boolean {
    return false;
  }
}
export const xcodeCheck = new XcodeCheck();


export class XcodebuildCheck implements IDoctorCheck {
  log!: AppiumLogger;
  static readonly XCODE_VER_PATTERN = /^Xcode\s+([\d.]+)$/m;
  static readonly MIN_XCODE_VERSION = 13;

  async diagnose(): Promise<DoctorCheckResult> {
    let xcodeVerMatch: RegExpExecArray | null;
    let stdout: string;
    let stderr: string;
    try {
      ({stdout, stderr} = await exec('xcodebuild', ['-version']));
      xcodeVerMatch = XcodebuildCheck.XCODE_VER_PATTERN.exec(stdout);
    } catch (err) {
      return doctor.nok(`Cannot run 'xcodebuild': ${(err as any).stderr || (err as Error).message}`);
    }
    if (!xcodeVerMatch) {
      return doctor.nok(`Cannot determine Xcode version. stdout: ${stdout}; stderr: ${stderr}`);
    }
    const xcodeMajorVer = parseInt(xcodeVerMatch[1], 10);
    if (xcodeMajorVer < XcodebuildCheck.MIN_XCODE_VERSION) {
      return doctor.nok(`The actual Xcode version (${xcodeVerMatch[0]}) is older than the expected ` +
        `one (${XcodebuildCheck.MIN_XCODE_VERSION})`);
    }
    return doctor.ok(`xcodebuild is installed and has a matching version number ` +
      `(${xcodeVerMatch[1]} >= ${XcodebuildCheck.MIN_XCODE_VERSION})`);
  }

  async fix(): Promise<string> {
    return `Install ${'Xcode'.bold} ${XcodebuildCheck.MIN_XCODE_VERSION}+ or upgrade the existing setup`;
  }

  hasAutofix(): boolean {
    return false;
  }

  isOptional(): boolean {
    return false;
  }
}
export const xcodebuildCheck = new XcodebuildCheck();

