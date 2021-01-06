import chai from 'chai';
import chaiAsPromised from 'chai-as-promised';
import WDA_MAC_SERVER from '../../lib/wda-mac';

chai.use(chaiAsPromised);

describe('WDAMacServer', function () {
  describe('parseProxyProperties', function () {
    it('should default', function () {
      WDA_MAC_SERVER.parseProxyProperties({}).should.eql(
        {scheme: 'http', server: '127.0.0.1', port: 10100, path: ''}
      );
    });

    it('should follow WebDriverAgentMacUrl', function () {
      WDA_MAC_SERVER.parseProxyProperties({ webDriverAgentMacUrl: 'http://customhost:9999' }).should.eql(
        {scheme: 'http', server: 'customhost', port: 9999, path: ''}
      );
    });

    it('should follow WebDriverAgentMacUrl with custom path', function () {
      WDA_MAC_SERVER.parseProxyProperties({ webDriverAgentMacUrl: 'https://customhost/path' }).should.eql(
        {scheme: 'https', server: 'customhost', port: 10100, path: '/path'}
      );
    });

    it('should follow WebDriverAgentMacUrl with invalid url', function () {
      try {
        WDA_MAC_SERVER.parseProxyProperties({ webDriverAgentMacUrl: 'invalid url' });
      } catch (e) {
        e.message.should.contain('is invalid');
      }
    });
  });
});
