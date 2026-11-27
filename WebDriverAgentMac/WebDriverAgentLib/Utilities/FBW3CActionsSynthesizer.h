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
 Performs the actions as a sequence of single-key event records, which keeps the modifiers pressed
 for the time between their key down and key up. Only applicable if `isKeyOnly` is YES.
 */
- (BOOL)performKeyActionsWithError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
