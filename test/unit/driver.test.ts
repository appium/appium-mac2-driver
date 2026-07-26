import assert from 'node:assert/strict';
import {describe, it} from 'node:test';

import {Mac2Driver} from '../../lib/driver.js';

describe('Mac2Driver', () => {
  it('should exist', () => {
    assert.ok(Mac2Driver);
  });
});
