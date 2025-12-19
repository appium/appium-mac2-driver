export const HOST: string = process.env.APPIUM_TEST_SERVER_HOST || '127.0.0.1';
export const PORT: number = parseInt(process.env.APPIUM_TEST_SERVER_PORT || '', 10) || 4567;
export const MOCHA_TIMEOUT: number = 240000;
export const TEXT_EDIT_BUNDLE_ID: string = 'com.apple.TextEdit';
