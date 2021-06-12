import { util } from 'appium-support';
import { errors } from 'appium-base-driver';

const commands = {};

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

function requireUuid (options = {}, keyNames = ['elementId', 'element']) {
  const result = extractUuid(options, keyNames);
  if (!result) {
    throw new errors.InvalidArgumentError(`${keyNames[0]} field is mandatory`);
  }
  return result;
}


/**
 * @typedef {Object} SetValueOptions
 * @property {!string} elementId uuid of the element to set value for
 * @property {*} value value to set. Could also be an array
 * @property {string} text text to set. If both value and text are set
 * then `value` is preferred
 * @property {?number} keyModifierFlags if set then the given key modifiers will be
 * applied while the element value is being set. See
 * https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 * for more details
 */

/**
 * Set value to the given element
 *
 * @param {SetValueOptions} opts
 */
commands.macosSetValue = async function macosSetValue (opts = {}) {
  const uuid = requireUuid(opts);
  const { value, text, keyModifierFlags } = opts;
  return await this.wda.proxy.command(`/element/${uuid}/value`, 'POST', {
    value, text,
    keyModifierFlags,
  });
};

/**
 * @typedef {Object} ClickOptions
 * @property {?string} elementId uuid of the element to click. Either this property
 * or/and x and y must be set. If both are set then x and y are considered as relative
 * element coordinates. If only x and y are set then these are parsed as
 * absolute coordinates.
 * @property {?number} x click X coordinate
 * @property {?number} y click Y coordinate
 * @property {?number} keyModifierFlags if set then the given key modifiers will be
 * applied while click is performed. See
 * https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 * for more details
 */

/**
 * Perform click gesture on an element or by relative/absolute coordinates
 *
 * @param {ClickOptions} opts
 */
commands.macosClick = async function macosClick (opts = {}) {
  const uuid = extractUuid(opts);
  const { x, y, keyModifierFlags } = opts;
  const url = uuid ? `/element/${uuid}/click` : '/wda/click';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    keyModifierFlags,
  });
};

/**
 * @typedef {Object} ScrollOptions
 * @property {?string} elementId uuid of the element to be scrolled. Either this property
 * or/and x and y must be set. If both are set then x and y are considered as relative
 * element coordinates. If only x and y are set then these are parsed as
 * absolute coordinates.
 * @property {?number} x scroll X coordinate
 * @property {?number} y scroll Y coordinate
 * @property {!number} deltaX horizontal delta as float number
 * @property {!number} deltaY vertical delta as float number
 * @property {?number} keyModifierFlags if set then the given key modifiers will be
 * applied while scroll is performed. See
 * https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 * for more details
 */

/**
 * Perform scroll gesture on an element or by relative/absolute coordinates
 *
 * @param {ScrollOptions} opts
 */
commands.macosScroll = async function macosScroll (opts = {}) {
  const uuid = extractUuid(opts);
  const {
    x, y,
    deltaX, deltaY,
    keyModifierFlags,
  } = opts;
  const url = uuid ? `/wda/element/${uuid}/scroll` : '/wda/scroll';
  return await this.wda.proxy.command(url, 'POST', {
    deltaX, deltaY,
    x, y,
    keyModifierFlags,
  });
};

/**
 * @typedef {Object} SwipeOptions
 * @property {?string} elementId uuid of the element to be swiped. Either this property
 * or/and x and y must be set. If both are set then x and y are considered as relative
 * element coordinates. If only x and y are set then these are parsed as
 * absolute coordinates.
 * @property {?number} x swipe X coordinate
 * @property {?number} y swipe Y coordinate
 * @property {!string} direction either 'up', 'down', 'left' or 'right'
 * @property {?number} velocity The value is measured in pixels per second and same
 * values could behave differently on different devices depending on their display
 * density. Higher values make swipe gesture faster (which usually scrolls larger
 * areas if we apply it to a list) and lower values slow it down.
 * Only values greater than zero have effect.
 * @property {?number} keyModifierFlags if set then the given key modifiers will be
 * applied while scroll is performed. See
 * https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 * for more details
 */

/**
 * Perform swipe gesture on an element
 *
 * @param {SwipeOptions} opts
 */
commands.macosSwipe = async function macosSwipe (opts = {}) {
  const uuid = extractUuid(opts);
  const {
    x, y,
    direction,
    velocity,
    keyModifierFlags,
  } = opts;
  const url = uuid ? `/wda/element/${uuid}/swipe` : `/wda/swipe`;
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    direction,
    velocity,
    keyModifierFlags,
  });
};

