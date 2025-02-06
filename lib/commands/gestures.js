import _ from 'lodash';
import { util } from 'appium/support';
import { errors } from 'appium/driver';

/**
 * Set value to the given element.
 * Note:
 * This is not exposed as 'macos: setValue' because this is the same as
 * element.send_keys in W3C WebDriver spec.
 *
 * @this {Mac2Driver}
 * @param {string} elementId Uuid of the element to set value for.
 * @param {any} [value] Value to set. Could also be an array.
 * @param {string} [text] Text to set. If both value and text are set then `value` is preferred
 * @param {number} [keyModifierFlags] If set then the given key modifiers will
 *                  be applied while the element value is being set. See
 *                  https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                  for more details.
 */
export async function macosSetValue (elementId, value, text, keyModifierFlags) {
  return await this.wda.proxy.command(`/element/${elementId}/value`, 'POST', {
    value, text,
    keyModifierFlags,
  });
};


/**
 * Perform click gesture on an element or by relative/absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {string} [elementId] Uuid of the element to click. Either this property
 *                  or/and x and y must be set. If both are set then x and y are
 *                  considered as relative element coordinates. If only x and y
 *                  are set then these are parsed as absolute coordinates.
 * @param {number} [x] Click X coordinate
 * @param {number} [y] Click Y coordinate
 * @param {number} [keyModifierFlags] If set then the given key modifiers will be
 *                  applied while click is performed. See
 *                  https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                  for more details
 */
export async function macosClick (elementId, x, y, keyModifierFlags) {
  requireElementIdOrXY(elementId, x, y);
  const url = elementId ? `/element/${elementId}/click` : '/wda/click';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    keyModifierFlags,
  });
};

