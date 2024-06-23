import Mac2Driver from '../../lib/driver';

describe('Mac2Driver', function () {
  let chai;
  let should;

  before(async function () {
    chai = await import('chai');
    should = chai.should();
  });

  it('should exist', function () {
    should.exist(Mac2Driver);
  });
});
