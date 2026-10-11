import assert from 'node:assert/strict';
import {describe, it} from 'node:test';

import {Mac2Driver} from '../../lib/driver.js';

describe('Mac2Driver', () => {
  it('should exist', () => {
    assert.ok(Mac2Driver);
  });

  describe('postrun', () => {
    function makeDriver(hasClaimedHost: boolean) {
      const driver = new Mac2Driver({} as any);
      const scripts: string[] = [];
      driver.opts = {postrun: {script: 'quit app'}} as any;
      driver.macosExecAppleScript = (async (script: string) => {
        scripts.push(script);
        return '';
      }) as any;
      (driver as any)._hasClaimedHost = hasClaimedHost;
      return {driver, scripts};
    }

    it('runs after a session that has claimed the host', async () => {
      const {driver, scripts} = makeDriver(true);
      await driver.deleteSession();
      assert.deepEqual(scripts, ['quit app']);
    });

    it('is skipped for a session that has failed to claim the host', async () => {
      const {driver, scripts} = makeDriver(false);
      await driver.deleteSession();
      assert.deepEqual(scripts, []);
    });
  });
});