/**
 * Perform scroll gesture on an element or by relative/absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {number} deltaX Horizontal delta as float number
 * @param {number} deltaY Vertical delta as float number
 * @param {string} [elementId] Uuid of the element to be scrolled. Either this property
 *                 or/and x and y must be set. If both are set then x and y are
 *                 considered as relative element coordinates. If only x and y are
 *                 set then these are parsed as absolute coordinates.
 * @param {number} [x] Scroll X coordinate
 * @param {number} [y] Scroll Y coordinate
 * @param {number} [keyModifierFlags] If set then the given key modifiers will be
 *                 applied while scroll is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosScroll (
  deltaX, deltaY,
  elementId,
  x, y,
  keyModifierFlags
) {
  requireElementIdOrXY(elementId, x, y);
  const url = elementId ? `/wda/element/${elementId}/scroll` : '/wda/scroll';
  return await this.wda.proxy.command(url, 'POST', {
    deltaX, deltaY,
    x, y,
    keyModifierFlags,
  });
};

/**
 * Perform swipe gesture on an element
 *
 * @this {Mac2Driver}
 * @param {'up'|'down'|'left'|'right'} direction Swipe direction
 * @param {string} [elementId] Uuid of the element to be swiped. Either this property
 *                 or/and x and y must be set. If both are set then x and y are
 *                 considered as relative element coordinates. If only x and y are
 *                 set then these are parsed as absolute coordinates.
 * @param {number} [x] Swipe X coordinate
 * @param {number} [y] Swipe Y coordinate
 * @param {number} [velocity] The value is measured in pixels per second and same
 *                 values could behave differently on different devices depending
 *                 on their display density. Higher values make swipe gesture faster
 *                 (which usually scrolls larger areas if we apply it to a list)
 *                 and lower values slow it down. Only values greater than zero have effect.
 * @param {number} [keyModifierFlags] If set then the given key modifiers will be
 *                 applied while scroll is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosSwipe (
  direction,
  elementId,
  x, y,
  velocity,
  keyModifierFlags
) {
  requireElementIdOrXY(elementId, x, y);
  const url = elementId ? `/wda/element/${elementId}/swipe` : `/wda/swipe`;
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    direction,
    velocity,
    keyModifierFlags,
  });
};

/**
 * Perform right click gesture on an element or by relative/absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {string} [elementId] Uuid of the element to click. Either this property
 *                 or/and x and y must be set. If both are set then x and y are
 *                 considered as relative element coordinates. If only x and y
 *                 are set then these are parsed as absolute coordinates.
 * @param {number} [x] Click X coordinate
 * @param {number} [y] Click Y coordinate
 * @param {number} [keyModifierFlags] If set then the given key modifiers will be
 *                 applied while click is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosRightClick (elementId, x, y, keyModifierFlags) {
  requireElementIdOrXY(elementId, x, y);
  const url = elementId ? `/wda/element/${elementId}/rightClick` : '/wda/rightClick';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    keyModifierFlags,
  });
};

/**
 * Perform hover gesture on an element or by relative/absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {string} [elementId] Uuid of the element to hover. Either this property
 *                 or/and x and y must be set. If both are set then x and y are
 *                 considered as relative element coordinates. If only x and y
 *                 are set then these are parsed as absolute coordinates.
 * @param {number} [x] Click X coordinate
 * @param {number} [y] Click Y coordinate
 * @param {number} [keyModifierFlags] If set then the given key modifiers will be
 *                 applied while click is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosHover (elementId, x, y, keyModifierFlags) {
  requireElementIdOrXY(elementId, x, y);
  const url = elementId ? `/wda/element/${elementId}/hover` : '/wda/hover';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    keyModifierFlags,
  });
};

/**
 * Perform double click gesture on an element or by relative/absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {string} [elementId] Uuid of the element to hover. Either this property
 *                 or/and x and y must be set. If both are set then x and y are
 *                 considered as relative element coordinates. If only x and y
 *                 are set then these are parsed as absolute coordinates.
 * @param {number} [x] Click X coordinate
 * @param {number} [y] Click Y coordinate
 * @param {number} [keyModifierFlags] If set then the given key modifiers will be
 *                 applied while click is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosDoubleClick (elementId, x, y, keyModifierFlags) {
  requireElementIdOrXY(elementId, x, y);
  const url = elementId ? `/wda/element/${elementId}/doubleClick` : '/wda/doubleClick';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    keyModifierFlags,
  });
};

/**
 * Perform long click and drag gesture on an element or by absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {number} duration Long click duration in float seconds
 * @param {string} [sourceElementId] Uuid of the element to start the drag from.
 *                 Either this property and `destinationElement` must be provided
 *                 or `startX`, `startY`, `endX`, `endY` coordinates must be set.
 * @param {string} [destinationElementId] Uuid of the element to end the drag on.
 *                 Either this property and `sourceElement` must be provided or
 *                 `startX`, `startY`, `endX`, `endY` coordinatesmust be set.
 * @param {number} [startX] Starting X coordinate
 * @param {number} [startY] Starting Y coordinate
 * @param {number} [endX] Ending X coordinate
 * @param {number} [endY] Ending Y coordinate
 * @param {number} [keyModifierFlags] If set then the given key modifiers will be
 *                 applied while drag is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosClickAndDrag (
  duration,
  sourceElementId,
  destinationElementId,
  startX, startY,
  endX, endY,
  keyModifierFlags
) {
  requireSourceDestWithElementsOrCoordinates(
    sourceElementId, destinationElementId,
    startX, startY, endX, endY,
  );
  const url = sourceElementId && destinationElementId
    ? `/wda/element/${sourceElementId}/clickAndDrag`
    : '/wda/clickAndDrag';
  const dest = destinationElementId && util.wrapElement(destinationElementId);
  return await this.wda.proxy.command(url, 'POST', {
    startX, startY,
    endX, endY,
    duration,
    dest,
    keyModifierFlags,
  });
};

/**
 * Perform long click, drag and hold gesture on an element or by absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {number} duration Long click duration in float seconds
 * @param {number} holdDuration Touch hold duration in float seconds
 * @param {string} [sourceElementId] Uuid of the element to start the drag from.
 *                 Either this property and `destinationElement` must be provided
 *                 or `startX`, `startY`, `endX`, `endY` coordinates must be set.
 * @param {string} [destinationElementId] Uuid of the element to end the drag on.
 *                 Either this property and `sourceElement` must be provided
 *                 or `startX`, `startY`, `endX`, `endY` coordinates must be set.
 * @param {number} [startX] Starting X coordinate
 * @param {number} [startY] Starting Y coordinate
 * @param {number} [endX] Ending X coordinate
 * @param {number} [endY] Ending Y coordinate
 * @param {number} [velocity] Dragging velocity in pixels per second.
 *                 If not provided then the default velocity is used. See
 *                 https://developer.apple.com/documentation/xctest/xcuigesturevelocity
 *                 for more details
 * @param {number} [keyModifierFlags] If set then the given key modifiers will be
 *                 applied while drag is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details */
