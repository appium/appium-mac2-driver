import _ from 'lodash';
import { util } from 'appium/support';
import { errors } from 'appium/driver';
import type { Mac2Driver } from '../driver';
import type { KeyOptions } from '../types';

/**
 * Set value to the given element.
 * Note:
 * This is not exposed as 'macos: setValue' because this is the same as
 * element.send_keys in W3C WebDriver spec.
 *
 * @param elementId - Uuid of the element to set value for.
 * @param value - Value to set. Could also be an array.
 * @param text - Text to set. If both value and text are set then `value` is preferred
 * @param keyModifierFlags - If set then the given key modifiers will
 *                  be applied while the element value is being set. See
 *                  https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                  for more details.
 */
export async function macosSetValue(
  this: Mac2Driver,
  elementId: string,
  value?: any,
  text?: string,
  keyModifierFlags?: number
): Promise<unknown> {
  return await this.wda.proxy.command(`/element/${elementId}/value`, 'POST', {
    value,
    text,
    keyModifierFlags,
  });
}

/**
 * Perform click gesture on an element or by relative/absolute coordinates
 *
 * @param elementId - Uuid of the element to click. Either this property
 *                  or/and x and y must be set. If both are set then x and y are
 *                  considered as relative element coordinates. If only x and y
 *                  are set then these are parsed as absolute coordinates.
 * @param x - Click X coordinate
 * @param y - Click Y coordinate
 * @param keyModifierFlags - If set then the given key modifiers will be
 *                  applied while click is performed. See
 *                  https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                  for more details
 */
export async function macosClick(
  this: Mac2Driver,
  elementId?: string,
  x?: number,
  y?: number,
  keyModifierFlags?: number
): Promise<unknown> {
  requireElementIdOrXY(elementId, x, y);
  const url = elementId ? `/element/${elementId}/click` : '/wda/click';
  return await this.wda.proxy.command(url, 'POST', {
    x,
    y,
    keyModifierFlags,
  });
}

