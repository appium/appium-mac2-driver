import path from 'node:path';
import os from 'node:os';
import {resolveExecutablePath} from './utils';
import {doctor, fs, util} from 'appium/support';
import {exec} from 'teen_process';
import type {IDoctorCheck, AppiumLogger, DoctorCheckResult} from '@appium/types';
import '@colors/colors';

export class OptionalFfmpegCheck implements IDoctorCheck {
  static readonly FFMPEG_BINARY = 'ffmpeg';
  static readonly FFMPEG_INSTALL_LINK = 'https://www.ffmpeg.org/download.html';

  log!: AppiumLogger;

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
      return doctor.nokOptional(
        `Cannot run 'automationmodetool': ${(err as any).stderr || (err as Error).message}`,
      );
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

export class OptionalFullDiskAccessDaemonContainersCheck implements IDoctorCheck {
  /**
   * Upper-case UUID basename only (native recording attachment filenames). Expressed as a glob
   * pattern because `fs.glob` does not accept arbitrary RegExps.
   */
  private static readonly NATIVE_RECORDING_ATTACHMENT_GLOB = (() => {
    const h = '[0-9A-F]';
    const seg = (n: number) => Array.from({length: n}, () => h).join('');
    return `*/Data/Attachments/${seg(8)}-${seg(4)}-${seg(4)}-${seg(4)}-${seg(12)}`;
  })();
  log!: AppiumLogger;
  private readonly ANY_ATTACHMENT_GLOB = '*/Data/Attachments/*';
  private readonly DAEMON_CONTAINERS_ROOT = path.resolve(
    os.homedir(),
    'Library',
    'Daemon Containers',
  );

  async diagnose(): Promise<DoctorCheckResult> {
    const nonDarwin = this.checkIfNotDarwin();
    if (nonDarwin) {
      return nonDarwin;
    }
    const accessBlocked = await this.tryAccessDaemonContainers();
    if (accessBlocked) {
      return accessBlocked;
    }
    const uuidPathsOrErr = await this.globAttachmentsOrError();
    if (!Array.isArray(uuidPathsOrErr)) {
      return uuidPathsOrErr;
    }
    if (uuidPathsOrErr.length === 0) {
      return await this.okWhenNoUuidAttachmentMatches();
    }
    return doctor.okOptional(
      `This process can read "${this.DAEMON_CONTAINERS_ROOT}" ` +
        `and found ${util.pluralize('matching path', uuidPathsOrErr.length, true)} under ` +
        `${this.DAEMON_CONTAINERS_ROOT}/*/Data/Attachments/*.`,
    );
  }

  async fix(): Promise<string> {
    return (
      `Open ${'System Settings'.bold} → ${'Privacy & Security'.bold} → ${'Full Disk Access'.bold} ` +
      `and enable the Terminal, IDE, or launchd parent that starts Appium Server. ` +
      `Native screen recordings are stored in ${this.DAEMON_CONTAINERS_ROOT}/*/Data/Attachments/<recording_uuid>. ` +
      `This permission is required to retrieve screen recording videos captured natively by the XCTest daemon via ` +
      `'macos: (start/stop)NativeScreenRecording' APIs.`
    );
  }

  hasAutofix(): boolean {
    return false;
  }

  isOptional(): boolean {
    return true;
  }

  private checkIfNotDarwin(): DoctorCheckResult | null {
    if (process.platform === 'darwin') {
      return null;
    }
    return doctor.okOptional(
      `Full Disk Access to ~/Library/Daemon Containers can only be checked on macOS`,
    );
  }

  private async tryAccessDaemonContainers(): Promise<DoctorCheckResult | null> {
    try {
      await fs.access(this.DAEMON_CONTAINERS_ROOT);
      return null;
    } catch (e) {
      return doctor.nokOptional(
        `Cannot access "${this.DAEMON_CONTAINERS_ROOT}": ${(e as Error).message}`,
      );
    }
  }

  private async globAttachmentsOrError(): Promise<string[] | DoctorCheckResult> {
    try {
      return await fs.glob(
        OptionalFullDiskAccessDaemonContainersCheck.NATIVE_RECORDING_ATTACHMENT_GLOB,
        {
          cwd: this.DAEMON_CONTAINERS_ROOT,
          absolute: true,
        },
      );
    } catch (e) {
      return doctor.nokOptional(
        `Cannot enumerate native recording attachments under "${this.DAEMON_CONTAINERS_ROOT}": ${(e as Error).message}`,
      );
    }
  }

  private async globAnyAttachmentsBestEffort(): Promise<string[]> {
    try {
      return await fs.glob(this.ANY_ATTACHMENT_GLOB, {
        cwd: this.DAEMON_CONTAINERS_ROOT,
        absolute: true,
      });
    } catch {
      return [];
    }
  }

  private async okWhenNoUuidAttachmentMatches(): Promise<DoctorCheckResult> {
    const anyAttachmentPaths = await this.globAnyAttachmentsBestEffort();
    return doctor.okOptional(
      anyAttachmentPaths.length > 0
        ? `This process can read "${this.DAEMON_CONTAINERS_ROOT}" ` +
            `(found ${util.pluralize('path', anyAttachmentPaths.length, true)} under ` +
            `*/Data/Attachments/*, none matched the upper-case UUID filename glob).`
        : `This process can read "${this.DAEMON_CONTAINERS_ROOT}" ` +
            `(no files under */Data/Attachments/* yet).`,
    );
  }
}
export const optionalFullDiskAccessDaemonContainersCheck =
  new OptionalFullDiskAccessDaemonContainersCheck();
