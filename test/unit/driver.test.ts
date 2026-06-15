import {describe, it} from 'node:test';
import assert from 'node:assert/strict';
import {Mac2Driver} from '../../lib/driver.js';

describe('Mac2Driver', () => {
  it('should exist', () => {
    assert.ok(Mac2Driver);
  });
});
