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
