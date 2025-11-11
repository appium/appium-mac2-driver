import { WDA_MAC_SERVER } from '../../lib/wda-mac';

describe('WDAMacServer', function () {
  let chai;

  before(async function () {
    chai = await import('chai');
    const chaiAsPromised = await import('chai-as-promised');

    chai.should();
    chai.use(chaiAsPromised.default);
  });

  describe('parseProxyProperties', function () {
    it('should default', function () {
      WDA_MAC_SERVER.parseProxyProperties({}).should.eql(
        {scheme: 'http', host: '127.0.0.1', port: 10100, path: ''}
      );
    });

    it('should follow WebDriverAgentMacUrl', function () {
      WDA_MAC_SERVER.parseProxyProperties({ webDriverAgentMacUrl: 'http://customhost:9999' }).should.eql(
        {scheme: 'http', host: 'customhost', port: 9999, path: ''}
      );
    });

    it('should follow WebDriverAgentMacUrl with custom path', function () {
      WDA_MAC_SERVER.parseProxyProperties({ webDriverAgentMacUrl: 'https://customhost/path' }).should.eql(
        {scheme: 'https', host: 'customhost', port: 10100, path: '/path'}
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
