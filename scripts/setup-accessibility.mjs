import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

import {logger} from 'appium/support.js';
import {exec} from 'teen_process';

const RUNNER_NAME = 'WebDriverAgentRunner-Runner.app';
const RUNNER_SCHEME = 'WebDriverAgentRunner';
// Keep the build arguments in sync with the driver, so it reuses this build without re-signing it
const DISABLE_STORE_ARG = 'COMPILER_INDEX_STORE_ENABLE=NO';
const XCODEPROJ_NAME = 'WebDriverAgentMac.xcodeproj';
const DERIVED_DATA_ROOT = path.join(os.homedir(), 'Library', 'Developer', 'Xcode', 'DerivedData');
const SETTINGS_URL = 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility';
const NO_OPEN_FLAG = '--no-open';
const RUNNER_PATH_ENV = 'WDA_RUNNER_PATH';
const KEEP_RUNNING_FLAG = '--keep-running';
const RUNNER_EXECUTABLE_FRAGMENT = `/${RUNNER_NAME}/Contents/MacOS/`;

const log = logger.getLogger('WDA');

async function exists(p) {
  try {
    await fs.access(p);
    return true;
  } catch {
    return false;
  }
}

/**
 * Xcode stores the project path of each derived data folder in its info.plist
 */
async function readWorkspacePath(derivedDataDir) {
  try {
    const {stdout} = await exec('plutil', [
      '-extract',
      'WorkspacePath',
      'raw',
      '-o',
      '-',
      path.join(derivedDataDir, 'info.plist'),
    ]);
    return stdout.trim();
  } catch {
    return null;
  }
}

/**
 * Finds the runner app built from the WebDriverAgent project of this driver.
 * The newest one wins if there are many.
 */
async function findRunner(projectPath) {
  let entries;
  try {
    entries = await fs.readdir(DERIVED_DATA_ROOT);
  } catch {
    return null;
  }
  const candidates = [];
  for (const entry of entries.filter((name) => name.startsWith('WebDriverAgentMac-'))) {
    const derivedDataDir = path.join(DERIVED_DATA_ROOT, entry);
    const runnerPath = path.join(derivedDataDir, 'Build', 'Products', 'Debug', RUNNER_NAME);
    if (!(await exists(runnerPath)) || (await readWorkspacePath(derivedDataDir)) !== projectPath) {
      continue;
    }
    candidates.push({runnerPath, mtimeMs: (await fs.stat(runnerPath)).mtimeMs});
  }
  return candidates.sort((a, b) => b.mtimeMs - a.mtimeMs)[0]?.runnerPath ?? null;
}

/**
 * Stops the runner and the xcodebuild process that hosts it. macOS evaluates the permission
 * when a process starts, so a runner started before the grant stays untrusted.
 * Appium itself keeps running, but an active session loses its runner.
 */
async function stopRunningRunners() {
  const {stdout} = await exec('ps', ['-axo', 'pid=,command=']);
  const pids = [];
  for (const line of stdout.split('\n')) {
    const match = line.trim().match(/^(\d+)\s+(.*)$/);
    if (!match) {
      continue;
    }
    const pid = Number(match[1]);
    const command = match[2];
    const isRunner = command.includes(RUNNER_EXECUTABLE_FRAGMENT);
    const isHost =
      /(^|\/)xcodebuild\s/.test(command) &&
      command.includes('test-without-building') &&
      command.includes(`-scheme ${RUNNER_SCHEME}`);
    if ((isRunner || isHost) && pid !== process.pid && pid !== process.ppid) {
      pids.push(pid);
    }
  }
  for (const pid of pids) {
    try {
      process.kill(pid, 'SIGTERM');
    } catch (e) {
      log.warn(`Cannot stop the process ${pid}: ${e.message}`);
    }
  }
  if (pids.length > 0) {
    log.info(`Stopped the running WebDriverAgent processes: ${pids.join(', ')}`);
  }
}

/**
 * Builds the runner the same way the driver does
 */
async function buildRunner(projectPath) {
  log.info(`Building ${RUNNER_NAME}. This may take a few minutes`);
  try {
    await exec(
      'xcodebuild',
      ['build-for-testing', '-project', projectPath, '-scheme', RUNNER_SCHEME, DISABLE_STORE_ARG],
      {cwd: path.dirname(projectPath)},
    );
  } catch (e) {
    const output = String(e.stdout ?? '')
      .trim()
      .split('\n')
      .slice(-20)
      .join('\n');
    throw new Error(`Cannot build ${RUNNER_NAME}: ${e.stderr || e.message}\n${output}`, {cause: e});
  }
}

async function setupAccessibility() {
  const args = process.argv.slice(2);
  const shouldOpen = !args.includes(NO_OPEN_FLAG);
  const shouldStop = !args.includes(KEEP_RUNNING_FLAG);
  const explicitPath = args.find((arg) => !arg.startsWith('--')) ?? process.env[RUNNER_PATH_ENV];

  if (shouldStop) {
    await stopRunningRunners();
  }

  const __dirname = path.dirname(fileURLToPath(import.meta.url));
  const projectPath = path.resolve(__dirname, '..', 'WebDriverAgentMac', XCODEPROJ_NAME);
  let runnerPath = explicitPath ? path.resolve(explicitPath) : await findRunner(projectPath);
  if (!runnerPath && !explicitPath) {
    await buildRunner(projectPath);
    runnerPath = await findRunner(projectPath);
  }
  if (!runnerPath || !(await exists(runnerPath))) {
    log.error(
      `Cannot find ${RUNNER_NAME}${explicitPath ? ` at '${runnerPath}'` : ` built from '${projectPath}'`}. ` +
        `If your Xcode derived data folder is not in '${DERIVED_DATA_ROOT}', ` +
        `set the ${RUNNER_PATH_ENV} environment variable to the full path to ${RUNNER_NAME}.`,
    );
    process.exitCode = 1;
    return;
  }

  log.info(`WebDriverAgent runner: '${runnerPath}'`);
  log.info(
    `Add the runner to System Settings > Privacy & Security > Accessibility and turn it on. ` +
      `Then restart your Appium session. Do not rebuild the runner after granting the permission, ` +
      `because the grant may be tied to the exact build.`,
  );
  if (!shouldOpen) {
    return;
  }
  // Selects the runner in Finder, so it can be dragged into the Accessibility list
  await exec('open', ['-R', runnerPath]);
  await exec('open', [SETTINGS_URL]);
}

setupAccessibility().catch((e) => {
  log.error(e.message);
  process.exitCode = 1;
});
