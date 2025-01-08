import {doctor} from 'appium/support';
import {exec} from 'teen_process';
import { getPath as getXcodePath } from 'appium-xcode';
import '@colors/colors';


/** @satisfies {import('@appium/types').IDoctorCheck} */
export class XcodeCheck {
  async diagnose() {
    try {
      const xcodePath = await getXcodePath();
      return doctor.ok(`xCode is installed at '${xcodePath}'`);
    } catch (err) {
      return doctor.nok(err.message);
    }
  }

  async fix() {
    return `Manually install ${'Xcode'.bold} and configure the active developer directory path using the xcode-select tool`;
  }

  hasAutofix() {
    return false;
  }

  isOptional() {
    return false;
  }
}
export const xcodeCheck = new XcodeCheck();


/** @satisfies {import('@appium/types').IDoctorCheck} */
export class XcodebuildCheck {
  XCODE_VER_PATTERN = /^Xcode\s+([\d.]+)$/m;
  MIN_XCODE_VERSION = 13;

  async diagnose() {
    let xcodeVerMatch;
    let stdout;
    let stderr;
    try {
      ({stdout, stderr} = await exec('xcodebuild', ['-version']));
      xcodeVerMatch = this.XCODE_VER_PATTERN.exec(stdout);
    } catch (err) {
      return doctor.nok(`Cannot run 'xcodebuild': ${err.stderr || err.message}`);
    }
    if (!xcodeVerMatch) {
      return doctor.nok(`Cannot determine Xcode version. stdout: ${stdout}; stderr: ${stderr}`);
    }
    const xcodeMajorVer = parseInt(xcodeVerMatch[1], 10);
    if (xcodeMajorVer < this.MIN_XCODE_VERSION) {
      return doctor.nok(`The actual Xcode version (${xcodeVerMatch[0]}) is older than the expected ` +
        `one (${this.MIN_XCODE_VERSION})`);
    }
    return doctor.ok(`xcodebuild is installed and has a matching version number ` +
      `(${xcodeVerMatch[1]} >= ${this.MIN_XCODE_VERSION})`);
  }

  async fix() {
    return `Install ${'Xcode'.bold} ${this.MIN_XCODE_VERSION}+ or upgrade the existing setup`;
  }

  hasAutofix() {
    return false;
  }

  isOptional() {
    return false;
  }
}
export const xcodebuildCheck = new XcodebuildCheck();
