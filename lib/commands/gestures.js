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
 *
 * @param {import('@appium/types').StringRecord} [options={}]
 * @param {string[]} [keyNames]
 * @returns {string|null}
 */
function requireUuid (options = {}, keyNames = ['elementId', 'element']) {
  const result = extractUuid(options, keyNames);
  if (!result) {
    throw new errors.InvalidArgumentError(`${keyNames[0]} field is mandatory`);
  }
  return result;
}

/**
 * Set value to the given element
 *
 * @this {Mac2Driver}
 * @param {import('../types').SetValueOptions} opts
 */
export async function macosSetValue (opts) {
  const uuid = requireUuid(opts);
  const { value, text, keyModifierFlags } = opts ?? {};
  return await this.wda.proxy.command(`/element/${uuid}/value`, 'POST', {
    value, text,
    keyModifierFlags,
  });
};

/**
 * Perform click gesture on an element or by relative/absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {import('../types').ClickOptions} opts
 */
export async function macosClick (opts = {}) {
  const uuid = extractUuid(opts);
  const { x, y, keyModifierFlags } = opts;
  const url = uuid ? `/element/${uuid}/click` : '/wda/click';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    keyModifierFlags,
  });
};

/**
 * Perform scroll gesture on an element or by relative/absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {import('../types').ScrollOptions} opts
 */
export async function macosScroll (opts = {}) {
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
 * Perform swipe gesture on an element
 *
 * @this {Mac2Driver}
 * @param {import('../types').SwipeOptions} opts
 */
export async function macosSwipe (opts) {
  const uuid = extractUuid(opts);
  const {
    x, y,
    direction,
    velocity,
    keyModifierFlags,
  } = opts ?? {};
  const url = uuid ? `/wda/element/${uuid}/swipe` : `/wda/swipe`;
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
 * @param {import('../types').RightClickOptions} opts
 */
export async function macosRightClick (opts = {}) {
  const uuid = extractUuid(opts);
  const { x, y, keyModifierFlags } = opts;
  const url = uuid ? `/wda/element/${uuid}/rightClick` : '/wda/rightClick';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    keyModifierFlags,
  });
};

/**
 * Perform hover gesture on an element or by relative/absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {import('../types').HoverOptions} opts
 */
export async function macosHover (opts = {}) {
  const uuid = extractUuid(opts);
  const { x, y, keyModifierFlags } = opts;
  const url = uuid ? `/wda/element/${uuid}/hover` : '/wda/hover';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    keyModifierFlags,
  });
};

/**
 * Perform double click gesture on an element or by relative/absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {import('../types').DoubleClickOptions} opts
 */
export async function macosDoubleClick (opts = {}) {
  const uuid = extractUuid(opts);
  const { x, y, keyModifierFlags } = opts;
  const url = uuid ? `/wda/element/${uuid}/doubleClick` : '/wda/doubleClick';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    keyModifierFlags,
  });
};

/**
 * Perform long click and drag gesture on an element or by absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {import('../types').ClickAndDragOptions} opts
 */
export async function macosClickAndDrag (opts) {
  const sourceUuid = extractUuid(opts, ['sourceElementId', 'sourceElement']);
  const destUuid = extractUuid(opts, ['destinationElementId', 'destinationElement']);
  const {
    startX, startY,
    endX, endY,
    duration,
    keyModifierFlags
  } = opts ?? {};
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
 * Perform long click, drag and hold gesture on an element or by absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {import('../types').ClickAndDragAndHoldOptions} opts
 */
export async function macosClickAndDragAndHold (opts) {
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
 * Send keys to the given element or to the application under test
 *
 * @this {Mac2Driver}
 * @param {import('../types').KeysOptions} opts
 */
export async function macosKeys (opts) {
  const uuid = extractUuid(opts);
  const { keys } = opts ?? {};
  const url = uuid ? `/wda/element/${uuid}/keys` : '/wda/keys';
  return await this.wda.proxy.command(url, 'POST', { keys });
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
 * Perform tap gesture on a Touch Bar element or by relative/absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {import('../types').TapOptions} opts
 */
export async function macosTap (opts = {}) {
  const uuid = extractUuid(opts);
  const { x, y, keyModifierFlags } = opts ?? {};
  const url = uuid ? `/wda/element/${uuid}/tap` : '/wda/tap';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
    keyModifierFlags,
  });
};

/**
 * Perform tap gesture on a Touch Bar element or by relative/absolute coordinates
 *
 * @this {Mac2Driver}
 * @param {import('../types').DoubleTapOptions} opts
 */
export async function macosDoubleTap (opts = {}) {
  const uuid = extractUuid(opts);
  const { x, y, keyModifierFlags } = opts;
  const url = uuid ? `/wda/element/${uuid}/doubleTap` : '/wda/doubleTap';
  return await this.wda.proxy.command(url, 'POST', {
    x, y,
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
