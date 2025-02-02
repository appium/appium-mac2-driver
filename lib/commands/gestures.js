import { util } from 'appium/support';
import { errors } from 'appium/driver';

/**
 *
 * @param {import('@appium/types').StringRecord} [options={}]
 * @param {string[]} [keyNames]
 * @returns {string|null}
 */
function extractUuid (options = {}, keyNames = ['elementId', 'element']) {
  for (const name of keyNames) {
    if (options[name]) {
      const result = util.unwrapElement(options[name]);
      if (result) {
        return result;
      }
    }
  }
  return null;
}

/**
 * Set value to the given element
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
 * Raise invalid argument error if element id was unset or x and y were unset.
 * @returns
 */
function requireElementIdOrXY (elementId, x, y) {
  if (!!elementId || (!!x && !!y)) {
    return;
  }
  throw new errors.InvalidArgumentError(`'elementId' or 'x' and 'y' is required.`);
}

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
 * @param {string} [elementId] Uuid of the element to be scrolled. Either this property
 *                 or/and x and y must be set. If both are set then x and y are
 *                 considered as relative element coordinates. If only x and y are
 *                 set then these are parsed as absolute coordinates.
 * @param {number} [x] Scroll X coordinate
 * @param {number} [y] Scroll Y coordinate
 * @param {number} [deltaX] Horizontal delta as float number
 * @param {number} [deltaY] Vertical delta as float number
 * @param {number} [keyModifierFlags] If set then the given key modifiers will be
 *                 applied while scroll is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosScroll (
  elementId,
  x, y,
  deltaX, deltaY,
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
 * @param {string} [elementId] Uuid of the element to be swiped. Either this property
 *                 or/and x and y must be set. If both are set then x and y are
 *                 considered as relative element coordinates. If only x and y are
 *                 set then these are parsed as absolute coordinates.
 * @param {number} [x] Swipe X coordinate
 * @param {number} [y] Swipe Y coordinate
 * @param {'up'|'down'|'left'|'right'} [direction] Swipe direction
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
  elementId,
  x, y,
  direction,
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
 * @param {number} [duration] Long click duration in float seconds
 * @param {number} [keyModifierFlags] If set then the given key modifiers will be
 *                 applied while drag is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details
 */
export async function macosClickAndDrag (
  sourceElementId,
  destinationElementId,
  startX, startY,
  endX, endY,
  duration,
  keyModifierFlags
) {
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
 * @param {number} [duration] Long click duration in float seconds
 * @param {number} [holdDuration] Touch hold duration in float seconds
 * @param {number} [velocity] Dragging velocity in pixels per second.
 *                 If not provided then the default velocity is used. See
 *                 https://developer.apple.com/documentation/xctest/xcuigesturevelocity
 *                 for more details
 * @param {number} [keyModifierFlags] If set then the given key modifiers will be
 *                 applied while drag is performed. See
 *                 https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 *                 for more details */
export async function macosClickAndDragAndHold (
  sourceElementId,
  destinationElementId,
  startX, startY,
  endX, endY,
  duration,
  holdDuration,
  velocity,
  keyModifierFlags
) {
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
 * @param {import('../types').PressOptions} opts
 */
export async function macosPressAndHold (opts) {
  const uuid = extractUuid(opts);
  const { x, y, duration, keyModifierFlags } = opts ?? {};
  const url = uuid ? `/wda/element/${uuid}/press` : '/wda/press';
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
 * @param {import('../types').PressAndDragOptions} opts
 */
export async function macosPressAndDrag (opts) {
  const sourceUuid = extractUuid(opts, ['sourceElementId', 'sourceElement']);
  const destUuid = extractUuid(opts, ['destinationElementId', 'destinationElement']);
  const {
    startX, startY,
    endX, endY,
    duration,
    keyModifierFlags
  } = opts ?? {};
  const url = sourceUuid && destUuid
    ? `/wda/element/${sourceUuid}/pressAndDrag`
    : '/wda/pressAndDrag';
  const dest = destUuid && util.wrapElement(destUuid);
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
 * @param {import('../types').PressAndDragAndHoldOptions} opts
 */
export async function macosPressAndDragAndHold (opts) {
  const sourceUuid = extractUuid(opts, ['sourceElementId', 'sourceElement']);
  const destUuid = extractUuid(opts, ['destinationElementId', 'destinationElement']);
  const {
    startX, startY,
    endX, endY,
    duration, holdDuration,
    velocity,
    keyModifierFlags
  } = opts ?? {};
  const url = sourceUuid && destUuid
    ? `/wda/element/${sourceUuid}/pressAndDragAndHold`
    : '/wda/pressAndDragAndHold';
  const dest = destUuid && util.wrapElement(destUuid);
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
 * @typedef {import('../driver').Mac2Driver} Mac2Driver
 */
