import {describe, it} from 'node:test';
import assert from 'node:assert/strict';
import {WDA_MAC_SERVER} from '../../lib/wda-mac.js';

describe('WDAMacServer', () => {
  describe('parseProxyProperties', () => {
    it('should default', () => {
      assert.deepEqual((WDA_MAC_SERVER as any).parseProxyProperties({}), {
        scheme: 'http',
        host: '127.0.0.1',
        port: 10100,
        path: '',
      });
    });

    it('should follow WebDriverAgentMacUrl', () => {
      assert.deepEqual(
        (WDA_MAC_SERVER as any).parseProxyProperties({
          webDriverAgentMacUrl: 'http://customhost:9999',
        }),
        {scheme: 'http', host: 'customhost', port: 9999, path: ''},
      );
    });

    it('should follow WebDriverAgentMacUrl with custom path', () => {
      assert.deepEqual(
        (WDA_MAC_SERVER as any).parseProxyProperties({
          webDriverAgentMacUrl: 'https://customhost/path',
        }),
        {scheme: 'https', host: 'customhost', port: 10100, path: '/path'},
      );
    });

    it('should follow WebDriverAgentMacUrl with invalid url', () => {
      assert.throws(
        () => (WDA_MAC_SERVER as any).parseProxyProperties({webDriverAgentMacUrl: 'invalid url'}),
        /is invalid/,
      );
    });
  });
});
