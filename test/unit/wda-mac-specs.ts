import { expect, use } from 'chai';
import { WDA_MAC_SERVER } from '../../lib/wda-mac';
import chaiAsPromised from 'chai-as-promised';

use(chaiAsPromised);

describe('WDAMacServer', function () {
  describe('parseProxyProperties', function () {
    it('should default', function () {
      expect(WDA_MAC_SERVER.parseProxyProperties({})).eql(
        {scheme: 'http', host: '127.0.0.1', port: 10100, path: ''}
      );
    });

    it('should follow WebDriverAgentMacUrl', function () {
      expect(WDA_MAC_SERVER.parseProxyProperties({ webDriverAgentMacUrl: 'http://customhost:9999' })).eql(
        {scheme: 'http', host: 'customhost', port: 9999, path: ''}
      );
    });

    it('should follow WebDriverAgentMacUrl with custom path', function () {
      expect(WDA_MAC_SERVER.parseProxyProperties({ webDriverAgentMacUrl: 'https://customhost/path' })).eql(
        {scheme: 'https', host: 'customhost', port: 10100, path: '/path'}
      );
    });

    it('should follow WebDriverAgentMacUrl with invalid url', function () {
      try {
        WDA_MAC_SERVER.parseProxyProperties({ webDriverAgentMacUrl: 'invalid url' });
      } catch (e: any) {
        e.message.should.contain('is invalid');
      }
    });
  });
});