/**
 * @typedef {Object} RightClickOptions
 * @property {?string} elementId uuid of the element to click. Either this property
 * or/and x and y must be set. If both are set then x and y are considered as relative
 * element coordinates. If only x and y are set then these are parsed as
 * absolute coordinates.
 * @property {?number} x click X coordinate
 * @property {?number} y click Y coordinate
 * @property {?number} keyModifierFlags if set then the given key modifiers will be
 * applied while click is performed. See
 * https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 * for more details
 */

/**
 * Perform right click gesture on an element or by relative/absolute coordinates
 *
 * @param {RightClickOptions} opts
 */
commands.macosRightClick = async function macosRightClick (opts = {}) {
  const uuid = extractUuid(opts);
  const { x, y, keyModifierFlags } = opts;
  const url = uuid ? `/wda/element/${uuid}/rightClick` : '/wda/rightClick';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    keyModifierFlags,
  });
};

/**
 * @typedef {Object} HoverOptions
 * @property {?string} elementId uuid of the element to hover. Either this property
 * or/and x and y must be set. If both are set then x and y are considered as relative
 * element coordinates. If only x and y are set then these are parsed as
 * absolute coordinates.
 * @property {?number} x click X coordinate
 * @property {?number} y click Y coordinate
 * @property {?number} keyModifierFlags if set then the given key modifiers will be
 * applied while hover is performed. See
 * https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 * for more details
 */

/**
 * Perform hover gesture on an element or by relative/absolute coordinates
 *
 * @param {HoverOptions} opts
 */
commands.macosHover = async function macosHover (opts = {}) {
  const uuid = extractUuid(opts);
  const { x, y, keyModifierFlags } = opts;
  const url = uuid ? `/wda/element/${uuid}/hover` : '/wda/hover';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    keyModifierFlags,
  });
};

/**
 * @typedef {Object} DoubleClickOptions
 * @property {?string} elementId uuid of the element to double click. Either this property
 * or/and x and y must be set. If both are set then x and y are considered as relative
 * element coordinates. If only x and y are set then these are parsed as
 * absolute coordinates.
 * @property {?number} x click X coordinate
 * @property {?number} y click Y coordinate
 * @property {?number} keyModifierFlags if set then the given key modifiers will be
 * applied while double click is performed. See
 * https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 * for more details
 */

/**
 * Perform double click gesture on an element or by relative/absolute coordinates
 *
 * @param {DoubleClickOptions} opts
 */
commands.macosDoubleClick = async function macosDoubleClick (opts = {}) {
  const uuid = extractUuid(opts);
  const { x, y, keyModifierFlags } = opts;
  const url = uuid ? `/wda/element/${uuid}/doubleClick` : '/wda/doubleClick';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    keyModifierFlags,
  });
};

/**
 * @typedef {Object} ClickAndDragOptions
 * @property {?string} sourceElementId uuid of the element to start the drag from. Either this property
 * and `destinationElement` must be provided or `startX`, `startY`, `endX`, `endY` coordinates
 * must be set.
 * @property {?string} destinationElementId uuid of the element to end the drag on. Either this property
 * and `sourceElement` must be provided or `startX`, `startY`, `endX`, `endY` coordinates
 * must be set.
 * @property {?number} startX starting X coordinate
 * @property {?number} startY starting Y coordinate
 * @property {?number} endX ending X coordinate
 * @property {?number} endY ending Y coordinate
 * @property {!number} duration long click duration in float seconds
 * @property {?number} keyModifierFlags if set then the given key modifiers will be
 * applied while drag is performed. See
 * https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 * for more details
 */

/**
 * Perform long click and drag gesture on an element or by absolute coordinates
 *
 * @param {ClickAndDragOptions} opts
 */
