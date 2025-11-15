import type { Mac2Driver } from '../driver';
import type { StringRecord } from '@appium/types';

/**
 * Start an app with given bundle identifier or activates it
 * if the app is already running. An exception is thrown if the
 * app with the given identifier cannot be found.
 *
 * @param bundleId - Bundle identifier of the app to be launched or activated.
 *                 Either this property or `path` must be provided
 * @param path - Full path to the app bundle. Either this property or
 *                 `bundleId` must be provided
 * @param args - The list of command line arguments for the app to be launched with.
 *                   This parameter is ignored if the app is already running.
 * @param environment - Environment variables mapping.
 *                   Custom variables are added to the default process environment.
 */
export async function macosLaunchApp(
  this: Mac2Driver,
  bundleId?: string,
  path?: string,
  args?: string[],
  environment?: StringRecord
): Promise<unknown> {
  return await this.wda.proxy.command('/wda/apps/launch', 'POST', {
    arguments: args,
    environment,
    bundleId,
    path,
  });
}

/**
 * Activate an app with given bundle identifier. An exception is thrown if the
 * app cannot be found or is not running.
 *
 * @param bundleId - Bundle identifier of the app to be activated.
 *                 Either this property or `path` must be provided
 * @param path - Full path to the app bundle. Either this property
 *                 or `bundleId` must be provided
 */
export async function macosActivateApp(
  this: Mac2Driver,
  bundleId?: string,
  path?: string
): Promise<unknown> {
  return await this.wda.proxy.command('/wda/apps/activate', 'POST', { bundleId, path });
}

/**
 * Terminate an app with given bundle identifier. An exception is thrown if the
 * app cannot be found.
 *
 * @param bundleId - Bundle identifier of the app to be terminated.
 *                 Either this property or `path` must be provided
 * @param path - Full path to the app bundle. Either this property
 *                 or `bundleId` must be provided
 * @returns `true` if the app was running and has been successfully terminated.
 * `false` if the app was not running before.
 */
export async function macosTerminateApp(
  this: Mac2Driver,
  bundleId?: string,
  path?: string
): Promise<boolean> {
  return (await this.wda.proxy.command('/wda/apps/terminate', 'POST', { bundleId, path })) as boolean;
}

/**
 * Query an app state with given bundle identifier. An exception is thrown if the
 * app cannot be found.
 *
 * @param bundleId - Bundle identifier of the app whose state should be queried.
 *                 Either this property or `path` must be provided
 * @param path - Full path to the app bundle. Either this property
 *                 or `bundleId` must be provided
 * @returns The application state code. See
 * https://developer.apple.com/documentation/xctest/xcuiapplicationstate?language=objc
 * for more details
 */
export async function macosQueryAppState(
  this: Mac2Driver,
  bundleId?: string,
  path?: string
): Promise<number> {
  return (await this.wda.proxy.command('/wda/apps/state', 'POST', { bundleId, path })) as number;
}

