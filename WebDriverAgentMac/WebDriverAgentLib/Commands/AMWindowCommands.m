/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AMWindowCommands.h"

#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "XCUIElement+FBFind.h"

@implementation AMWindowCommands

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute POST:@"/window/maximize"] respondWithTarget:self action:@selector(handleMaximizeWindow:)],
    [[FBRoute POST:@"/window/fullscreen"] respondWithTarget:self action:@selector(handleFullscreenWindow:)],
    [[FBRoute POST:@"/window/minimize"] respondWithTarget:self action:@selector(handleMinimizeWindow:)],
  ];
}

#pragma mark - Commands

+ (id<FBResponsePayload>)handleMaximizeWindow:(FBRouteRequest *)request
{
  return [self performClickWithButtonId:@"_XCUI:FullScreenWindow"
                                request:request
                           errorMessage:[NSString stringWithFormat:@"%@ window cannot be maximized because the correponding button is not available", request.session.currentApplication.description]];
}

+ (id<FBResponsePayload>)handleFullscreenWindow:(FBRouteRequest *)request
{
  return [self performClickWithButtonId:@"_XCUI:FullScreenWindow"
                                request:request
                           errorMessage:[NSString stringWithFormat:@"%@ window cannot be put into fullscreen mode because the correponding button is not available", request.session.currentApplication.description]];
}

+ (id<FBResponsePayload>)handleMinimizeWindow:(FBRouteRequest *)request
{
  return [self performClickWithButtonId:@"_XCUI:MinimizeWindow"
                                request:request
                           errorMessage:[NSString stringWithFormat:@"%@ window cannot be minimized because the correponding button is not available", request.session.currentApplication.description]];
}

+ (id<FBResponsePayload>)performClickWithButtonId:(NSString *)buttonId
                                          request:(FBRouteRequest *)request
                                     errorMessage:(NSString *)errorMessage
{
  XCUIApplication *application = request.session.currentApplication;
  XCUIElement *dstButton = [application fb_descendantsMatchingIdentifier:buttonId
                                             shouldReturnAfterFirstMatch:YES].firstObject;
  if (nil == dstButton || !dstButton.hittable) {
    return FBResponseWithUnknownErrorFormat(@"%@", errorMessage);
  }
  [dstButton click];
  return FBResponseWithOK();
}

@end
