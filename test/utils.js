const HOST = process.env.APPIUM_TEST_SERVER_HOST || '127.0.0.1';
const PORT = parseInt(process.env.APPIUM_TEST_SERVER_PORT, 10) || 4567;
const MOCHA_TIMEOUT = 240000;
const TEXT_EDIT_BUNDLE_ID = 'com.apple.TextEdit';

export { HOST, PORT, MOCHA_TIMEOUT, TEXT_EDIT_BUNDLE_ID };
