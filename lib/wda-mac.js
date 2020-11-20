import _ from 'lodash';
import path from 'path';
import { JWProxy, errors } from 'appium-base-driver';
import { fs, logger, util, timing } from 'appium-support';
import { SubProcess, exec } from 'teen_process';
import { waitForCondition } from 'asyncbox';
import { execSync } from 'child_process';

const log = logger.getLogger('WebDriverAgentMac');

const ROOT_DIR = path.basename(__dirname) === 'lib'
  ? path.resolve(__dirname, process.env.NO_PRECOMPILE ? '..' : '../..')
  : __dirname;
const WDA_ROOT = path.resolve(ROOT_DIR, 'WebDriverAgentMac');
const WDA_PROJECT = (wdaRoot = WDA_ROOT) => path.resolve(wdaRoot, 'WebDriverAgentMac.xcodeproj');
const SCRIPTS_ROOT = (wdaRoot = WDA_ROOT) => path.resolve(wdaRoot, 'Scripts');
const BOOTSTRAP_SCRIPT = (wdaRoot = WDA_ROOT) => path.resolve(SCRIPTS_ROOT(wdaRoot), 'bootstrap.sh');
const RUNNER_SCHEME = 'WebDriverAgentRunner';
const DISABLE_STORE_ARG = 'COMPILER_INDEX_STORE_ENABLE=NO';
const XCODEBUILD = 'xcodebuild';
const CARTHAGE = 'carthage';
const CARTHAGE_FRAMEWORKS_ROOT = (wdaRoot = WDA_ROOT) => path.resolve(wdaRoot, 'Carthage');
const STARTUP_TIMEOUT_MS = 120000;
const DEPS_LOAD_TIMEOUT_MS = 120000;
const DEFAULT_SYSTEM_PORT = 10100;


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
  constructor (opts = {}) {
    this.showServerLogs = opts.showServerLogs;
    this.port = opts.systemPort || DEFAULT_SYSTEM_PORT;
    this.bootstrapRoot = opts.bootstrapRoot || WDA_ROOT;
    this.depsLoadTimeoutMs = opts.depsLoadTimeout || DEPS_LOAD_TIMEOUT_MS;
    this.proc = null;
  }

  get isRunning () {
    return !!(this.proc?.isRunning);
  }

  async loadDependencies () {
    if (await fs.exists(CARTHAGE_FRAMEWORKS_ROOT(this.bootstrapRoot))) {
      return false;
    }

    let carthage;
    try {
      carthage = await fs.which(CARTHAGE);
    } catch (e) {
      throw new Error(`${CARTHAGE} binary cannot be found in PATH. ` +
        `Please make sure that Carthage (https://github.com/Carthage/Carthage) is installed on your system`);
    }
    log.debug(`Found ${CARTHAGE} binary at '${carthage}'`);

    const args = [BOOTSTRAP_SCRIPT(this.bootstrapRoot), '-dn'];
    log.info(`Loading dependencies with args: ${util.quote(args)}`);
    log.debug(`Will wait up to ${this.depsLoadTimeoutMs}ms for the process to finish. ` +
      `This timeout could be changed using 'depsLoadTimeout' capability`);
    const timer = new timing.Timer().start();
    await exec('bash', args, {
      cwd: this.bootstrapRoot,
      timeout: this.depsLoadTimeoutMs,
    });
    log.info(`Loaded dependencies within ${timer.getDuration().asMilliSeconds.toFixed(0)}ms`);
    return true;
  }

  async init () {
    if (this.isRunning) {
      return;
    }

    let xcodebuild;
    try {
      xcodebuild = await fs.which(XCODEBUILD);
    } catch (e) {
      throw new Error(`${XCODEBUILD} binary cannot be found in PATH. ` +
        `Please make sure that Xcode is installed on your system`);
    }
    log.debug(`Found ${XCODEBUILD} binary at '${xcodebuild}'`);

    if (await this.loadDependencies()) {
      log.info('Performing project cleanup');
      const args = [
        'clean',
        '-project', WDA_PROJECT(this.bootstrapRoot),
        '-scheme', RUNNER_SCHEME,
      ];
      await exec(XCODEBUILD, args, {
        cwd: this.bootstrapRoot,
      });
    }

    const args = [
      'build-for-testing', 'test-without-building',
      '-project', WDA_PROJECT(this.bootstrapRoot),
      '-scheme', RUNNER_SCHEME,
      DISABLE_STORE_ARG,
    ];
    const env = Object.assign({}, process.env);
    if (this.port) {
      log.debug(`Using port ${this.port}`);
      env.USE_PORT = `${this.port}`;
    }
    log.debug(`Bootstrap root: ${this.bootstrapRoot}`);
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
  }

  async stop () {
    if (this.isRunning) {
      await this.proc.stop('SIGTERM');
    }
  }

  async kill () {
    if (this.isRunning) {
      try {
        await this.proc.stop('SIGKILL');
      } catch (ign) {}
    }
  }
}

const RUNNING_PROCESS_IDS = [];
process.once('exit', () => {
  for (const pid of RUNNING_PROCESS_IDS) {
    try {
      execSync(`kill ${pid}`);
    } catch (ign) {}
  }
});

class WDAMacServer {
  constructor (caps) {
    this.process = new WDAMacProcess(caps);
    this.serverStartupTimeoutMs = caps.serverStartupTimeout || STARTUP_TIMEOUT_MS;
    this.proxy = null;
  }

  get isRunning () {
    return !!(this.process?.isRunning);
  }

  async start (wdaCaps) {
    await this.process.init();

    this.proxy = new WDAMacProxy({
      server: '127.0.0.1',
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
      await waitForCondition(async () => {
        try {
          await this.proxy.command('/status', 'GET');
          return true;
        } catch (err) {
          if (this.proxy.didProcessExit) {
            throw new Error(err.message);
          }
          return false;
        }
      }, {
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
          `and make sure the xcodebuild host process could be started manually from a terminal`);
      }
      throw e;
    }
    const pid = this.process.proc.pid;
    RUNNING_PROCESS_IDS.push(pid);
    this.process.proc.on('exit', () => void _.pull(RUNNING_PROCESS_IDS, pid));
    log.info(`The host process has started within ${timer.getDuration().asMilliSeconds.toFixed(0)}ms`);

    await this.proxy.command('/session', 'POST', {
      capabilities: {
        firstMatch: [{}],
        alwaysMatch: wdaCaps,
      }
    });
  }

  async stop () {
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

    try {
      await this.process.stop();
    } catch (e) {
      log.warn(`Mac2Driver process cannot be stopped (${e.message}). Killing it forcefully`);
      await this.process.kill();
    }
  }
}

export default WDAMacServer;
