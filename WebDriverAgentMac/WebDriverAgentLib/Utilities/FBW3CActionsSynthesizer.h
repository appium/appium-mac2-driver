/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBBaseActionsSynthesizer.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBW3CActionsSynthesizer : FBBaseActionsSynthesizer

/*! YES if the actions consist of a single key input source only */
@property (readonly, nonatomic) BOOL isKeyOnly;

/**
 Synthesizes the key actions as a sequence of XCSynthesizedEventRecord instances,
 which must be performed one after another. Delays between them are represented
 as NSNumber instances (seconds).
 */
- (nullable NSArray *)synthesizeKeySequenceWithError:(NSError **)error;

/*! The record, which releases all the modifiers and closes the persistent state */
+ (XCSynthesizedEventRecord *)modifiersReleaseRecord;

@end

NS_ASSUME_NONNULL_END
