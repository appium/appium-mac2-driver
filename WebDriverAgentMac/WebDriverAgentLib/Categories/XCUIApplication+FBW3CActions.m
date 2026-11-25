/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIApplication+FBW3CActions.h"

#import "AMXCUIDeviceWrapper.h"
#import "FBBaseActionsSynthesizer.h"
#import "FBErrorBuilder.h"
#import "FBW3CActionsSynthesizer.h"

#define MAX_ACTIONS_DURATION_SEC 300

@implementation XCUIApplication (FBW3CActions)

- (BOOL)fb_performW3CActions:(NSArray *)actions
                elementCache:(FBElementCache *)elementCache
                       error:(NSError **)error
{
  FBBaseActionsSynthesizer *synthesizer = [[FBW3CActionsSynthesizer alloc] initWithActions:actions
                                                                            forApplication:self
                                                                              elementCache:elementCache
                                                                                     error:error];
  if (nil == synthesizer) {
    return NO;
  }
  if ([synthesizer isKindOfClass:FBW3CActionsSynthesizer.class] && ((FBW3CActionsSynthesizer *)synthesizer).isKeyOnly) {
    return [self.class fb_performKeySequence:[(FBW3CActionsSynthesizer *)synthesizer synthesizeKeySequenceWithError:error]
                                       error:error];
  }
  XCSynthesizedEventRecord *eventRecord = [synthesizer synthesizeWithError:error];
  return nil == eventRecord ? NO : [AMXCUIDeviceWrapper.sharedDevice synthesizeEvent:eventRecord error:error];
}

+ (BOOL)fb_performKeySequence:(nullable NSArray *)sequence
                         error:(NSError **)error
{
  if (nil == sequence) {
    return NO;
  }
  BOOL isPersistent = NO;
  for (id step in sequence) {
    if ([step isKindOfClass:NSNumber.class]) {
      [NSThread sleepForTimeInterval:[step doubleValue]];
      continue;
    }
    if (![AMXCUIDeviceWrapper.sharedDevice synthesizeEvent:step error:error]) {
      if (isPersistent) {
        // Do not leave modifiers pressed
        [AMXCUIDeviceWrapper.sharedDevice synthesizeEvent:[FBW3CActionsSynthesizer modifiersReleaseRecord] error:nil];
      }
      return NO;
    }
    if ([[step valueForKey:@"beginsPersistentState"] boolValue]) {
      isPersistent = YES;
    } else if ([[step valueForKey:@"endsPersistentState"] boolValue]) {
      isPersistent = NO;
    }
  }
  return YES;
}

@end
