export const HOST: string = process.env.APPIUM_TEST_SERVER_HOST || '127.0.0.1';
export const PORT: number = parseInt(process.env.APPIUM_TEST_SERVER_PORT || '', 10) || 4567;
export const TEST_TIMEOUT: number = 240000;
export const TEXT_EDIT_BUNDLE_ID: string = 'com.apple.TextEdit';

const W3C_ELEMENT_KEY = 'element-6066-11e4-a52e-4f735466cecf';

/** Extracts the element id from the W3C element reference returned by the find commands */
export const elementId = (el: Record<string, string>): string => el[W3C_ELEMENT_KEY];
