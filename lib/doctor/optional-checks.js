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
    if (stdout.includes('DOES NOT REQUIRE')) {
      return doctor.okOptional(`Automation Mode does not require user authentication`);
    }
    return doctor.nokOptional(`Automation Mode requires user authentication`);
  }

  async fix() {
    return `Run \`automationmodetool enable-automationmode-without-authentication\` to disable Automation Mode authentication`;
  }

  hasAutofix() {
    return false;
  }

  isOptional() {
    return true;
  }
}
export const optionalAutomationModeCheck = new OptionalAutomationModeCheck();