commands.macosClickAndDrag = async function macosClickAndDrag (opts = {}) {
  const sourceUuid = extractUuid(opts, ['sourceElementId', 'sourceElement']);
  const destUuid = extractUuid(opts, ['destinationElementId', 'destinationElement']);
  const {
    startX, startY,
    endX, endY,
    duration,
    keyModifierFlags
  } = opts;
  const url = sourceUuid && destUuid
    ? `/wda/element/${sourceUuid}/clickAndDrag`
    : '/wda/clickAndDrag';
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
 * @typedef {Object} ClickAndDragAndHoldOptions
 * @property {?string} sourceElementId uuid of the element to start the drag from. Either this property
 * and `destinationElement` must be provided or `startX`, `startY`, `endX`, `endY` coordinates
 * must be set.
 * @property {?string} destinationElementId uuid of the element to end the drag on. Either this property
 * and `sourceElement` must be provided or `startX`, `startY`, `endX`, `endY` coordinates
 * must be set.
 * @property {?number} startX starting X coordinate
 * @property {?number} startY starting Y coordinate
 * @property {?number} endX ending X coordinate
 * @property {?number} endY ending Y coordinate
 * @property {!number} duration long click duration in float seconds
 * @property {?number} velocity dragging velocity in pixels per second.
 * If not provided then the default velocity is used. See
 * https://developer.apple.com/documentation/xctest/xcuigesturevelocity
 * for more details
 * @property {?number} keyModifierFlags if set then the given key modifiers will be
 * applied while drag is performed. See
 * https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 * for more details
 */

/**
 * Perform long click, drag and hold gesture on an element or by absolute coordinates
 *
 * @param {ClickAndDragAndHoldOptions} opts
 */
commands.macosClickAndDragAndHold = async function macosClickAndDragAndHold (opts = {}) {
  const sourceUuid = extractUuid(opts, ['sourceElementId', 'sourceElement']);
  const destUuid = extractUuid(opts, ['destinationElementId', 'destinationElement']);
  const {
    startX, startY,
    endX, endY,
    duration, holdDuration,
    velocity,
    keyModifierFlags
  } = opts;
  const url = sourceUuid && destUuid
    ? `/wda/element/${sourceUuid}/clickAndDragAndHold`
    : '/wda/clickAndDragAndHold';
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
 * @typedef {Object} KeyOptions
 * @property {!string} key a string, that represents a key to type (see
 * https://developer.apple.com/documentation/xctest/xcuielement/1500604-typekey?language=objc
 * and https://developer.apple.com/documentation/xctest/xcuikeyboardkey?language=objc)
 * @property {?number} modifierFlags a set of modifier flags
 * (https://developer.apple.com/documentation/xctest/xcuikeymodifierflags?language=objc)
 * to use when typing the key.
 */

/**
 * @typedef {Object} KeysOptions
 * @property {?string} elementId uuid of the element to send keys to.
 * If the element is not provided then the keys will be sent to the current application.
 * @property {!Array<KeyOptions|string>} keys Array of keys to type.
 * Each item could either be a string, that represents a key itself (see
 * https://developer.apple.com/documentation/xctest/xcuielement/1500604-typekey?language=objc
 * and https://developer.apple.com/documentation/xctest/xcuikeyboardkey?language=objc)
 * or a dictionary, if the key should also be entered with modifiers.
 */

/**
 * Send keys to the given element or to the application under test
 *
 * @param {KeysOptions} opts
 */
commands.macosKeys = async function macosKeys (opts = {}) {
  const uuid = extractUuid(opts);
  const { keys } = opts;
  const url = uuid ? `/wda/element/${uuid}/keys` : '/wda/keys';
  return await this.wda.proxy.command(url, 'POST', { keys });
};

/**
 * @typedef {Object} PressOptions
 * @property {?string} elementId uuid of the Touch Bar element to be pressed. Either this property
 * or/and x and y must be set. If both are set then x and y are considered as relative
 * element coordinates. If only x and y are set then these are parsed as
 * absolute Touch Bar coordinates.
 * @property {?number} x long click X coordinate
 * @property {?number} y long click Y coordinate
 * @property {!number} duration the number of float seconds to hold the mouse button
 * @property {?number} keyModifierFlags if set then the given key modifiers will be
 * applied while click is performed. See
 * https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 * for more details
 */

/**
 * Perform press gesture on a Touch Bar element or by relative/absolute coordinates
 *
 * @param {PressOptions} opts
 */
commands.macosPressAndHold = async function macosPressAndHold (opts = {}) {
  const uuid = extractUuid(opts);
  const { x, y, duration, keyModifierFlags } = opts;
  const url = uuid ? `/wda/element/${uuid}/press` : '/wda/press';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    duration,
    keyModifierFlags,
  });
};

/**
 * @typedef {Object} TapOptions
 * @property {?string} elementId uuid of the Touch Bar element to tap. Either this property
 * or/and x and y must be set. If both are set then x and y are considered as relative
 * element coordinates. If only x and y are set then these are parsed as
 * absolute Touch Bar coordinates.
 * @property {?number} x click X coordinate
 * @property {?number} y click Y coordinate
 * @property {?number} keyModifierFlags if set then the given key modifiers will be
 * applied while click is performed. See
 * https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 * for more details
 */

/**
 * Perform tap gesture on a Touch Bar element or by relative/absolute coordinates
 *
 * @param {TapOptions} opts
 */
commands.macosTap = async function macosTap (opts = {}) {
  const uuid = extractUuid(opts);
  const { x, y, keyModifierFlags } = opts;
  const url = uuid ? `/wda/element/${uuid}/tap` : '/wda/tap';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    keyModifierFlags,
  });
};

