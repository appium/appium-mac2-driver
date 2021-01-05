import WDA_MAC_SERVER from '../../lib/wda-mac';

describe('WDAMacServer', function () {
  describe('shouldPrepareProxy', function () {
    beforeEach(function () {
      WDA_MAC_SERVER.isProxyingToRemoteServer = false;
      WDA_MAC_SERVER.proxy = null;
    });

    it('should do with isProxyingToRemoteServer true', function () {
      WDA_MAC_SERVER.isProxyingToRemoteServer = true;
      WDA_MAC_SERVER.shouldPrepareProxy().should.be.true;
    });

    it('should do with no proxy instancce', function () {
      WDA_MAC_SERVER.shouldPrepareProxy().should.be.true;
    });

    it('should not do since it has proxy instance WebDriverAgentMacUrl with custom path', function () {
      WDA_MAC_SERVER.proxy = Object();
      WDA_MAC_SERVER.shouldPrepareProxy().should.be.false;
    });
  });
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
  });
});
