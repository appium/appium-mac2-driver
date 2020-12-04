/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIApplication+FBW3CActions.h"

#import "FBBaseActionsSynthesizer.h"
#import "FBExceptions.h"
#import "FBErrorBuilder.h"
#import "FBLogger.h"
#import "FBW3CActionsSynthesizer.h"
#import "XCUIDevice.h"

#define MAX_ACTIONS_DURATION_SEC 300

@implementation XCUIApplication (FBTouchAction)

+ (BOOL)handleEventSynthesisWithError:(NSError *)error
{
  if ([error.localizedDescription containsString:@"not visible"]) {
    [[NSException exceptionWithName:FBElementNotVisibleException
                             reason:error.localizedDescription
                           userInfo:error.userInfo] raise];
  }
  return NO;
}

- (BOOL)fb_performActionsWithItems:(NSArray *)actions
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
  if (nil == eventRecord) {
    return [self.class handleEventSynthesisWithError:*error];
  }
  return [self fb_synthesizeEvent:eventRecord error:error];
}


- (BOOL)fb_performW3CActions:(NSArray *)actions
                elementCache:(FBElementCache *)elementCache
                       error:(NSError **)error
{
  return [self fb_performActionsWithItems:actions
                             elementCache:elementCache
                                    error:error];
}

- (BOOL)fb_synthesizeEvent:(XCSynthesizedEventRecord *)event error:(NSError *__autoreleasing*)error
{
  __block NSError *internalError = nil;
  dispatch_semaphore_t sem = dispatch_semaphore_create(0);
  [[XCUIDevice.sharedDevice eventSynthesizer] synthesizeEvent:event
                                                   completion:(id)^(BOOL result, NSError *invokeError) {
    if (!result) {
      internalError = invokeError;
    }
    dispatch_semaphore_signal(sem);
  }];
  if (0 != dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MAX_ACTIONS_DURATION_SEC * NSEC_PER_SEC)))) {
    return [[[FBErrorBuilder builder]
             withDescriptionFormat:@"Cannot perform actions within %@ seconds timeout", @(MAX_ACTIONS_DURATION_SEC)]
            buildError:error];;
  }
  if (error && internalError) {
    *error = internalError;
    return NO;
  }
  return YES;
}

@end
