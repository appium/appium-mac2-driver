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
  XCSynthesizedEventRecord *eventRecord = [synthesizer synthesizeWithError:error];
  return nil == eventRecord ? NO : [AMXCUIDeviceWrapper.sharedDevice synthesizeEvent:eventRecord error:error];
}

@end
