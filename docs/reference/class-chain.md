---
title: Class Chain Locator Strategy
---

The Mac2 driver supports searching elements using the _class chain_
[locator search strategy](./locator-strategies.md#class-chain) (`class chain`, or `-ios class chain`
in the clients that only know this name). It is very similar to a simplified XPath, but is much
faster, because the lookup does not need the page source of the whole application. It is a layer
over the native [XCUIElementQuery](https://developer.apple.com/documentation/xctest/xcuielementquery)
lookup calls with some additional features, like positions in the intermediate steps and negative
positions counted from the end. A class chain is a `/`-separated list of _steps_. Each step selects
elements of a certain type, optionally narrowed down by predicates and a position, relative to the
elements matched by the previous step.

!!! tip

    Use [predicate string](./predicate.md) locators for elements that can be identified only by
    their own attributes. Class chain is the right choice when the element can be found only
    in relation to other elements, like its parent, descendants or siblings.

## Quick Examples

=== "Class Chain"

    ```java
    // java
    driver.findElement(AppiumBy.iOSClassChain(
        "**/XCUIElementTypeWindow/XCUIElementTypeButton[`identifier BEGINSWITH '_XCUI:'`][2]"));
    ```

=== "XPath"

    ```java
    // java
    driver.findElement(AppiumBy.xpath(
        "(//XCUIElementTypeWindow/XCUIElementTypeButton[starts-with(@identifier, '_XCUI:')])[2]"));
    ```

Both examples select the second button among the direct children of all windows, whose identifier
starts with `_XCUI:`.

## Steps

Every step starts with an element type, which is one of the `XCUIElementType*` names
(see the [`XCUIElementType` documentation](https://developer.apple.com/documentation/xcuiautomation/xcuielement/elementtype)),
or `*` for any type (same as `XCUIElementTypeAny`).

### Children and Descendants

Steps are separated by `/`, and select direct children of the elements matched by the previous step.
Use `**/` to select all descendants instead. The first step is relative to the element the search
is made from, which is the application if the search is made on the driver.

|Class chain|Selects|XPath alternative|
|---|---|---|
|`XCUIElementTypeWindow/XCUIElementTypeButton`|buttons, which are children of windows, which are children of the application|`/*/XCUIElementTypeWindow/XCUIElementTypeButton`|
|`**/XCUIElementTypeButton`|all buttons in the application|`//XCUIElementTypeButton`|
|`**/XCUIElementTypeGroup/**/XCUIElementTypeButton`|all buttons inside of groups, at any depth|`//XCUIElementTypeGroup//XCUIElementTypeButton`|

### Positions

A position in square brackets selects a single element among the matches of the entire preceding
chain, not per matched element of the previous step, like for XPath. Positions start with `1`.
A negative position counts from the end: `-1` is the last match. Avoid positions in the
intermediate steps if possible, because they make the lookup slower.

|Class chain|Selects|XPath alternative|
|---|---|---|
|`**/XCUIElementTypeWindow[2]`|the second window|`(//XCUIElementTypeWindow)[2]`|
|`**/XCUIElementTypeWindow[-1]`|the last window|`(//XCUIElementTypeWindow)[last()]`|
|`**/XCUIElementTypeGroup/XCUIElementTypeButton[2]`|the second button among the children of all groups|`(//XCUIElementTypeGroup/XCUIElementTypeButton)[2]`|
|`XCUIElementTypeWindow[2]/*[-2]`|the second last child of the second window|`/*/XCUIElementTypeWindow[2]/*[last() - 1]`|

### Predicates

Predicates restrict the elements of a step. They are put into square brackets before the position,
and every predicate is a [predicate expression](./predicate.md) using
the [element attributes](./element-attributes.md):

- ``[`predicate`]`` - the predicate is applied to the matched elements themselves. It is the direct
  alternative of the native [matchingPredicate:](https://developer.apple.com/documentation/xctest/xcuielementquery/1500471-matchingpredicate?language=objc) selector
- `[$predicate$]` - the predicate is applied to all _descendants_ of the matched elements;
  an element is selected if at least one of its descendants satisfies the predicate. It is the direct
  alternative of the native [containingPredicate:](https://developer.apple.com/documentation/xctest/xcuielementquery/1500956-containingpredicate?language=objc) selector

Only the marker enclosing the predicate has to be escaped inside of it by doubling: a backtick
in ``[`...`]`` or a dollar sign in `[$...$]`, for example `[$identifier == 'a$$b'$]`.
Predicates are always put before the position, never after it. Several predicates are applied
one after another, in the given order. A predicate must not be empty, and its text is never used
as a format string, so it must not contain format specifiers like `%@`.

|Class chain|Selects|XPath alternative|
|---|---|---|
|``**/XCUIElementTypeButton[`identifier == 'OK'`]``|buttons with the identifier `OK`|`//XCUIElementTypeButton[@identifier='OK']`|
|``**/XCUIElementTypeButton[`enabled == 1 AND label CONTAINS 'done'`]``|enabled buttons with `done` in the label|`//XCUIElementTypeButton[@enabled='true' and contains(@label, 'done')]`|
|``**/XCUIElementTypeGroup[$amType == 'XCUIElementTypeImage' AND identifier == 'bla'$]``|groups, which contain an image with the identifier `bla`|`//XCUIElementTypeGroup[.//XCUIElementTypeImage[@identifier='bla']]`|
|``**/XCUIElementTypeButton[`identifier BEGINSWITH 'A'`][-1]``|the last button, whose identifier starts with `A`|`(//XCUIElementTypeButton[starts-with(@identifier, 'A')])[last()]`|

## Axis Steps

Axis steps select elements relative to the elements matched by the previous step in a direction
other than "down". They replace the XPath axes, which are the most common reason to use the
much slower XPath strategy.

|Step|Selects|XPath alternative|
|---|---|---|
|`..`|the parent|`..` or `parent::*`|
|`^XCUIElementTypeWindow`|all ancestors of the given type|`ancestor::XCUIElementTypeWindow`|
|`>XCUIElementTypeButton`|all following siblings of the given type|`following-sibling::XCUIElementTypeButton`|
|`<XCUIElementTypeButton`|all preceding siblings of the given type|`preceding-sibling::XCUIElementTypeButton`|
|`~XCUIElementTypeButton`|all siblings of the given type, except the matched element itself|`preceding-sibling::XCUIElementTypeButton | following-sibling::XCUIElementTypeButton`|

Axis steps accept `*`, predicates and positions, the same way as regular steps. `..` is the
exception: it has neither a type nor a position, but may have predicates.

### Examples

The button right before the "OK" button:

=== "Class Chain"

    ```java
    // java
    driver.findElement(AppiumBy.iOSClassChain(
        "**/XCUIElementTypeButton[`identifier == 'OK'`]/<XCUIElementTypeButton[1]"));
    ```

=== "XPath"

    ```java
    // java
    driver.findElement(AppiumBy.xpath(
        "//XCUIElementTypeButton[@identifier='OK']/preceding-sibling::XCUIElementTypeButton[1]"));
    ```

The window containing the "OK" button:

=== "Class Chain"

    ```java
    // java
    driver.findElement(AppiumBy.iOSClassChain(
        "**/XCUIElementTypeButton[`identifier == 'OK'`]/^XCUIElementTypeWindow"));
    ```

=== "XPath"

    ```java
    // java
    driver.findElement(AppiumBy.xpath(
        "//XCUIElementTypeButton[@identifier='OK']/ancestor::XCUIElementTypeWindow"));
    ```

All buttons next to the "OK" button, which are children of the same parent:

=== "Class Chain"

    ```java
    // java
    driver.findElements(AppiumBy.iOSClassChain(
        "**/XCUIElementTypeButton[`identifier == 'OK'`]/~XCUIElementTypeButton"));
    ```

=== "XPath"

    ```java
    // java
    driver.findElements(AppiumBy.xpath(
        "//XCUIElementTypeButton[@identifier='OK']/preceding-sibling::XCUIElementTypeButton"
        + " | //XCUIElementTypeButton[@identifier='OK']/following-sibling::XCUIElementTypeButton"));
    ```

The text field, which is next to the label "Email", found through the parent:

=== "Class Chain"

    ```java
    // java
    driver.findElement(AppiumBy.iOSClassChain(
        "**/XCUIElementTypeStaticText[`label == 'Email'`]/../XCUIElementTypeTextField"));
    ```

=== "XPath"

    ```java
    // java
    driver.findElement(AppiumBy.xpath(
        "//XCUIElementTypeStaticText[@label='Email']/../XCUIElementTypeTextField"));
    ```

The window containing the "OK" button, using a predicate on the parent:

=== "Class Chain"

    ```java
    // java
    driver.findElement(AppiumBy.iOSClassChain(
        "**/XCUIElementTypeButton[`identifier == 'OK'`]/..[`amType == 'XCUIElementTypeSheet'`]"));
    ```

=== "XPath"

    ```java
    // java
    driver.findElement(AppiumBy.xpath(
        "//XCUIElementTypeButton[@identifier='OK']/parent::XCUIElementTypeSheet"));
    ```

### Positions on Axes

Positions count along the axis, as they do for XPath axes: from the nearest element for `^`
and `<`, in document order for `>` and `~`, and from the other end if negative.

|Class chain|Selects|XPath alternative|
|---|---|---|
|`^XCUIElementTypeGroup[1]`|the closest ancestor of the type|`ancestor::XCUIElementTypeGroup[1]`|
|`^*[-1]`|the outermost ancestor, which is the application|`ancestor::*[last()]`|
|`<XCUIElementTypeButton[1]`|the closest preceding button|`preceding-sibling::XCUIElementTypeButton[1]`|
|`>XCUIElementTypeButton[-1]`|the last following button|`following-sibling::XCUIElementTypeButton[last()]`|

### Rules

- An axis step may follow any step, and may also start the chain, in which case it is relative
  to the element the search is made from, for example when finding an element within another element.
- An axis step cannot directly follow `**/`, but `**/` may follow an axis step:
  `XCUIElementTypeButton/../**/XCUIElementTypeImage`.
- As for the other steps, a position selects among the matches of the whole step. If the previous step
  matches several elements, then the matches of `>` and `~` for all of them are merged in the document order
  before the position is applied, while the matches of `^` and `<` stay in the order of the axis, with
  duplicates removed. XPath applies the position for each element separately.
- The matches of a chain containing axis steps are always returned in the document order, same as for XPath.
- Axes may leave the subtree of the element the search is made from, as long as the element belongs
  to the application. Such chains are evaluated on the accessibility snapshot of the whole application,
  because `XCUIElementQuery` has no parent or sibling axes. Chains without axis steps are still
  resolved by native queries. Such a lookup takes about one snapshot of the application, which
  made it around 2x faster than the equivalent XPath in measurements on several apps.

## Strict Syntax

- A position is an integer that is not zero, written with ASCII digits.
- A class name directly after `**` is an error: use `**/XCUIElementTypeButton`, not `**XCUIElementTypeButton`.
- An empty query is an error.

## More Information

- [Locator Strategies](./locator-strategies.md) — overview of all strategies and their performance
- [Predicate Locator Strategy](./predicate.md) — how to write the predicates used in class chains
- [Element Attributes](./element-attributes.md) — element attributes available in predicates
