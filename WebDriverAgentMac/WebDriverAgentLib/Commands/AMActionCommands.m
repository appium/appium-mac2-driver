/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AMActionCommands.h"

#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "XCUIApplication+FBW3CActions.h"

@implementation AMActionCommands

#pragma mark - <AMActionCommands>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute POST:@"/actions"] respondWithTarget:self action:@selector(handlePerformW3CActions:)],
  ];
}

#pragma mark - Commands

+ (id<FBResponsePayload>)handlePerformW3CActions:(FBRouteRequest *)request
{
  XCUIApplication *application = request.session.currentApplication;
  FBElementCache *cache = request.session.elementCache;
  NSArray *actions = (NSArray *)request.arguments[@"actions"];
  NSError *error;
  if (![application fb_performW3CActions:actions
                            elementCache:cache
                                   error:&error]) {
    if ([error.localizedDescription containsString:@"not visible"]) {
      return FBResponseWithStatus([FBCommandStatus elementNotVisibleErrorWithMessage:error.localizedDescription
                                                                           traceback:nil]);
    }
    return FBResponseWithUnknownError(error);
  }
  return FBResponseWithOK();
}

@end
