import _ from 'lodash';
import path from 'path';
import { JWProxy, errors } from 'appium-base-driver';
import { fs, logger, util, timing, mkdirp } from 'appium-support';
import { SubProcess, exec } from 'teen_process';
import { waitForCondition } from 'asyncbox';
import { checkPortStatus } from 'portscanner';
import { execSync } from 'child_process';
import { listChildrenProcessIds } from './utils';

const log = logger.getLogger('WebDriverAgentMac');

const HOST = '127.0.0.1';
const ROOT_DIR = path.basename(__dirname) === 'lib'
  ? path.resolve(__dirname, process.env.NO_PRECOMPILE ? '..' : '../..')
  : __dirname;
const WDA_ROOT = path.resolve(ROOT_DIR, 'WebDriverAgentMac');
const WDA_PROJECT_NAME = 'WebDriverAgentMac.xcodeproj';
const WDA_PROJECT = (wdaRoot = WDA_ROOT) => path.resolve(wdaRoot, WDA_PROJECT_NAME);
const RUNNER_SCHEME = 'WebDriverAgentRunner';
const DISABLE_STORE_ARG = 'COMPILER_INDEX_STORE_ENABLE=NO';
const XCODEBUILD = 'xcodebuild';
const STARTUP_TIMEOUT_MS = 120000;
const DEFAULT_SYSTEM_PORT = 10100;
const RUNNING_PROCESS_IDS = [];
const RECENT_UPGRADE_TIMESTAMP_PATH = path.join('.appium',
  'webdriveragent_mac', 'upgrade.time');


async function getUpgradeTimestamp () {
  const packageManifest = path.resolve(ROOT_DIR, 'package.json');
  if (!await fs.exists(packageManifest)) {
    return null;
  }
  const {mtime} = await fs.stat(packageManifest);
  return mtime.getTime();
}

async function cleanupObsoleteProcesses () {
  if (!_.isEmpty(RUNNING_PROCESS_IDS)) {
    log.debug(`Cleaning up ${RUNNING_PROCESS_IDS.length} obsolete ` +
      util.pluralize('process', RUNNING_PROCESS_IDS.length, false));
    try {
      await exec('kill', ['-9', ...RUNNING_PROCESS_IDS]);
    } catch (ign) {}
    _.pullAll(RUNNING_PROCESS_IDS, RUNNING_PROCESS_IDS);
  }
}

process.once('exit', () => {
  if (!_.isEmpty(RUNNING_PROCESS_IDS)) {
    try {
      execSync(`kill -9 ${RUNNING_PROCESS_IDS.join(' ')}`);
    } catch (ign) {}
    _.pullAll(RUNNING_PROCESS_IDS, RUNNING_PROCESS_IDS);
  }
});


class WDAMacProxy extends JWProxy {
  async proxyCommand (url, method, body = null) {
    if (this.didProcessExit) {
      throw new errors.InvalidContextError(
        `'${method} ${url}' cannot be proxied to Mac2 Driver server because ` +
        'its process is not running (probably crashed). Check the Appium log for more details');
    }
    return await super.proxyCommand(url, method, body);
  }
}

class WDAMacProcess {
  constructor () {
    this.showServerLogs = false;
    this.port = DEFAULT_SYSTEM_PORT;
    this.bootstrapRoot = WDA_ROOT;
    this.proc = null;
  }

  get isRunning () {
    return !!(this.proc?.isRunning);
  }

  get pid () {
    return this.isRunning ? this.proc.pid : null;
  }

  async listChildrenPids () {
    return this.pid ? (await listChildrenProcessIds(this.pid)) : [];
  }

