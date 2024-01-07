/* eslint-disable require-await */
import {resolveExecutablePath} from './utils';
import {doctor} from 'appium/support';
import {exec} from 'teen_process';
import '@colors/colors';

/** @satisfies {import('@appium/types').IDoctorCheck} */
export class OptionalFfmpegCheck {
  FFMPEG_BINARY = 'ffmpeg';
  FFMPEG_INSTALL_LINK = 'https://www.ffmpeg.org/download.html';

  async diagnose() {
    const ffmpegPath = await resolveExecutablePath(this.FFMPEG_BINARY);

    return ffmpegPath
      ? doctor.okOptional(`${this.FFMPEG_BINARY} exists at '${ffmpegPath}'`)
      : doctor.nokOptional(`${this.FFMPEG_BINARY} cannot be found`);
  }

  async fix() {
    return (
      `${`${this.FFMPEG_BINARY}`.bold} is used to capture screen recordings. ` +
      `Please read ${this.FFMPEG_INSTALL_LINK}.`
    );
  }

  hasAutofix() {
    return false;
  }

  isOptional() {
    return true;
  }
}
export const optionalFfmpegCheck = new OptionalFfmpegCheck();


/** @satisfies {import('@appium/types').IDoctorCheck} */
export class OptionalAutomationModeCheck {
  async diagnose() {
    let stdout;
    try {
      ({stdout} = await exec('automationmodetool'));
    } catch (err) {
      return doctor.nokOptional(`Cannot run 'automationmodetool': ${err.stderr || err.message}`);
    }
    if (stdout.includes('disabled')) {
      return doctor.nokOptional(`Automation Mode is disabled`);
    }
    return doctor.okOptional(`Automation Mode is enabled`);
  }

  async fix() {
    return `Run \`automationmodetool enable-automationmode-without-authentication\` to enable Automation Mode`;
  }

  hasAutofix() {
    return false;
  }

  isOptional() {
    return true;
  }
}
export const optionalAutomationModeCheck = new OptionalAutomationModeCheck();