/**
 * Perform scroll gesture on an element or by relative/absolute coordinates
 *
 * @param deltaX - Horizontal delta as float number
 * @param deltaY - Vertical delta as float number
 * @param elementId - Uuid of the element to be scrolled. Either this property
 *                 or/and x and y must be set. If both are set then x and y are
 *                 considered as relative element coordinates. If only x and y are
 *                 set then these are parsed as absolute coordinates.
 * @param x - Scroll X coordinate
 * @param y - Scroll Y coordinate
 * @param keyModifierFlags - If set then the given key modifiers will be
 *                 applied while scroll is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosScroll(
  this: Mac2Driver,
  deltaX: number,
  deltaY: number,
  elementId?: string,
  x?: number,
  y?: number,
  keyModifierFlags?: number
): Promise<unknown> {
  requireElementIdOrXY(elementId, x, y);
  const url = elementId ? `/wda/element/${elementId}/scroll` : '/wda/scroll';
  return await this.wda.proxy.command(url, 'POST', {
    deltaX,
    deltaY,
    x,
    y,
    keyModifierFlags,
  });
}

/**
 * Perform swipe gesture on an element
 *
 * @param direction - Swipe direction
 * @param elementId - Uuid of the element to be swiped. Either this property
 *                 or/and x and y must be set. If both are set then x and y are
 *                 considered as relative element coordinates. If only x and y are
 *                 set then these are parsed as absolute coordinates.
 * @param x - Swipe X coordinate
 * @param y - Swipe Y coordinate
 * @param velocity - The value is measured in pixels per second and same
 *                 values could behave differently on different devices depending
 *                 on their display density. Higher values make swipe gesture faster
 *                 (which usually scrolls larger areas if we apply it to a list)
 *                 and lower values slow it down. Only values greater than zero have effect.
 * @param keyModifierFlags - If set then the given key modifiers will be
 *                 applied while scroll is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosSwipe(
  this: Mac2Driver,
  direction: 'up' | 'down' | 'left' | 'right',
  elementId?: string,
  x?: number,
  y?: number,
  velocity?: number,
  keyModifierFlags?: number
): Promise<unknown> {
  requireElementIdOrXY(elementId, x, y);
  const url = elementId ? `/wda/element/${elementId}/swipe` : `/wda/swipe`;
  return await this.wda.proxy.command(url, 'POST', {
    x,
    y,
    direction,
    velocity,
    keyModifierFlags,
  });
}

/**
 * Perform right click gesture on an element or by relative/absolute coordinates
 *
 * @param elementId - Uuid of the element to click. Either this property
 *                 or/and x and y must be set. If both are set then x and y are
 *                 considered as relative element coordinates. If only x and y
 *                 are set then these are parsed as absolute coordinates.
 * @param x - Click X coordinate
 * @param y - Click Y coordinate
 * @param keyModifierFlags - If set then the given key modifiers will be
 *                 applied while click is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosRightClick(
  this: Mac2Driver,
  elementId?: string,
  x?: number,
  y?: number,
  keyModifierFlags?: number
): Promise<unknown> {
  requireElementIdOrXY(elementId, x, y);
  const url = elementId ? `/wda/element/${elementId}/rightClick` : '/wda/rightClick';
  return await this.wda.proxy.command(url, 'POST', {
    x,
    y,
    keyModifierFlags,
  });
}

/**
 * Perform hover gesture on an element or by relative/absolute coordinates
 *
 * @param elementId - Uuid of the element to hover. Either this property
 *                 or/and x and y must be set. If both are set then x and y are
 *                 considered as relative element coordinates. If only x and y
 *                 are set then these are parsed as absolute coordinates.
 * @param x - Click X coordinate
 * @param y - Click Y coordinate
 * @param keyModifierFlags - If set then the given key modifiers will be
 *                 applied while click is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosHover(
  this: Mac2Driver,
  elementId?: string,
  x?: number,
  y?: number,
  keyModifierFlags?: number
): Promise<unknown> {
  requireElementIdOrXY(elementId, x, y);
  const url = elementId ? `/wda/element/${elementId}/hover` : '/wda/hover';
  return await this.wda.proxy.command(url, 'POST', {
    x,
    y,
    keyModifierFlags,
  });
}

/**
 * Perform double click gesture on an element or by relative/absolute coordinates
 *
 * @param elementId - Uuid of the element to hover. Either this property
 *                 or/and x and y must be set. If both are set then x and y are
 *                 considered as relative element coordinates. If only x and y
 *                 are set then these are parsed as absolute coordinates.
 * @param x - Click X coordinate
 * @param y - Click Y coordinate
 * @param keyModifierFlags - If set then the given key modifiers will be
 *                 applied while click is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosDoubleClick(
  this: Mac2Driver,
  elementId?: string,
  x?: number,
  y?: number,
  keyModifierFlags?: number
): Promise<unknown> {
  requireElementIdOrXY(elementId, x, y);
  const url = elementId ? `/wda/element/${elementId}/doubleClick` : '/wda/doubleClick';
  return await this.wda.proxy.command(url, 'POST', {
    x,
    y,
    keyModifierFlags,
  });
}

/**
 * Perform long click and drag gesture on an element or by absolute coordinates
 *
 * @param duration - Long click duration in float seconds
 * @param sourceElementId - Uuid of the element to start the drag from.
 *                 Either this property and `destinationElement` must be provided
 *                 or `startX`, `startY`, `endX`, `endY` coordinates must be set.
 * @param destinationElementId - Uuid of the element to end the drag on.
 *                 Either this property and `sourceElement` must be provided or
 *                 `startX`, `startY`, `endX`, `endY` coordinatesmust be set.
 * @param startX - Starting X coordinate
 * @param startY - Starting Y coordinate
 * @param endX - Ending X coordinate
 * @param endY - Ending Y coordinate
 * @param keyModifierFlags - If set then the given key modifiers will be
 *                 applied while drag is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosClickAndDrag(
  this: Mac2Driver,
  duration: number,
  sourceElementId?: string,
  destinationElementId?: string,
  startX?: number,
  startY?: number,
  endX?: number,
  endY?: number,
  keyModifierFlags?: number
): Promise<unknown> {
  requireSourceDestWithElementsOrCoordinates(
    sourceElementId,
    destinationElementId,
    startX,
    startY,
    endX,
    endY
  );
  const url =
    sourceElementId && destinationElementId
      ? `/wda/element/${sourceElementId}/clickAndDrag`
      : '/wda/clickAndDrag';
  const dest = destinationElementId && util.wrapElement(destinationElementId);
  return await this.wda.proxy.command(url, 'POST', {
    startX,
    startY,
    endX,
    endY,
    duration,
    dest,
    keyModifierFlags,
  });
}

/**
 * Perform long click, drag and hold gesture on an element or by absolute coordinates
 *
 * @param duration - Long click duration in float seconds
 * @param holdDuration - Touch hold duration in float seconds
 * @param sourceElementId - Uuid of the element to start the drag from.
 *                 Either this property and `destinationElement` must be provided
 *                 or `startX`, `startY`, `endX`, `endY` coordinates must be set.
 * @param destinationElementId - Uuid of the element to end the drag on.
 *                 Either this property and `sourceElement` must be provided
 *                 or `startX`, `startY`, `endX`, `endY` coordinates must be set.
 * @param startX - Starting X coordinate
 * @param startY - Starting Y coordinate
 * @param endX - Ending X coordinate
 * @param endY - Ending Y coordinate
 * @param velocity - Dragging velocity in pixels per second.
 *                 If not provided then the default velocity is used. See
 *                 https://developer.apple.com/documentation/xctest/xcuigesturevelocity
 *                 for more details
 * @param keyModifierFlags - If set then the given key modifiers will be
 *                 applied while drag is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosClickAndDragAndHold(
  this: Mac2Driver,
  duration: number,
  holdDuration: number,
  sourceElementId?: string,
  destinationElementId?: string,
  startX?: number,
  startY?: number,
  endX?: number,
  endY?: number,
  velocity?: number,
  keyModifierFlags?: number
): Promise<unknown> {
  requireSourceDestWithElementsOrCoordinates(
    sourceElementId,
    destinationElementId,
    startX,
    startY,
    endX,
    endY
  );
  const url =
    sourceElementId && destinationElementId
      ? `/wda/element/${sourceElementId}/clickAndDragAndHold`
      : '/wda/clickAndDragAndHold';
  const dest = destinationElementId && util.wrapElement(destinationElementId);
  return await this.wda.proxy.command(url, 'POST', {
    startX,
    startY,
    endX,
    endY,
    duration,
    holdDuration,
    velocity,
    dest,
    keyModifierFlags,
  });
}

/**
 * Send keys to the given element or to the application under test
 *
 * @param keys - Array of keys to type.
 *                 Each item could either be a string, that represents a key itself (see
 *                 https://developer.apple.com/documentation/xctest/xcuielement/1500604-typekey
 *                 and https://developer.apple.com/documentation/xctest/xcuikeyboardkey)
 *                 or a dictionary, if the key should also be entered with modifiers.
 * @param elementId - Uuid of the element to send the keys to.
 *                 If unset then keys are sent to the current application
 *                 under test.
 */
