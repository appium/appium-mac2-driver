import chai from 'chai';
import chaiAsPromised from 'chai-as-promised';
import sinon from 'sinon';
import * as teen_process from 'teen_process';
import { listChildrenProcessIds } from '../../lib/utils';

const sandbox = sinon.createSandbox();
chai.should();
chai.use(chaiAsPromised);

describe('listChildrenProcessIds', function () {
  const EXAMPLE_PS_OUTPUT = `
  USER                PID  %CPU %MEM      VSZ    RSS   TT  STAT STARTED      TIME COMMAND           PPID
  _coreaudiod         236   3.1  0.0  4343236   4124   ??  Ss   Thu10AM  42:23.82 /usr/sbin/coreau     1
  root               4450   2.8  0.1  4503952   7508   ??  Ss   Thu12PM   0:30.75 /usr/libexec/Tou     1
  me                  435   2.8  1.3  5420884 110008   ??  S    Thu10AM   3:22.93 /System/Applicat     1
  _windowserver       309   1.4  0.6  8229584  48416   ??  Ss   Thu10AM 206:32.94 /System/Library/     1
  me                 2412   0.4  4.0  8857196 332676   ??  S    Thu10AM  54:42.51 /Applications/Fi     1
  me                58224   0.4  1.0  4794712  87728 s005  S     3:31PM   0:03.24 /Applications/Xc     1
  me                23287   0.3  0.1  4978684   5508   ??  S    Fri02PM   6:16.59 /Applications/VL     1
  me                 8131   0.2  1.9  7966904 157260   ??  S    Thu04PM   3:02.67 /Applications/Fi  2412
  _hidd               213   0.1  0.0  4337324   3720   ??  Ss   Thu10AM  24:07.67 /usr/libexec/hid     1
  me                 2434   0.1  1.3  7703680 104936   ??  S    Thu10AM  79:21.15 /Applications/Fi  2412
  me                57884   0.1  0.3  8777744  22112   ??  S     3:15PM   0:15.71 /Applications/Vi 57860
  `;

  afterEach(function () {
    sandbox.restore();
  });

  it('should return empty array for no output', async function () {
    sandbox.stub(teen_process, 'exec');
    teen_process.exec.returns({stdout: '', stderr: ''});
    const result = await listChildrenProcessIds(1234);
    result.should.eql([]);
  });

  it('should return valid array of process ids', async function () {
    sandbox.stub(teen_process, 'exec');
    teen_process.exec.returns({stdout: EXAMPLE_PS_OUTPUT, stderr: ''});
    const result = await listChildrenProcessIds(2412);
    result.should.eql(['8131', '2434']);
  });

  it('should return empty array for no matches', async function () {
    sandbox.stub(teen_process, 'exec');
    teen_process.exec.returns({stdout: EXAMPLE_PS_OUTPUT, stderr: ''});
    const result = await listChildrenProcessIds('241266');
    result.should.eql([]);
  });
});
