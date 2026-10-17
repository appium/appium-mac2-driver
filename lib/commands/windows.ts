import type {Mac2Driver} from '../driver.js';
import type {WindowInfo, WindowState} from '../types.js';

/**
 * Lists the windows of the current application
 *
 * @returns Information about each window, including its element identifier
 */
export async function macosListWindows(this: Mac2Driver): Promise<WindowInfo[]> {
  return (await this.wda.proxy.command('/wda/windows', 'GET')) as WindowInfo[];
}

/**
 * Changes the state and/or geometry of an application window, optionally moving it to another display
 *
 * @param windowId - Identifier of the window element. The main window is used by default
 * @param state - The state to put the window into
 * @param x - Horizontal origin. Global, or relative to the display if `displayId` is set
 * @param y - Vertical origin. Global, or relative to the display if `displayId` is set
 * @param width - Window width
 * @param height - Window height
 * @param displayId - Identifier of the display to move the window to
 * @returns The updated window information
 */
export async function macosAdjustWindow(
  this: Mac2Driver,
  windowId?: string,
  state?: WindowState,
  x?: number,
  y?: number,
  width?: number,
  height?: number,
  displayId?: number,
): Promise<WindowInfo> {
  return (await this.wda.proxy.command('/wda/window/adjust', 'POST', {
    windowId,
    state,
    x,
    y,
    width,
    height,
    displayId,
  })) as WindowInfo;
}
