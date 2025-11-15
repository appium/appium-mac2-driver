import {resolveExecutablePath} from './utils';
import {doctor} from 'appium/support';
import {exec} from 'teen_process';
import type {IDoctorCheck, AppiumLogger, DoctorCheckResult} from '@appium/types';
import '@colors/colors';

export class OptionalFfmpegCheck implements IDoctorCheck {
  log!: AppiumLogger;
  static readonly FFMPEG_BINARY = 'ffmpeg';
  static readonly FFMPEG_INSTALL_LINK = 'https://www.ffmpeg.org/download.html';

  async diagnose(): Promise<DoctorCheckResult> {
    const ffmpegPath = await resolveExecutablePath(OptionalFfmpegCheck.FFMPEG_BINARY);

    return ffmpegPath
      ? doctor.okOptional(`${OptionalFfmpegCheck.FFMPEG_BINARY} exists at '${ffmpegPath}'`)
      : doctor.nokOptional(`${OptionalFfmpegCheck.FFMPEG_BINARY} cannot be found`);
  }

  async fix(): Promise<string> {
    return (
      `${`${OptionalFfmpegCheck.FFMPEG_BINARY}`.bold} is used to capture screen recordings. ` +
      `Please read ${OptionalFfmpegCheck.FFMPEG_INSTALL_LINK}.`
    );
  }

  hasAutofix(): boolean {
    return false;
  }

  isOptional(): boolean {
    return true;
  }
}
export const optionalFfmpegCheck = new OptionalFfmpegCheck();


export class OptionalAutomationModeCheck implements IDoctorCheck {
  log!: AppiumLogger;

  async diagnose(): Promise<DoctorCheckResult> {
    let stdout: string;
    try {
      ({stdout} = await exec('automationmodetool'));
    } catch (err) {
      return doctor.nokOptional(`Cannot run 'automationmodetool': ${(err as any).stderr || (err as Error).message}`);
    }
    if (stdout.includes('DOES NOT REQUIRE')) {
      return doctor.okOptional(`Automation Mode does not require user authentication`);
    }
    return doctor.nokOptional(`Automation Mode requires user authentication`);
  }

  async fix(): Promise<string> {
    return `Run \`automationmodetool enable-automationmode-without-authentication\` to disable Automation Mode authentication`;
  }

  hasAutofix(): boolean {
    return false;
  }

  isOptional(): boolean {
    return true;
  }
}
export const optionalAutomationModeCheck = new OptionalAutomationModeCheck();