export async function macosClickAndDragAndHold (
  duration,
  holdDuration,
  sourceElementId,
  destinationElementId,
  startX, startY,
  endX, endY,
  velocity,
  keyModifierFlags
) {
  requireSourceDestWithElementsOrCoordinates(
    sourceElementId, destinationElementId,
    startX, startY, endX, endY,
  );
  const url = sourceElementId && destinationElementId
    ? `/wda/element/${sourceElementId}/clickAndDragAndHold`
    : '/wda/clickAndDragAndHold';
  const dest = destinationElementId && util.wrapElement(destinationElementId);
  return await this.wda.proxy.command(url, 'POST', {
    startX, startY,
    endX, endY,
    duration, holdDuration,
    velocity,
    dest,
    keyModifierFlags,
  });
};

/**
 * Send keys to the given element or to the application under test
 *
 * @this {Mac2Driver}
 * @param {(import('../types').KeyOptions | string)[]} keys Array of keys to type.
 *                 Each item could either be a string, that represents a key itself (see
 *                 https://developer.apple.com/documentation/xctest/xcuielement/1500604-typekey
 *                 and https://developer.apple.com/documentation/xctest/xcuikeyboardkey)
 *                 or a dictionary, if the key should also be entered with modifiers.
 * @param {string} [elementId] Uuid of the element to send the keys to.
 *                 If unset then keys are sent to the current application
 *                 under test.
 */
export async function macosKeys (keys, elementId) {
  const url = elementId ? `/wda/element/${elementId}/keys` : '/wda/keys';
  return await this.wda.proxy.command(url, 'POST', { keys });
};