  async isFreshUpgrade () {
    const homeFolder = process.env.HOME;
    if (!homeFolder) {
      log.info('The HOME folder path cannot be determined');
      return false;
    }

    const currentUpgradeTimestamp = await getUpgradeTimestamp();
    if (!_.isInteger(currentUpgradeTimestamp)) {
      log.info('It is impossible to determine the timestamp of the package');
      return false;
    }

    const timestampPath = path.resolve(homeFolder, RECENT_UPGRADE_TIMESTAMP_PATH);
    if (await fs.exists(timestampPath)) {
      try {
        await fs.access(timestampPath, fs.W_OK);
      } catch (ign) {
        log.info(`WebDriverAgent upgrade timestamp at '${timestampPath}' is not writeable`);
        return false;
      }
      const recentUpgradeTimestamp = parseInt(await fs.readFile(timestampPath, 'utf8'), 10);
      if (_.isInteger(recentUpgradeTimestamp)) {
        if (recentUpgradeTimestamp >= currentUpgradeTimestamp) {
          log.info(`WebDriverAgent sources are up to date ` +
            `(${recentUpgradeTimestamp} >= ${currentUpgradeTimestamp})`);
          return false;
        }
        log.info(`WebDriverAgent sources have been upgraded ` +
          `(${recentUpgradeTimestamp} < ${currentUpgradeTimestamp})`);
      } else {
        log.warn(`The recent upgrade timestamp at '${timestampPath}' is corrupted. Trying to fix it`);
      }
    }

    try {
      await mkdirp(path.dirname(timestampPath));
      await fs.writeFile(timestampPath, `${currentUpgradeTimestamp}`, 'utf8');
      log.debug(`Stored the recent WebDriverAgent upgrade timestamp ${currentUpgradeTimestamp} ` +
        `at '${timestampPath}'`);
    } catch (e) {
      log.info(`Unable to create the recent WebDriverAgent upgrade timestamp at '${timestampPath}'. ` +
        `Original error: ${e.message}`);
      return false;
    }

    return true;
  }

  async init (opts = {}) {
    if (this.isRunning) {
      return false;
    }

    this.showServerLogs = opts.showServerLogs ?? this.showServerLogs;
    this.port = opts.systemPort ?? this.port;
    this.bootstrapRoot = opts.bootstrapRoot ?? this.bootstrapRoot;

    log.debug(`Using bootstrap root: ${this.bootstrapRoot}`);
    if (!await fs.exists(WDA_PROJECT(this.bootstrapRoot))) {
      throw new Error(`${WDA_PROJECT_NAME} does not exist at '${WDA_PROJECT(this.bootstrapRoot)}'. ` +
        `Was 'bootstrapRoot' set to a proper value?`);
    }

    await cleanupObsoleteProcesses();

    let xcodebuild;
    try {
      xcodebuild = await fs.which(XCODEBUILD);
    } catch (e) {
      throw new Error(`${XCODEBUILD} binary cannot be found in PATH. ` +
        `Please make sure that Xcode is installed on your system`);
    }
    log.debug(`Using ${XCODEBUILD} binary at '${xcodebuild}'`);

    if (await this.isFreshUpgrade()) {
      log.info('Performing project cleanup');
      const args = [
        'clean',
        '-project', WDA_PROJECT(this.bootstrapRoot),
        '-scheme', RUNNER_SCHEME,
      ];
      try {
        await exec(XCODEBUILD, args, {
          cwd: this.bootstrapRoot,
        });
      } catch (e) {
        log.warn(`Cannot perform project cleanup. ` +
          `Original error: ${e.stderr || e.message}`);
      }
    }

    log.debug(`Using port ${this.port}`);
    const isPortBusy = (await checkPortStatus(this.port, HOST)) === 'open';
    if (isPortBusy) {
      throw new Error(`The port #${this.port} is busy. ` +
        `Consider setting 'systemPort' capability to another free port number and/or ` +
        `make sure the previous driver session(s) have been closed properly.`);
    }

    const args = [
      'build-for-testing', 'test-without-building',
      '-project', WDA_PROJECT(this.bootstrapRoot),
      '-scheme', RUNNER_SCHEME,
      DISABLE_STORE_ARG,
    ];
    const env = Object.assign({}, process.env, {
      USE_PORT: `${this.port}`,
    });
    this.proc = new SubProcess(xcodebuild, args, {
      cwd: this.bootstrapRoot,
      env,
    });
    if (!this.showServerLogs) {
      log.info(`Mac2Driver host process logging is disabled. ` +
        `All the ${XCODEBUILD} output is going to be suppressed. ` +
        `Set the 'showServerLogs' capability to 'true' if this is an undesired behavior`);
    }
    this.proc.on('output', (stdout, stderr) => {
      if (!this.showServerLogs) {
        return;
      }

      const line = _.trim(stdout || stderr);
      if (line) {
        log.debug(`[${XCODEBUILD}] ${line}`);
      }
    });
    this.proc.on('exit', (code, signal) => {
      log.info(`Mac2Driver host process has exited with code ${code}, signal ${signal}`);
    });
    log.info(`Starting Mac2Driver host process: ${XCODEBUILD} ${util.quote(args)}`);
    await this.proc.start(0);
    return true;
  }

