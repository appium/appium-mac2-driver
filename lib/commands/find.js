import { util } from 'appium-support';


const commands = {};

// This is needed to make lookup by image working
commands.findElOrEls = async function findElOrEls (strategy, selector, mult, context) {
  context = util.unwrapElement(context);
  const endpoint = `/element${context ? `/${context}/element` : ''}${mult ? 's' : ''}`;

  if (strategy === '-ios predicate string') {
    strategy = 'predicate string';
  } else if (strategy === '-ios class chain') {
    strategy = 'class chain';
  }

  return await this.wda.proxy.command(endpoint, 'POST', {
    using: strategy,
    value: selector,
  });
};


export { commands };
export default commands;
