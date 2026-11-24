---
title: Predicate Locator Strategy
---

The Mac2 driver supports searching elements using the _predicate string_ and _class chain_
[locator search strategies](../reference/locator-strategies.md). They are powered by Apple XCTest, provide
flexibility and are much faster than XPath. Predicates can be used to restrict a set of elements to
select only those for which some condition evaluates to true.

!!! tip

    In addition to the examples listed here, make sure to check the links in the
    [More Information](#more-information) section below!

## Quick Examples

=== "Predicate String"

    ```java
    // java
    driver.findElements(AppiumBy.iOSNsPredicateString("enabled == 1 AND label CONTAINS 'yolo'"));
    ```

=== "Class Chain"

    ```java
    // java
    driver.findElements(AppiumBy.iOSClassChain("**/XCUIElementTypeWindow[`label LIKE '*yolo*'`]"));
    ```

The predicate string example would select all enabled elements, whose label contains `yolo`, while
the class chain example would find all elements of type `XCUIElementTypeWindow` whose label
contains `yolo`. Class chain queries allow to create much more complicated search expressions
and may contain multiple predicates. Check the [Class Chain Locator Strategy](./class-chain.md)
article for how to build such queries.

## Available Attributes

All supported element [attributes](../reference/element-attributes.md) can be used in predicate expressions.
A few of them have no native XCTest equivalent that predicate expressions can reference directly,
so they are only usable through their `am`-prefixed alias:
[`amRect`](../reference/element-attributes.md#amrect), [`amText`](../reference/element-attributes.md#amtext),
[`amType`](../reference/element-attributes.md#amtype) and
[`amHasKeyboardInputFocus`](../reference/element-attributes.md#amhaskeyboardinputfocus). Separately,
[`amIdentifier`](../reference/element-attributes.md#amidentifier) is the only reliable way to match
`WKWebView` web elements by their DOM id - see
[`useDomIdAsAccessibilityId`](../reference/settings.md#usedomidasaccessibilityid) - e.g. `amIdentifier == 'done'`.

## Basic Comparisons

* `=` , `==` - The left-hand expression is equal to the right-hand expression:
  ```java
  // java
  driver.findElements(AppiumBy.iOSNsPredicateString("label == 'Olivia'"));

  // same in Xpath:
  driver.findElements(AppiumBy.xpath("//*[@label = 'Olivia']"));
  ```

* `>=` , `=>` - The left-hand expression is greater than or equal to the right-hand expression.

* `<=` , `=<` - The left-hand expression is less than or equal to the right-hand expression.

* `>` - The left-hand expression is greater than the right-hand expression.

* `<` - The left-hand expression is less than the right-hand expression.

* `!=` , `<>` - The left-hand expression is not equal to the right-hand expression.

* `BETWEEN` - The left-hand expression is between, or equal to either of, the values specified in
  the right-hand side. The right-hand side is a two value array (an array is required to specify
  order) giving upper and lower bounds. For example, `1 BETWEEN { 0 , 33 }`.

## Boolean Value Predicates

* `TRUEPREDICATE` - A predicate that always evaluates to `TRUE` .

* `FALSEPREDICATE` - A predicate that always evaluates to `FALSE`.

## Basic Compound Predicates

* `AND` , `&&` - Logical AND.

* `OR` , `||` - Logical OR.

* `NOT` , `!` - Logical NOT.

## String Comparisons

String comparisons are by default case and diacritic sensitive. You can modify an operator using the
key characters `c` and `d` within square braces to specify case and diacritic insensitivity
respectively, for example, `value BEGINSWITH[cd] 'bar'`.

* `BEGINSWITH` - The left-hand expression begins with the right-hand expression.

    ```java
    driver.findElement(AppiumBy.iOSNsPredicateString("amType == 'XCUIElementTypeButton' AND identifier BEGINSWITH '_XCUI:'"));

    // same in Xpath:
    driver.findElement(AppiumBy.xpath("//XCUIElementTypeButton[starts-with(@identifier, '_XCUI:')]"));
    ```

* `CONTAINS` - The left-hand expression contains the right-hand expression.

    ```java
    driver.findElement(AppiumBy.iOSNsPredicateString("amType == 'XCUIElementTypeButton' AND label CONTAINS 'opera'"));

    // same in Xpath:
    driver.findElement(AppiumBy.xpath("//XCUIElementTypeButton[contains(@label, 'opera')]"));
    ```

* `ENDSWITH` - The left-hand expression ends with the right-hand expression.

* `LIKE` - The left hand expression equals the right-hand expression: `?` and `*` are allowed as
  wildcard characters, where `?` matches 1 character and `*` matches 0 or more characters.

    ```java
    driver.findElement(AppiumBy.iOSNsPredicateString("label LIKE '*Total: $*'"));
    ```

* `MATCHES` - The left hand expression equals the right hand expression using a regex-style
  comparison according to ICU v3 (for more details see the ICU User Guide for
  [Regular Expressions](http://userguide.icu-project.org/strings/regexp)).

    ```java
    driver.findElement(AppiumBy.iOSNsPredicateString("value MATCHES '.*of [1-9]'"));
    ```

## Aggregate Operations

* `IN` - Equivalent to an SQL IN operation, the left-hand side must appear in the collection
  specified by the right-hand side. For example, `identifier IN { 'Ben', 'Melissa', 'Matthew' }`.
  The collection may be an array, a set, or a dictionary (in the case of a dictionary, its values
  are used).

## Identifiers

* **C style identifier** - Any C style identifier that is not a reserved word.

* **\#symbol** - Used to escape a reserved word into a user identifier.

* **[\\]{octaldigit}{3}** - Used to escape an octal number ( ```\``` followed by 3 octal digits).

* **[\\][xX]{hexdigit}{2}** - Used to escape a hex number ( ```\x``` or ```\X``` followed by 2 hex digits).

* **[\\][uU]{hexdigit}{4}** - Used to escape a Unicode number ( ```\u``` or ```\U``` followed by 4 hex digits).

## Literals

Single and double quotes produce the same result, but they do not terminate each other. For example,
`"abc"` and `'abc'` are identical, whereas `"a'b'c"` is equivalent to a space-separated
concatenation of `a, 'b', c`.

* `FALSE` , `NO` - Logical false.

* `TRUE` , `YES` - Logical true.

* `NULL` , `NIL` - A null value.

* `SELF` - Represents the object being evaluated.

* `"text"` - A character string.

* `'text'` - A character string.

* **Comma-separated literal array** - For example, `{ 'comma', 'separated', 'literal', 'array' }` .

* **Standard integer and fixed-point notations** - For example, `1 , 27 , 2.71828 , 19.75` .

* **Floating-point notation with exponentiation** - For example, `9.2e-5` .

* `0x` - Prefix used to denote a hexadecimal digit sequence.

* `0o` - Prefix used to denote an octal digit sequence.

* `0b` - Prefix used to denote a binary digit sequence.

## Reserved Keywords

The following keywords are reserved:

`AND, OR, IN, NOT, ALL, ANY, SOME, NONE, LIKE, CASEINSENSITIVE, CI, MATCHES, CONTAINS, BEGINSWITH,
ENDSWITH, BETWEEN, NULL, NIL, SELF, TRUE, YES, FALSE, NO, FIRST, LAST, SIZE, ANYKEY, SUBQUERY,
CAST, TRUEPREDICATE, FALSEPREDICATE`

## More Information

* [Apple Developer documentation on Predicates](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Predicates/AdditionalChapters/Introduction.html)
* [NSPredicate Cheat Sheet](https://academy.realm.io/posts/nspredicate-cheatsheet/)
* [Class Chain Locator Strategy](./class-chain.md)
