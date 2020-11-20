import { util } from 'appium-support';


const commands = {};

// This is needed to make lookup by image working
commands.findElOrEls = async function findElOrEls (strategy, selector, mult, context) {
  context = util.unwrapElement(context);
  const endpoint = `/element${context ? `/${context}/element` : ''}${mult ? 's' : ''}`;

  return await this.gecko.proxy.command(endpoint, 'POST', {
    using: strategy,
    value: selector,
  });
};


export { commands };
export default commands;