  async stop () {
    if (this.isRunning) {
      const childrenPids = await this.listChildrenPids();
      if (!_.isEmpty(childrenPids)) {
        try {
          await exec('kill', childrenPids);
        } catch (ign) {}
      }
      await this.proc.stop('SIGTERM', 3000);
    }
  }

  async kill () {
    if (this.isRunning) {
      const childrenPids = await this.listChildrenPids();
      if (!_.isEmpty(childrenPids)) {
        try {
          await exec('kill', ['-9', ...childrenPids]);
        } catch (ign) {}
      }
      try {
        await this.proc.stop('SIGKILL');
      } catch (ign) {}
    }
  }
}

class WDAMacServer {
  constructor () {
    this.process = new WDAMacProcess();
    this.serverStartupTimeoutMs = STARTUP_TIMEOUT_MS;
    this.proxy = null;
  }

  get isRunning () {
    return !!(this.process?.isRunning);
  }

  async isProxyReady (throwOnExit = true) {
    if (!this.proxy) {
      return false;
    }

    try {
      await this.proxy.command('/status', 'GET');
      return true;
    } catch (err) {
      if (throwOnExit && this.proxy.didProcessExit) {
        throw new Error(err.message);
      }
      return false;
    }
  }

  async startSession (caps) {
    this.serverStartupTimeoutMs = caps.serverStartupTimeout ?? this.serverStartupTimeoutMs;
    const wasProcessInitNecessary = await this.process.init(caps);

    if (wasProcessInitNecessary || !(await this.isProxyReady(false))) {
      this.proxy = new WDAMacProxy({
        server: HOST,
        port: this.process.port,
        base: '',
        keepAlive: true,
      });
      this.proxy.didProcessExit = false;
      this.process.proc.on('exit', () => {
        this.proxy.didProcessExit = true;
      });

      const timer = new timing.Timer().start();
      try {
        await waitForCondition(async () => await this.isProxyReady(), {
          waitMs: this.serverStartupTimeoutMs,
          intervalMs: 1000,
        });
      } catch (e) {
        if (this.process.isRunning) {
          // avoid "frozen" processes,
          await this.process.kill();
        }
        if (/Condition unmet/.test(e.message)) {
          throw new Error(`Mac2Driver server is not listening within ${this.serverStartupTimeoutMs}ms timeout. ` +
            `Try to increase the value of 'serverStartupTimeout' capability, check the server logs ` +
            `and make sure the ${XCODEBUILD} host process could be started manually from a terminal`);
        }
        throw e;
      }
      const pid = this.process.pid;
      const childrenPids = await this.process.listChildrenPids();
      RUNNING_PROCESS_IDS.push(...childrenPids, pid);
      this.process.proc.on('exit', () => void _.pull(RUNNING_PROCESS_IDS, pid));
      log.info(`The host process is ready within ${timer.getDuration().asMilliSeconds.toFixed(0)}ms`);
    } else {
      log.info('The host process has already been listening. Proceeding with session creation');
    }

    await this.proxy.command('/session', 'POST', {
      capabilities: {
        firstMatch: [{}],
        alwaysMatch: caps,
      }
    });
  }

  async stopSession () {
    if (!this.isRunning) {
      log.info(`Mac2Driver session cannot be stopped, because the server is not running`);
      return;
    }

    if (this.proxy?.sessionId) {
      try {
        await this.proxy.command(`/session/${this.proxy.sessionId}`, 'DELETE');
      } catch (e) {
        log.info(`Mac2Driver session cannot be deleted. Original error: ${e.message}`);
      }
    }
  }
}

const WDA_MAC_SERVER = new WDAMacServer();

export default WDA_MAC_SERVER;
