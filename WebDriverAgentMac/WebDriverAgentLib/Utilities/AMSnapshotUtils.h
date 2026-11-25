/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * See the NOTICE file distributed with this work for additional
 * information regarding copyright ownership.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <ApplicationServices/ApplicationServices.h>
#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMSnapshotUtils : NSObject

/**
 Retrieves the unique snapshot hash. This hash is unique per snapshot's
 accessibility elemnent, which means different snapshots of the same
 element may have equal hashes

 @param snapshot snapshot instance to calculate the hash for
 @return The hash value as base64-encoded string
 */
+ (NSString *)hashWithSnapshot:(id)snapshot;

/**
 Retrieves the identifier WebDriver clients should observe for the given snapshot.
 This is the standard accessibility identifier, except for WebKit (WKWebView) web
 nodes, which leave it empty and publish their HTML `id` through the non-standard
 AXDOMIdentifier attribute instead. That one is only consulted while the
 `useDomIdAsAccessibilityId` setting is enabled, so a native identifier is never
 overridden.

 @param snapshot snapshot instance to retrieve the identifier for
 @return The identifier value or nil
 */
+ (nullable NSString *)wdIdentifierWithSnapshot:(nullable id<XCUIElementSnapshot>)snapshot;

/**
 Whether this process is trusted for the Accessibility API. WebKit DOM identifier
 resolution silently yields no results without this, since AXDOMIdentifier reads
 fail with kAXErrorAPIDisabled - useful for tests and diagnostics to tell "no DOM id
 fallback happened because the setting is off" apart from "no DOM id fallback
 happened because this process lacks Accessibility permission".

 @return YES if AXDOMIdentifier reads are expected to work, NO otherwise
 */
+ (BOOL)isAccessibilityTrusted;

/**
 Resolves snapshot hashes back to live elements below the given root element.

 @param hashes snapshot hashes to resolve, as returned by hashWithSnapshot:
 @param rootElement the element the hashes were collected from
 @param rootSnapshot the snapshot of rootElement
 @param firstMatch whether to only return the first matching element
 @return The matching elements. Could be empty
 */
+ (NSArray<XCUIElement *> *)elementsWithHashes:(NSSet<NSString *> *)hashes
                                   rootElement:(XCUIElement *)rootElement
                                  rootSnapshot:(id<XCUIElementSnapshot>)rootSnapshot
                         includeOnlyFirstMatch:(BOOL)firstMatch;

/**
 Binds the given snapshots to elements the way allElementsBoundByAccessibilityElement does,
 but without taking one more snapshot of the root element.

 @param snapshots snapshots of the root element subtree (or the root snapshot itself)
 @param rootElement the element the snapshots were taken from
 @param rootSnapshot the snapshot of rootElement
 @return The elements in the order of the given snapshots, or nil if they cannot be bound
 this way (the private API is not available or elements are bound by index)
 */
+ (nullable NSArray<XCUIElement *> *)elementsWithSnapshots:(NSArray<id<XCUIElementSnapshot>> *)snapshots
                                               rootElement:(XCUIElement *)rootElement
                                              rootSnapshot:(id<XCUIElementSnapshot>)rootSnapshot;

/**
 Looks up elements below (and including) the root element by walking one snapshot of it
 in memory and binding the matches without re-snapshotting, see elementsWithSnapshots:.
 Only worth it where the alternative takes several snapshots: a native type or predicate
 query is cheaper than a full snapshot.

 @param rootElement the element to search under, it is a candidate itself
 @param firstMatch whether to stop after the first match
 @param matcher called for every snapshot in document order, YES means a match
 @param fallbackMatcher optional, walks the same snapshot again if the matcher finds nothing
 @return The matching elements in document order (could be empty), or nil if this way is not
 applicable (no direct binding, snapshot failure, or the matcher threw). The caller should
 use the query-based lookup then.
 */
+ (nullable NSArray<XCUIElement *> *)elementsMatchingInSnapshotOfElement:(XCUIElement *)rootElement
                                                   includeOnlyFirstMatch:(BOOL)firstMatch
                                                                 matcher:(BOOL (^)(id<XCUIElementSnapshot> snapshot))matcher
                                                         fallbackMatcher:(nullable BOOL (^)(id<XCUIElementSnapshot> snapshot))fallbackMatcher;

/**
 Reads the non-standard AXDOMIdentifier attribute, where WebKit publishes a web
 node's HTML `id`. Returns nil for native elements, which report
 kAXErrorAttributeUnsupported for it, or when this process lacks Accessibility
 permission.

 @param snapshot snapshot instance to read the DOM identifier from
 @return The DOM identifier or nil
 */
+ (nullable NSString *)domIdentifierWithSnapshot:(nullable id)snapshot;

/**
 Creates an AX element for the given snapshot. The caller owns the result and must CFRelease it.

 @param snapshot snapshot instance to create the AX element for
 @return The AX element or NULL if this process lacks Accessibility permission or the element is unavailable
 */
+ (nullable AXUIElementRef)createAXElementWithSnapshot:(nullable id)snapshot CF_RETURNS_RETAINED;

/**
 Creates an AX element for the XCTest accessibility element (XCAccessibilityElement).
 The caller owns the result and must CFRelease it.

 @param element XCTest accessibility element
 @return The AX element or NULL if this process lacks Accessibility permission or the element is unavailable
 */
+ (nullable AXUIElementRef)createAXElementWithAccessibilityElement:(nullable id)element CF_RETURNS_RETAINED;

@end

NS_ASSUME_NONNULL_END