export async function macosKeys(
  this: Mac2Driver,
  keys: (KeyOptions | string)[],
  elementId?: string
): Promise<unknown> {
  const url = elementId ? `/wda/element/${elementId}/keys` : '/wda/keys';
  return await this.wda.proxy.command(url, 'POST', { keys });
}

/**
 * Perform tap gesture on a Touch Bar element or by relative/absolute coordinates
 *
 * @param elementId - Uuid of the Touch Bar element to tap. Either this property
 *                 or/and x and y must be set. If both are set then x and y are considered
 *                 as relative element coordinates. If only x and y are set then
 *                 these are parsed as absolute Touch Bar coordinates.
 * @param x - Tap X coordinate
 * @param y - Tap Y coordinate
 * @param keyModifierFlags - If set then the given key modifiers will be
 *                 applied while click is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosTap(
  this: Mac2Driver,
  elementId?: string,
  x?: number,
  y?: number,
  keyModifierFlags?: number
): Promise<unknown> {
  requireElementIdOrXY(elementId, x, y);
  const url = elementId ? `/wda/element/${elementId}/tap` : '/wda/tap';
  return await this.wda.proxy.command(url, 'POST', {
    x,
    y,
    keyModifierFlags,
  });
}

/**
 * Perform tap gesture on a Touch Bar element or by relative/absolute coordinates
 *
 * @param elementId - Uuid of the Touch Bar element to tap. Either this property
 *                 or/and x and y must be set. If both are set then x and y are considered
 *                 as relative element coordinates. If only x and y are set then
 *                 these are parsed as absolute Touch Bar coordinates.
 * @param x - Tap X coordinate
 * @param y - Tap Y coordinate
 * @param keyModifierFlags - If set then the given key modifiers will be
 *                 applied while click is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosDoubleTap(
  this: Mac2Driver,
  elementId?: string,
  x?: number,
  y?: number,
  keyModifierFlags?: number
): Promise<unknown> {
  requireElementIdOrXY(elementId, x, y);
  const url = elementId ? `/wda/element/${elementId}/doubleTap` : '/wda/doubleTap';
  return await this.wda.proxy.command(url, 'POST', {
    x,
    y,
    keyModifierFlags,
  });
}

/**
 * Perform press gesture on a Touch Bar element or by relative/absolute coordinates
 *
 * @param duration - The number of float seconds to hold the mouse button
 * @param elementId - Uuid of the Touch Bar element to be pressed. Either this property
 *                 or/and x and y must be set. If both are set then x and y are considered
 *                 as relative element coordinates. If only x and y are set then these are
 *                 parsed as absolute Touch Bar coordinates.
 * @param x - Press X coordinate
 * @param y - Press Y coordinate
 * @param keyModifierFlags - If set then the given key modifiers will be
 *                 applied while click is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosPressAndHold(
  this: Mac2Driver,
  duration: number,
  elementId?: string,
  x?: number,
  y?: number,
  keyModifierFlags?: number
): Promise<unknown> {
  const url = elementId ? `/wda/element/${elementId}/press` : '/wda/press';
  return await this.wda.proxy.command(url, 'POST', {
    x,
    y,
    duration,
    keyModifierFlags,
  });
}

/**
 * Perform long press and drag gesture on a Touch Bar element or by absolute coordinates
 *
 * @param duration - Long press duration in float seconds
 * @param sourceElementId - Uuid of a Touch Bar element to start the drag from.
 *                 Either this property and `destinationElement` must be provided or
 *                 `startX`, `startY`, `endX`, `endY` coordinates must be set.
 * @param destinationElementId - Uuid of a Touch Bar element to end the drag on.
 *                 Either this property and `sourceElement` must be provided or
 *                 `startX`, `startY`, `endX`, `endY` coordinates must be set.
 * @param startX - Starting X coordinate
 * @param startY - Starting Y coordinate
 * @param endX - Ending X coordinate
 * @param endY - Ending Y coordinate
 * @param keyModifierFlags - If set then the given key modifiers will be
 *                 applied while drag is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosPressAndDrag(
  this: Mac2Driver,
  duration: number,
  sourceElementId?: string,
  destinationElementId?: string,
  startX?: number,
  startY?: number,
  endX?: number,
  endY?: number,
  keyModifierFlags?: number
): Promise<unknown> {
  // requireSourceDestWithElementsOrCoordinates(
  //   sourceElementId, destinationElementId,
  //   startX, startY, endX, endY,
  // );
  const url =
    sourceElementId && destinationElementId
      ? `/wda/element/${sourceElementId}/pressAndDrag`
      : '/wda/pressAndDrag';
  const dest = destinationElementId && util.wrapElement(destinationElementId);
  return await this.wda.proxy.command(url, 'POST', {
    startX,
    startY,
    endX,
    endY,
    duration,
    dest,
    keyModifierFlags,
  });
}

/**
 * Perform press, drag and hold gesture on a Touch Bar element or by absolute Touch Bar coordinates
 *
 * @param duration - Long press duration in float seconds
 * @param holdDuration - Touch hold duration in float seconds
 * @param sourceElementId - Uuid of a Touch Bar element to start the drag from.
 *                 Either this property and `destinationElement` must be provided or
 *                 `startX`, `startY`, `endX`, `endY` coordinates must be set.
 * @param destinationElementId - Uuid of a Touch Bar element to end the drag on.
 *                 Either this property and `sourceElement` must be provided or
 *                 `startX`, `startY`, `endX`, `endY` coordinates must be set.
 * @param startX - Starting X coordinate
 * @param startY - Starting Y coordinate
 * @param endX - Ending X coordinate
 * @param endY - Ending Y coordinate
 * @param velocity - Dragging velocity in pixels per second.
 *                 If not provided then the default velocity is used. See
 *                 https://developer.apple.com/documentation/xctest/xcuigesturevelocity
 *                 for more details
 * @param keyModifierFlags - If set then the given key modifiers will be
 *                 applied while drag is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosPressAndDragAndHold(
  this: Mac2Driver,
  duration: number,
  holdDuration: number,
  sourceElementId?: string,
  destinationElementId?: string,
  startX?: number,
  startY?: number,
  endX?: number,
  endY?: number,
  velocity?: number,
  keyModifierFlags?: number
): Promise<unknown> {
  requireSourceDestWithElementsOrCoordinates(
    sourceElementId,
    destinationElementId,
    startX,
    startY,
    endX,
    endY
  );
  const url =
    sourceElementId && destinationElementId
      ? `/wda/element/${sourceElementId}/pressAndDragAndHold`
      : '/wda/pressAndDragAndHold';
  const dest = destinationElementId && util.wrapElement(destinationElementId);
  return await this.wda.proxy.command(url, 'POST', {
    startX,
    startY,
    endX,
    endY,
    duration,
    holdDuration,
    velocity,
    dest,
    keyModifierFlags,
  });
}

/**
 * Raise invalid argument error if element id was unset or x and y were unset.
 * @param elementId - Optional element ID
 * @param x - Optional X coordinate
 * @param y - Optional Y coordinate
 */
