import _ from 'lodash';
import path from 'path';
import url from 'url';
import axios from 'axios';
import B from 'bluebird';
import { JWProxy, errors } from 'appium/driver';
import { fs, logger, util, timing } from 'appium/support';
import { strongbox } from '@appium/strongbox';
import { SubProcess, exec } from 'teen_process';
import { waitForCondition } from 'asyncbox';
import { checkPortStatus } from 'portscanner';
import { execSync } from 'child_process';
import { listChildrenProcessIds, getModuleRoot } from './utils';

const log = logger.getLogger('WebDriverAgentMac');

const DEFAULT_WDA_ROOT = path.resolve(getModuleRoot(), 'WebDriverAgentMac');
const WDA_PROJECT_NAME = 'WebDriverAgentMac.xcodeproj';
const WDA_PROJECT = (wdaRoot = DEFAULT_WDA_ROOT) => path.resolve(wdaRoot, WDA_PROJECT_NAME);
const RUNNER_SCHEME = 'WebDriverAgentRunner';
const DISABLE_STORE_ARG = 'COMPILER_INDEX_STORE_ENABLE=NO';
const XCODEBUILD = 'xcodebuild';
const STARTUP_TIMEOUT_MS = 120000;
const DEFAULT_SYSTEM_PORT = 10100;
const DEFAULT_SYSTEM_HOST = '127.0.0.1';
const DEFAULT_SHOW_SERVER_LOGS = false;
const RUNNING_PROCESS_IDS = [];
const RECENT_UPGRADE_TIMESTAMP_PATH = path.join('.appium', 'webdriveragent_mac', 'upgrade.time');
const RECENT_MODULE_VERSION_ITEM_NAME = 'recentWdaModuleVersion';


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
    this.showServerLogs = DEFAULT_SHOW_SERVER_LOGS;
    this.port = DEFAULT_SYSTEM_PORT;
    this.host = DEFAULT_SYSTEM_HOST;
    this.bootstrapRoot = DEFAULT_WDA_ROOT;
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

  async cleanupProjectIfFresh () {
    const packageInfo = JSON.parse(await fs.readFile(path.join(getModuleRoot(), 'package.json'), 'utf8'));
    const box = strongbox(packageInfo.name);
    let boxItem = box.getItem(RECENT_MODULE_VERSION_ITEM_NAME);
    if (!boxItem) {
      const timestampPath = path.resolve(process.env.HOME, RECENT_UPGRADE_TIMESTAMP_PATH);
      if (await fs.exists(timestampPath)) {
        // TODO: It is probably a bit ugly to hardcode the recent version string,
        // TODO: hovewer it should do the job as a temporary transition trick
        // TODO: to switch from a hardcoded file path to the strongbox usage.
        try {
          boxItem = await box.createItemWithValue(RECENT_MODULE_VERSION_ITEM_NAME, '1.5.4');
        } catch (e) {
          log.warn(`The actual module version cannot be persisted: ${e.message}`);
          return;
        }
      } else {
        log.info('There is no need to perform the project cleanup. A fresh install has been detected');
        try {
          await box.createItemWithValue(RECENT_MODULE_VERSION_ITEM_NAME, packageInfo.version);
        } catch (e) {
          log.warn(`The actual module version cannot be persisted: ${e.message}`);
        }
        return;
      }
    }

    let recentModuleVersion = await boxItem.read();
    try {
      recentModuleVersion = util.coerceVersion(recentModuleVersion, true);
    } catch (e) {
      log.warn(`The persisted module version string has been damaged: ${e.message}`);
      log.info(`Updating it to '${packageInfo.version}' assuming the project clenup is not needed`);
      await boxItem.write(packageInfo.version);
      return;
    }

    if (util.compareVersions(recentModuleVersion, '>=', packageInfo.version)) {
      log.info(
        `WebDriverAgent does not need a cleanup. The project sources are up to date ` +
        `(${recentModuleVersion} >= ${packageInfo.version})`
      );
      return;
    }

    try {
      log.info('Performing project cleanup');
      const args = [
        'clean',
        '-project', WDA_PROJECT(this.bootstrapRoot),
        '-scheme', RUNNER_SCHEME,
      ];
      await exec(XCODEBUILD, args, {cwd: this.bootstrapRoot});
      await boxItem.write(packageInfo.version);
    } catch (e) {
      log.warn(`Cannot perform project cleanup. Original error: ${e.stderr || e.message}`);
    }
  }

  hasSameOpts ({ showServerLogs, systemPort, systemHost, bootstrapRoot }) {
    if (_.isBoolean(showServerLogs) && this.showServerLogs !== showServerLogs
      || _.isNil(showServerLogs) && this.showServerLogs !== DEFAULT_SHOW_SERVER_LOGS) {
      return false;
    }
    if (systemPort && this.port !== systemPort
      || !systemPort && this.port !== DEFAULT_SYSTEM_PORT) {
      return false;
    }
    if (systemHost && this.host !== systemHost
      || !systemHost && this.host !== DEFAULT_SYSTEM_HOST) {
      return false;
    }
    if (bootstrapRoot && this.bootstrapRoot !== bootstrapRoot
      || !bootstrapRoot && this.bootstrapRoot !== DEFAULT_WDA_ROOT) {
      return false;
    }

    return true;
  }

  async init (opts = {}) {
    if (this.isRunning && this.hasSameOpts(opts)) {
      return false;
    }

    this.showServerLogs = opts.showServerLogs ?? this.showServerLogs;
    this.port = opts.systemPort ?? this.port;
    this.host = opts.systemHost ?? this.host;
    this.bootstrapRoot = opts.bootstrapRoot ?? this.bootstrapRoot;

    log.debug(`Using bootstrap root: ${this.bootstrapRoot}`);
    if (!await fs.exists(WDA_PROJECT(this.bootstrapRoot))) {
      throw new Error(`${WDA_PROJECT_NAME} does not exist at '${WDA_PROJECT(this.bootstrapRoot)}'. ` +
        `Was 'bootstrapRoot' set to a proper value?`);
    }

    await this.kill();
    await cleanupObsoleteProcesses();

    let xcodebuild;
    try {
      xcodebuild = await fs.which(XCODEBUILD);
    } catch (e) {
      throw new Error(`${XCODEBUILD} binary cannot be found in PATH. ` +
        `Please make sure that Xcode is installed on your system`);
    }
    log.debug(`Using ${XCODEBUILD} binary at '${xcodebuild}'`);

    await this.cleanupProjectIfFresh();

    log.debug(`Using ${this.host} as server host`);
    log.debug(`Using port ${this.port}`);
    const isPortBusy = async () => (await checkPortStatus(this.port, this.host)) === 'open';
    if (await isPortBusy()) {
      log.warn(`The port #${this.port} at ${this.host} is busy. ` +
        `Assuming it is an obsolete WDA server instance and ` +
        `trying to terminate it in order to start a new one`);
      const timer = new timing.Timer().start();
      try {
        await axios.delete(`http://${this.host}:${this.port}/`, {
          timeout: 5000,
        });
        // Give the server some time to finish and stop listening
        await B.delay(500);
        await waitForCondition(async () => !(await isPortBusy()), {
          waitMs: 3000,
          intervalMs: 100,
        });
      } catch (e) {
        log.warn(`Did not know how to terminate the process at ${this.host}:${this.port}: ${e.message}. ` +
          `Perhaps, it is not a WDA server, which is hogging the port?`);
        throw new Error(`The port #${this.port} at ${this.host} is busy. ` +
          `Consider setting 'systemPort' capability to another free port number and/or ` +
          `make sure previous driver sessions have been closed properly.`);
      }
      log.info(`The previously running WDA server has been successfully terminated after ` +
        `${Math.round(timer.getDuration().asMilliSeconds)}ms`);
    }

    const args = [
      'build-for-testing', 'test-without-building',
      '-project', WDA_PROJECT(this.bootstrapRoot),
      '-scheme', RUNNER_SCHEME,
      DISABLE_STORE_ARG,
    ];
    const env = Object.assign({}, process.env, {
      USE_PORT: `${this.port}`,
      USE_HOST: this.host,
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
    if (!this.isRunning) {
      return;
    }

    const childrenPids = await this.listChildrenPids();
    if (!_.isEmpty(childrenPids)) {
      try {
        await exec('kill', childrenPids);
      } catch (ign) {}
    }
    await this.proc.stop('SIGTERM', 3000);
  }

  async kill () {
    if (!this.isRunning) {
      return;
    }

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

class WDAMacServer {
  constructor () {
    this.process = null;
    this.serverStartupTimeoutMs = STARTUP_TIMEOUT_MS;
    this.proxy = null;

    // To handle if the WDAMac server is proxying requests to a remote WDAMac app instance
    this.isProxyingToRemoteServer = false;
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


  /**
   * @typedef {Object} ProxyProperties
   *
   * @property {string} scheme - The scheme proxy to.
   * @property {string} host - The host name proxy to.
   * @property {number} port - The port number proxy to.
   * @property {string} path - The path proxy to.
   */

  /**
   * Returns proxy information where WDAMacServer proxy to.
   *
   * @param {Object} caps - The capabilities in the session.
   * @return {ProxyProperties}
   * @throws Error if 'webDriverAgentMacUrl' had invalid URL
   */
  parseProxyProperties (caps) {
    let scheme = 'http';
    if (!caps.webDriverAgentMacUrl) {
      return {
        scheme,
        server: (this.process?.host ?? caps.systemHost) ?? DEFAULT_SYSTEM_HOST,
        port: (this.process?.port ?? caps.systemPort) ?? DEFAULT_SYSTEM_PORT,
        path: ''
      };
    }

    let parsedUrl;
    try {
      parsedUrl = new url.URL(caps.webDriverAgentMacUrl);
    } catch (e) {
      throw new Error(`webDriverAgentMacUrl, '${caps.webDriverAgentMacUrl}', ` +
        `in the capabilities is invalid. ${e.message}`);
    }

    const { protocol, hostname, port, pathname } = parsedUrl;
    if (_.isString(protocol)) {
      scheme = protocol.split(':')[0];
    }
    return {
      scheme,
      server: hostname ?? DEFAULT_SYSTEM_HOST,
      port: _.isEmpty(port) ? DEFAULT_SYSTEM_PORT : _.parseInt(port),
      path: pathname === '/' ? '' : pathname
    };
  }

  async startSession (caps) {
    this.serverStartupTimeoutMs = caps.serverStartupTimeout ?? this.serverStartupTimeoutMs;

    this.isProxyingToRemoteServer = !!caps.webDriverAgentMacUrl;

    let wasProcessInitNecessary;
    if (this.isProxyingToRemoteServer) {
      if (this.process) {
        await this.process.kill();
        await cleanupObsoleteProcesses();
        this.process = null;
      }

      wasProcessInitNecessary = false;
    } else {
      if (!this.process) {
        this.process = new WDAMacProcess();
      }
      wasProcessInitNecessary = await this.process.init(caps);
    }

    if (wasProcessInitNecessary || this.isProxyingToRemoteServer || !this.proxy) {
      const {scheme, server, port, path} = this.parseProxyProperties(caps);
      this.proxy = new WDAMacProxy({
        scheme,
        server,
        port,
        base: path,
        keepAlive: true,
      });
      this.proxy.didProcessExit = false;

      if (this.process) {
        this.process.proc.on('exit', () => {
          this.proxy.didProcessExit = true;
        });
      }

      const timer = new timing.Timer().start();
      try {
        await waitForCondition(async () => await this.isProxyReady(), {
          waitMs: this.serverStartupTimeoutMs,
          intervalMs: 1000,
        });
      } catch (e) {
        if (this.process?.isRunning) {
          // avoid "frozen" processes,
          await this.process.kill();
        }
        if (/Condition unmet/.test(e.message)) {
          const msg = this.isProxyingToRemoteServer
            ? `No response from '${scheme}://${server}:${port}${path}' within ${this.serverStartupTimeoutMs}ms timeout.` +
            `Please make sure the remote server is running and accessible by Appium`
            : `Mac2Driver server is not listening within ${this.serverStartupTimeoutMs}ms timeout. ` +
            `Try to increase the value of 'serverStartupTimeout' capability, check the server logs ` +
            `and make sure the ${XCODEBUILD} host process could be started manually from a terminal`;
          throw new Error(msg);
        }
        throw e;
      }

      if (this.process) {
        const pid = this.process.pid;
        const childrenPids = await this.process.listChildrenPids();
        RUNNING_PROCESS_IDS.push(...childrenPids, pid);
        this.process.proc.on('exit', () => void _.pull(RUNNING_PROCESS_IDS, pid));
        log.info(`The host process is ready within ${timer.getDuration().asMilliSeconds.toFixed(0)}ms`);
      }
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
    if (!this.isProxyingToRemoteServer && !(this.process?.isRunning)) {
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