/**
 * @typedef {Object} DoubleTapOptions
 * @property {?string} elementId uuid of the Touch Bar element to tap. Either this property
 * or/and x and y must be set. If both are set then x and y are considered as relative
 * element coordinates. If only x and y are set then these are parsed as
 * absolute Touch Bar coordinates.
 * @property {?number} x click X coordinate
 * @property {?number} y click Y coordinate
 * @property {?number} keyModifierFlags if set then the given key modifiers will be
 * applied while click is performed. See
 * https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 * for more details
 */

/**
 * Perform tap gesture on a Touch Bar element or by relative/absolute coordinates
 *
 * @param {DoubleTapOptions} opts
 */
commands.macosDoubleTap = async function macosDoubleTap (opts = {}) {
  const uuid = extractUuid(opts);
  const { x, y, keyModifierFlags } = opts;
  const url = uuid ? `/wda/element/${uuid}/doubleTap` : '/wda/doubleTap';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    keyModifierFlags,
  });
};

/**
 * @typedef {Object} PressAndDragOptions
 * @property {?string} sourceElementId uuid of a Touch Bar element to start the drag from. Either this property
 * and `destinationElement` must be provided or `startX`, `startY`, `endX`, `endY` coordinates
 * must be set.
 * @property {?string} destinationElementId uuid of a Touch Bar element to end the drag on. Either this property
 * and `sourceElement` must be provided or `startX`, `startY`, `endX`, `endY` coordinates
 * must be set.
 * @property {?number} startX starting X coordinate
 * @property {?number} startY starting Y coordinate
 * @property {?number} endX ending X coordinate
 * @property {?number} endY ending Y coordinate
 * @property {!number} duration long click duration in float seconds
 * @property {?number} keyModifierFlags if set then the given key modifiers will be
 * applied while drag is performed. See
 * https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 * for more details
 */

/**
 * Perform long press and drag gesture on a Touch Bar element or by absolute coordinates
 *
 * @param {PressAndDragOptions} opts
 */
commands.macosPressAndDrag = async function macosPressAndDrag (opts = {}) {
  const sourceUuid = extractUuid(opts, ['sourceElementId', 'sourceElement']);
  const destUuid = extractUuid(opts, ['destinationElementId', 'destinationElement']);
  const {
    startX, startY,
    endX, endY,
    duration,
    keyModifierFlags
  } = opts;
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
 * @typedef {Object} PressAndDragAndHoldOptions
 * @property {?string} sourceElementId uuid of a Touch Bar element to start the drag from. Either this property
 * and `destinationElement` must be provided or `startX`, `startY`, `endX`, `endY` coordinates
 * must be set.
 * @property {?string} destinationElementId uuid of a Touch Bar element to end the drag on. Either this property
 * and `sourceElement` must be provided or `startX`, `startY`, `endX`, `endY` coordinates
 * must be set.
 * @property {?number} startX starting X coordinate
 * @property {?number} startY starting Y coordinate
 * @property {?number} endX ending X coordinate
 * @property {?number} endY ending Y coordinate
 * @property {!number} duration long click duration in float seconds
 * @property {?number} velocity dragging velocity in pixels per second.
 * If not provided then the default velocity is used. See
 * https://developer.apple.com/documentation/xctest/xcuigesturevelocity
 * for more details
 * @property {?number} keyModifierFlags if set then the given key modifiers will be
 * applied while drag is performed. See
 * https://developer.apple.com/documentation/xctest/xcuikeymodifierflags
 * for more details
 */

/**
 * Perform press, drag and hold gesture on a Touch Bar element or by absolute Touch Bar coordinates
 *
 * @param {PressAndDragAndHoldOptions} opts
 */
commands.macosPressAndDragAndHold = async function macosPressAndDragAndHold (opts = {}) {
  const sourceUuid = extractUuid(opts, ['sourceElementId', 'sourceElement']);
  const destUuid = extractUuid(opts, ['destinationElementId', 'destinationElement']);
  const {
    startX, startY,
    endX, endY,
    duration, holdDuration,
    velocity,
    keyModifierFlags
  } = opts;
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

export default commands;
