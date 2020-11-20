import _ from 'lodash';

const GECKO_CAP_PREFIXES = ['moz:'];
// https://www.w3.org/TR/webdriver/#capabilities
const STANDARD_CAPS = [
  'browserVersion',
  'platformName',
  'acceptInsecureCerts',
  'pageLoadStrategy',
  'proxy',
  'setWindowRect',
  'timeouts',
  'unhandledPromptBehavior',
];

function formatCapsForServer (caps) {
  const result = {};
  if (caps.browserName) {
    result.browserName = 'firefox';
  }
  for (const [name, value] of _.toPairs(caps)) {
    if (GECKO_CAP_PREFIXES.some((prefix) => name.startsWith(prefix)) || STANDARD_CAPS.includes(name)) {
      result[name] = value;
    }
  }
  if (result.platformName) {
    // Geckodriver only supports lowercase platform names
    result.platformName = _.toLower(result.platformName);
  }
  return result;
}

export { formatCapsForServer };
