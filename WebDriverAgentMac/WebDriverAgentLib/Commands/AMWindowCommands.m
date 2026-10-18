/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AMWindowCommands.h"

#import "AMWindowUtils.h"
#import "FBElementCache.h"
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
    [[FBRoute GET:@"/wda/windows"] respondWithTarget:self action:@selector(handleListWindows:)],
    [[FBRoute POST:@"/wda/window/adjust"] respondWithTarget:self action:@selector(handleAdjustWindow:)],
  ];
}

#pragma mark - Commands

+ (id<FBResponsePayload>)handleMaximizeWindow:(FBRouteRequest *)request
{
  return [self performClickWithButtonId:@"_XCUI:FullScreenWindow"
                                request:request
                           errorMessage:[NSString stringWithFormat:@"%@ window cannot be maximized because the corresponding button is not available", request.session.currentApplication.description]];
}

+ (id<FBResponsePayload>)handleFullscreenWindow:(FBRouteRequest *)request
{
  return [self performClickWithButtonId:@"_XCUI:FullScreenWindow"
                                request:request
                           errorMessage:[NSString stringWithFormat:@"%@ window cannot be put into fullscreen mode because the corresponding button is not available", request.session.currentApplication.description]];
}

+ (id<FBResponsePayload>)handleMinimizeWindow:(FBRouteRequest *)request
{
  return [self performClickWithButtonId:@"_XCUI:MinimizeWindow"
                                request:request
                           errorMessage:[NSString stringWithFormat:@"%@ window cannot be minimized because the corresponding button is not available", request.session.currentApplication.description]];
}

+ (id<FBResponsePayload>)handleListWindows:(FBRouteRequest *)request
{
  FBElementCache *cache = request.session.elementCache;
  NSMutableArray *result = [NSMutableArray array];
  for (XCUIElement *window in [AMWindowUtils windowsOfApplication:request.session.currentApplication]) {
    NSDictionary *info = [AMWindowUtils infoForWindow:window];
    if (nil != info) {
      [result addObject:[self info:info withWindowId:[cache storeElement:window]]];
    }
  }
  return FBResponseWithObject(result.copy);
}

+ (id<FBResponsePayload>)handleAdjustWindow:(FBRouteRequest *)request
{
  FBElementCache *cache = request.session.elementCache;
  XCUIApplication *application = request.session.currentApplication;
  NSString *windowId = [request.arguments[@"windowId"] isKindOfClass:NSString.class] ? request.arguments[@"windowId"] : nil;
  XCUIElement *window = nil != windowId
    ? [cache elementForUUID:windowId]
    : [AMWindowUtils mainWindowOfApplication:application];
  NSError *error = nil;
  NSDictionary *info = nil;
  if (nil != window) {
    info = [AMWindowUtils adjustWindow:window withArguments:request.arguments error:&error];
  } else if (nil == windowId) {
    // There are no visible windows, so a minimized one could be restored
    info = [AMWindowUtils adjustMinimizedWindowOfApplication:application withArguments:request.arguments error:&error];
  }
  NSString *resultWindowId = nil != info && nil != window ? (windowId ?: [cache storeElement:window]) : nil;
  if (nil == info) {
    NSString *message = error.localizedDescription;
    switch (error.code) {
      case AMWindowErrorInvalidArgument:
        return FBResponseWithStatus([FBCommandStatus invalidArgumentErrorWithMessage:message traceback:nil]);
      case AMWindowErrorNotFound:
        return FBResponseWithStatus([FBCommandStatus noSuchWindowErrorWithMessage:message traceback:nil]);
      default:
        return FBResponseWithStatus([FBCommandStatus unknownErrorWithMessage:message traceback:nil]);
    }
  }
  return FBResponseWithObject([self info:info withWindowId:resultWindowId]);
}

#pragma mark - Helpers

+ (NSDictionary<NSString *, id> *)info:(NSDictionary<NSString *, id> *)info withWindowId:(nullable NSString *)windowId
{
  NSMutableDictionary *result = [info mutableCopy];
  result[@"windowId"] = windowId ?: NSNull.null;
  return result.copy;
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