function requireElementIdOrXY(elementId?: string, x?: number, y?: number): void {
  if (!_.isString(elementId) && !(_.isNumber(x) && _.isNumber(y))) {
    throw new errors.InvalidArgumentError(`'elementId' or 'x' and 'y' is required.`);
  }
}

/**
 * Raise invalid argument error if sourceElementId and destinationElementId were unset
 * or startX, startY, endX and endY were unset.
 * @param sourceElementId - Optional source element ID
 * @param destinationElementId - Optional destination element ID
 * @param startX - Optional starting X coordinate
 * @param startY - Optional starting Y coordinate
 * @param endX - Optional ending X coordinate
 * @param endY - Optional ending Y coordinate
 */
function requireSourceDestWithElementsOrCoordinates(
  sourceElementId?: string,
  destinationElementId?: string,
  startX?: number,
  startY?: number,
  endX?: number,
  endY?: number
): void {
  if (
    !(_.isString(sourceElementId) && _.isString(destinationElementId)) &&
    !(_.isNumber(startX) && _.isNumber(startY) && _.isNumber(endX) && _.isNumber(endY))
  ) {
    throw new errors.InvalidArgumentError(
      `'sourceElementId' and 'destinationElementId' ` +
        `or 'startX', 'startY', 'endX' and 'endY' are required.`
    );
  }
}