/**
 * Perform tap gesture on a Touch Bar element or by relative/absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {string} [elementId] Uuid of the Touch Bar element to tap. Either this property
 *                 or/and x and y must be set. If both are set then x and y are considered
 *                 as relative element coordinates. If only x and y are set then
 *                 these are parsed as absolute Touch Bar coordinates.
 * @param {number} [x] Tap X coordinate
 * @param {number} [y] Tap Y coordinate
 * @param {number} [keyModifierFlags] If set then the given key modifiers will be
 *                 applied while click is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosTap (elementId, x, y, keyModifierFlags) {
  requireElementIdOrXY(elementId, x, y);
  const url = elementId ? `/wda/element/${elementId}/tap` : '/wda/tap';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    keyModifierFlags,
  });
};

/**
 * Perform tap gesture on a Touch Bar element or by relative/absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {string} [elementId] Uuid of the Touch Bar element to tap. Either this property
   *               or/and x and y must be set. If both are set then x and y are considered
   *               as relative element coordinates. If only x and y are set then
   *               these are parsed as absolute Touch Bar coordinates.
 * @param {number} [x] Tap X coordinate
 * @param {number} [y] Tap Y coordinate
 * @param {number} [keyModifierFlags] If set then the given key modifiers will be
 *                 applied while click is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosDoubleTap (elementId, x, y, keyModifierFlags) {
  requireElementIdOrXY(elementId, x, y);
  const url = elementId ? `/wda/element/${elementId}/doubleTap` : '/wda/doubleTap';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    keyModifierFlags,
  });
};

/**
 * Perform press gesture on a Touch Bar element or by relative/absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {number} duration The number of float seconds to hold the mouse button
 * @param {string} [elementId] Uuid of the Touch Bar element to be pressed. Either this property
 *                 or/and x and y must be set. If both are set then x and y are considered
 *                 as relative element coordinates. If only x and y are set then these are
 *                 parsed as absolute Touch Bar coordinates.
 * @param {number} [x] Press X coordinate
 * @param {number} [y] Press Y coordinate
 * @param {number} [keyModifierFlags] If set then the given key modifiers will be
 *                 applied while click is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosPressAndHold (duration, elementId, x, y, keyModifierFlags) {
  const url = elementId ? `/wda/element/${elementId}/press` : '/wda/press';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    duration,
    keyModifierFlags,
  });
};

/**
 * Perform long press and drag gesture on a Touch Bar element or by absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {number} duration Long press duration in float seconds
 * @param {string} [sourceElementId] Uuid of a Touch Bar element to start the drag from.
 *                 Either this property and `destinationElement` must be provided or
 *                 `startX`, `startY`, `endX`, `endY` coordinates must be set.
 * @param {string} [destinationElementId] Uuid of a Touch Bar element to end the drag on.
 *                 Either this property and `sourceElement` must be provided or
 *                 `startX`, `startY`, `endX`, `endY` coordinates must be set.
 * @param {number} [startX] Starting X coordinate
 * @param {number} [startY] Starting Y coordinate
 * @param {number} [endX] Ending X coordinate
 * @param {number} [endY] Ending Y coordinate
 * @param {number} [keyModifierFlags] If set then the given key modifiers will be
 *                 applied while drag is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosPressAndDrag (
  duration,
  sourceElementId,
  destinationElementId,
  startX, startY,
  endX, endY,
  keyModifierFlags
) {
  // requireSourceDestWithElementsOrCoordinates(
  //   sourceElementId, destinationElementId,
  //   startX, startY, endX, endY,
  // );
  const url = sourceElementId && destinationElementId
    ? `/wda/element/${sourceElementId}/pressAndDrag`
    : '/wda/pressAndDrag';
  const dest = destinationElementId && util.wrapElement(destinationElementId);
  return await this.wda.proxy.command(url, 'POST', {
    startX, startY,
    endX, endY,
    duration,
    dest,
    keyModifierFlags,
  });
};

/**
 * Perform press, drag and hold gesture on a Touch Bar element or by absolute Touch Bar coordinates
 *
 * @this {Mac2Driver}
 * @param {number} duration Long press duration in float seconds
 * @param {number} holdDuration Touch hold duration in float seconds
 * @param {string} [sourceElementId] Uuid of a Touch Bar element to start the drag from.
 *                 Either this property and `destinationElement` must be provided or
 *                 `startX`, `startY`, `endX`, `endY` coordinates must be set.
 * @param {string} [destinationElementId] Uuid of a Touch Bar element to end the drag on.
 *                 Either this property and `sourceElement` must be provided or
 *                 `startX`, `startY`, `endX`, `endY` coordinates must be set.
 * @param {number} [startX] Starting X coordinate
 * @param {number} [startY] Starting Y coordinate
 * @param {number} [endX] Ending X coordinate
 * @param {number} [endY] Ending Y coordinate
 * @param {number} [velocity] Dragging velocity in pixels per second.
 *                 If not provided then the default velocity is used. See
 *                 https://developer.apple.com/documentation/xctest/xcuigesturevelocity
 *                 for more details
 * @param {number} [keyModifierFlags] If set then the given key modifiers will be
 *                 applied while drag is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosPressAndDragAndHold (
  duration,
  holdDuration,
  sourceElementId,
  destinationElementId,
  startX, startY,
  endX, endY,
  velocity,
  keyModifierFlags
) {
  requireSourceDestWithElementsOrCoordinates(
    sourceElementId, destinationElementId,
    startX, startY, endX, endY,
  );
  const url = sourceElementId && destinationElementId
    ? `/wda/element/${sourceElementId}/pressAndDragAndHold`
    : '/wda/pressAndDragAndHold';
  const dest = destinationElementId && util.wrapElement(destinationElementId);
  return await this.wda.proxy.command(url, 'POST', {
    startX, startY,
    endX, endY,
    duration, holdDuration,
    velocity,
    dest,
    keyModifierFlags,
  });
};

/**
 * Raise invalid argument error if element id was unset or x and y were unset.
 * @param {string} [elementId]
 * @param {number} [x]
 * @param {number} [y]
 * @returns {void}
 */
function requireElementIdOrXY (elementId, x, y) {
  if (!_.isString(elementId) && !(_.isNumber(x) && _.isNumber(y))) {
    throw new errors.InvalidArgumentError(`'elementId' or 'x' and 'y' is required.`);
  }
}

/**
 * Raise invalid argument error if sourceElementId and destinationElementId were unset
 * or startX, startY, endX and endY were unset.
 * @param {string} [sourceElementId]
 * @param {string} [destinationElementId]
 * @param {number} [startX]
 * @param {number} [startY]
 * @param {number} [endX]
 * @param {number} [endY]
 * @returns {void}
 */
function requireSourceDestWithElementsOrCoordinates (
  sourceElementId, destinationElementId,
  startX, startY, endX, endY
) {
  if (
    !(_.isString(sourceElementId) && _.isString(destinationElementId))
    && !(_.isNumber(startX) && _.isNumber(startY) && _.isNumber(endX) && _.isNumber(endY))
  ) {
    throw new errors.InvalidArgumentError(`'sourceElementId' and 'destinationElementId' ` +
      `or 'startX', 'startY', 'endX' and 'endY' are required.`);
  }
}

/**
 * @typedef {import('../driver').Mac2Driver} Mac2Driver
 */
