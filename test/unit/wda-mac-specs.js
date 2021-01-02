import WDA_MAC_SERVER from '../../lib/wda-mac';

describe('WDAMacServer', function () {
  describe('_get_proxy_preference', function () {
    it('should default', function () {
      WDA_MAC_SERVER._get_proxy_preference({}).should.eql(
        {scheme: 'http', host: '127.0.0.1', port: 10100, path: ''}
      );
    });

    it('should follow WebDriverAgentMacUrl', function () {
      WDA_MAC_SERVER._get_proxy_preference({
        WebDriverAgentMacUrl: 'http://customhost:9999'
      }).should.eql(
        {scheme: 'http', host: 'customhost', port: 9999, path: ''}
      );
    });

    it('should follow WebDriverAgentMacUrl with custom path', function () {
      WDA_MAC_SERVER._get_proxy_preference({
        WebDriverAgentMacUrl: 'https://customhost/path'
      }).should.eql(
        {scheme: 'https', host: 'customhost', port: 10100, path: '/path'}
      );
    });
  });
});
