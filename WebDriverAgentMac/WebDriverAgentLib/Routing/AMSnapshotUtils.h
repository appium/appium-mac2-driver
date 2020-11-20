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

@end

NS_ASSUME_NONNULL_END
