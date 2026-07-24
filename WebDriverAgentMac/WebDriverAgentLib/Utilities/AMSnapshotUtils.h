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
 Retrives the unique snapshot hash. This hash is unique per snapshot's
 accessibility elemnent, which means different snapshots of the same
 element may have equal hashes

 @param snapshot snapshot instance to calcluate the hash for
 @return The hash value as base64-encoded string
 */
+ (NSString *)hashWithSnapshot:(id)snapshot;

/**
 Whether the current process is trusted for the public Accessibility API.
 When NO, DOM identifier resolution is impossible (reads fail with
 kAXErrorAPIDisabled) and callers must fall back to default behaviour.
 */
+ (BOOL)isAccessibilityTrusted;

/**
 Resolves a WebKit web element's DOM `id` for the given snapshot, by
 reconstituting the underlying AXUIElementRef from the snapshot's remote token
 and reading its non-standard `AXDOMIdentifier` attribute.

 Returns nil for native (non-web) elements, for elements without an `id`, and
 whenever the process is not Accessibility-trusted. Never raises.

 @param snapshot snapshot instance (must expose `_accessibilityElement._token`)
 @return The DOM `id` string, or nil
 */
+ (nullable NSString *)domIdentifierWithSnapshot:(id)snapshot;

@end

NS_ASSUME_NONNULL_END
