import _ from 'lodash';
import os from 'os';
import path from 'path';
import { JWProxy, errors } from 'appium-base-driver';
import { fs, logger, util, system } from 'appium-support';
import { SubProcess } from 'teen_process';
import { waitForCondition } from 'asyncbox';
import { findAPortNotInUse } from 'portscanner';
import { execSync } from 'child_process';
import { VERBOSITY } from './constants';

const log = logger.getLogger('WebDriverAgentMac');

const GD_BINARY = `geckodriver${system.isWindows() ? '.exe' : ''}`;
const STARTUP_TIMEOUT_MS = 10000; // 10 seconds
const GECKO_PORT_RANGE = [5200, 5300];
const GECKO_SERVER_GUARD = util.getLockFileGuard(
  path.resolve(os.tmpdir(), 'gecko_server_guard.lock'),
  {timeout: 5, tryRecovery: true}
);


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
    for (const optName of ['noReset', 'verbosity', 'androidStorage']) {
      this[optName] = opts[optName];
    }
    this.port = opts.systemPort;
    this.proc = null;
  }

  get isRunning () {
    return !!(this.proc?.isRunning);
  }

  async init () {
    if (this.isRunning) {
      return;
    }

    if (!this.port) {
      await GECKO_SERVER_GUARD(async () => {
        const [startPort, endPort] = GECKO_PORT_RANGE;
        try {
          this.port = await findAPortNotInUse(startPort, endPort);
        } catch (e) {
          throw new Error(
            `Cannot find any free port in range ${startPort}..${endPort}. ` +
            `Double check the processes that are locking ports within this range and terminate ` +
            `these which are not needed anymore or set any free port number to the 'systemPort' capability`);
        }
      });
    }

    let driverBin;
    try {
      driverBin = await fs.which(GD_BINARY);
    } catch (e) {
      throw new Error(`${GD_BINARY} binary cannot be found in PATH. ` +
        `Please make sure it is present on your system`);
    }
    const args = [
      '-p', this.port,
    ];
    switch (_.toLower(this.verbosity)) {
      case VERBOSITY.DEBUG:
        args.push('-v');
        break;
      case VERBOSITY.TRACE:
        args.push('-vv');
        break;
    }
    if (this.noReset) {
      args.push('--connect-existing');
    }
    if (this.androidStorage) {
      args.push('–-android-storage', this.androidStorage);
    }
    this.proc = new SubProcess(driverBin, args);
    this.proc.on('output', (stdout, stderr) => {
      const line = _.trim(stdout || stderr);
      if (line) {
        log.debug(`[${GD_BINARY}] ${line}`);
      }
    });
    this.proc.on('exit', (code, signal) => {
      log.info(`${GD_BINARY} has exited with code ${code}, signal ${signal}`);
    });
    log.info(`Starting '${driverBin}' with args ${JSON.stringify(args)}`);
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
    const command = system.isWindows() ? `taskkill.exe /PID ${pid}` : `kill ${pid}`;
    try {
      execSync(command);
    } catch (ign) {}
  }
});

class WDAMacServer {
  constructor (caps) {
    this.process = new WDAMacProcess(caps);
    this.proxy = null;
  }

  get isRunning () {
    return !!(this.process?.isRunning);
  }

  async start (geckoCaps) {
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
        waitMs: STARTUP_TIMEOUT_MS,
        intervalMs: 1000,
      });
    } catch (e) {
      if (this.process.isRunning) {
        // avoid "frozen" processes,
        await this.process.kill();
      }
      if (/Condition unmet/.test(e.message)) {
        throw new Error(`Gecko Driver server is not listening within ${STARTUP_TIMEOUT_MS}ms timeout. ` +
          `Make sure it could be started manually from a terminal`);
      }
      throw e;
    }
    const pid = this.process.proc.pid;
    RUNNING_PROCESS_IDS.push(pid);
    this.process.proc.on('exit', () => void _.pull(RUNNING_PROCESS_IDS, pid));

    await this.proxy.command('/session', 'POST', {
      capabilities: {
        firstMatch: [{}],
        alwaysMatch: geckoCaps,
      }
    });
  }

  async stop () {
    if (!this.isRunning) {
      log.info(`Gecko Driver session cannot be stopped, because the server is not running`);
      return;
    }

    if (this.proxy?.sessionId) {
      try {
        await this.proxy.command(`/session/${this.proxy.sessionId}`, 'DELETE');
      } catch (e) {
        log.info(`Gecko Driver session cannot be deleted. Original error: ${e.message}`);
      }
    }

    try {
      await this.process.stop();
    } catch (e) {
      log.warn(`Gecko Driver process cannot be stopped (${e.message}). Killing it forcefully`);
      await this.process.kill();
    }
  }
}

export default WDAMacServer;
