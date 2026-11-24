---
title: Locator Strategies
---

The Mac2 driver supports several location strategies in the native context. The list below
describes each strategy along with usage recommendations. For additional recommendations, consider
checking the [How To Achieve The Best Lookup Performance](https://github.com/facebookarchive/WebDriverAgent/wiki/How-To-Achieve-The-Best-Lookup-Performance)
article.

## Class Name

|Name|Speed Ranking|Example|
|---|---|---|
|`className`|⭐⭐⭐⭐⭐|`XCUIElementTypeButton`|

This strategy is mapped to the element's `elementType` [attribute](./element-attributes.md#elementtype). The full list of
supported XCUIElement type names can be found in the [XCTest documentation on `XCUIElementType`](https://developer.apple.com/documentation/xcuiautomation/xcuielement/elementtype).

!!! info "When to Use"

    Use this strategy when you want to count the number of elements of a specific type. It is not
    recommended to use this approach for single element searches, since it may return a different
    result as soon as at least one other element with the same `elementType` value is present. Only
    use this in individual element searches when you are certain that exactly one such element will
    always be expected.

## Name

|Name|Speed Ranking|Example|
|---|---|---|
|`name`|⭐⭐⭐⭐⭐|`my name`|

This strategy is mapped to the element's `identifier` [attribute](./element-attributes.md#identifier).

!!! info "When to Use"

    Use this strategy for elements that can be identified using their `identifier` attribute value.

## Id

|Name|Speed Ranking|Example|
|---|---|---|
|`id`|⭐⭐⭐⭐⭐|`my name`|

This strategy is an alias for the [`name` strategy](#name).

## Accessibility Id

|Name|Speed Ranking|Example|
|---|---|---|
|`accessibility id`|⭐⭐⭐⭐⭐|`my name`|

This strategy is an alias for the [`name` strategy](#name).

## Predicate String

|<div style="width:9em">Name</div>|Speed Ranking|Example|
|---|---|---|
|`predicate string`|⭐⭐⭐⭐⭐|`(name == 'done' OR value == 'done') AND type IN {'XCUIElementTypeButton', 'XCUIElementTypeKey'}`|

This strategy is mapped to the native XCTest predicate locator. Refer to the XCUITest driver's
[Predicate Locator Strategy guide](https://appium.github.io/appium-xcuitest-driver/latest/reference/ios-predicate/)
for more details on how to build effective predicate expressions. All supported element [attributes](./element-attributes.md)
can be used in these expressions. A few of them have no native XCTest equivalent that predicate
expressions can reference directly, so they are only usable through their `am`-prefixed alias:
[`amRect`](./element-attributes.md#amrect), [`amText`](./element-attributes.md#amtext),
[`amType`](./element-attributes.md#amtype) and
[`amHasKeyboardInputFocus`](./element-attributes.md#amhaskeyboardinputfocus). Separately,
[`amIdentifier`](./element-attributes.md#amidentifier) is the only reliable way to match
`WKWebView` web elements by their DOM id from this strategy - see
[`useDomIdAsAccessibilityId`](./settings.md#usedomidasaccessibilityid) - e.g. `amIdentifier == 'done'`.

!!! info "When to Use"

    Use this strategy for elements that can be identified only using one or more of their own
    attributes - that is, without utilizing their parent, descendant, or sibling elements.

## Class Chain

|<div style="width:7em">Name</div>|Speed Ranking|Example|
|---|---|---|
|`class chain`|⭐⭐⭐⭐|`**/XCUIElementTypeCell[$name == 'done' OR value == 'done'$]/XCUIElementTypeButton[-1]`|

This strategy is mapped to the native XCTest predicate locator, but with respect to the actual
element tree hierarchy. Such locators are basically a supertype of [predicate string](#predicate-string).
Read [Class Chain Queries Construction Rules](https://github.com/facebookarchive/WebDriverAgent/wiki/Class-Chain-Queries-Construction-Rules)
for more details on how to build such locators. As with predicate string, the `am`-prefixed
attribute aliases can be used at any position in the chain, including `amIdentifier` to reliably
match `WKWebView` web elements by their DOM id.

!!! info "When to Use"

    Use this strategy for elements that _cannot_ be identified only using their own attributes,
    but _can_ be identified upon additionally using their parent element(s), sibling element(s)
    and/or their descendant element attribute(s).

### Axis Steps

Axis steps select elements relative to the ones matched by the previous step, so a chain can
move to the parent, ancestors or siblings. They cover most of the cases that otherwise
require XPath axes.

|Step|Selects|XPath equivalent|
|---|---|---|
|`..`|the parent|`..` or `parent::*`|
|`^XCUIElementTypeWindow`|all ancestors of the given type|`ancestor::XCUIElementTypeWindow`|
|`>XCUIElementTypeButton`|all following siblings of the given type|`following-sibling::XCUIElementTypeButton`|
|`<XCUIElementTypeButton`|all preceding siblings of the given type|`preceding-sibling::XCUIElementTypeButton`|
|`~XCUIElementTypeButton`|all siblings of the given type, except the matched element itself|`preceding-sibling::XCUIElementTypeButton \| following-sibling::XCUIElementTypeButton`|

For example, ``**/XCUIElementTypeButton[`identifier == "OK"`]/<XCUIElementTypeButton[1]`` selects the
button right before the "OK" button, and ``**/XCUIElementTypeButton[`identifier == "OK"`]/^XCUIElementTypeWindow``
selects the window containing it.

- Axis steps accept `*`, predicates and positions, same as regular steps. Positions count along
  the axis: starting from the nearest element for `^` and `<`, in document order for `>` and `~`,
  and from the other end if negative. `..` has neither a class name nor a position,
  but may have predicates.
- An axis step may follow any step, and may also start the chain, in which case it is relative to the
  element the search is made from. It cannot directly follow `**/`, but `**/` may follow it,
  for example `XCUIElementTypeButton/../**/XCUIElementTypeImage`.
- The matches of a chain containing axis steps are always returned in document order.
- Axes may leave the subtree of the element the search is made from, as long as the element belongs
  to the application. Such chains are evaluated on the accessibility snapshot of the whole application,
  because `XCUIElementQuery` has no parent or sibling axes. Chains without axis steps are still
  resolved by native queries.

Class chain syntax is strict: a position is an integer that is not zero, and a predicate must not be empty.
A class name directly after `**` is an error, and predicate text is not a format string, so it must not
contain format specifiers like `%@`.

## XPath

|Name|Speed Ranking|Example|
|---|---|---|
|`xpath`|⭐⭐⭐|`//XCUIElementTypeButton[@value="Regular"]/parent::*`|

This strategy is not natively supported by XCTest, and relies on the XML tree generated by the
Mac2 driver's page source API. As a result, such locators can be much slower compared to all
other ones - sometimes up to 10x slower.

XPath 2.0 is supported since Mac2 driver version 1.20.0. Older driver versions only support XPath
1.0 (based on `xmllib2`). 

!!! info "When to Use"

    Use this strategy for elements that can _only_ be identified when using conditions
    that cannot be expressed by the other strategies, for example the complex ones that
    combine several elements of the hierarchy. It is _strongly_ recommended to use more
    performant strategies if possible, such as [class chain](#class-chain) with
    [axis steps](#axis-steps) for the parent, ancestor and sibling relationships.
