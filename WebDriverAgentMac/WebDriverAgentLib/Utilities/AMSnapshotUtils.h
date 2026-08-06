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

@end

NS_ASSUME_NONNULL_END
