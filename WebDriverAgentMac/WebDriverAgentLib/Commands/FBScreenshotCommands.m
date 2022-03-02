/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBScreenshotCommands.h"

#import "XCTest/XCTest.h"

@implementation FBScreenshotCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/screenshot"].withoutSession respondWithTarget:self action:@selector(handleGetScreenshot:)],
    [[FBRoute GET:@"/screenshot"] respondWithTarget:self action:@selector(handleGetScreenshot:)],

    [[FBRoute GET:@"/wda/screenshots"].withoutSession respondWithTarget:self action:@selector(handleGetScreenshots:)],
    [[FBRoute GET:@"/wda/screenshots"] respondWithTarget:self action:@selector(handleGetScreenshots:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleGetScreenshot:(FBRouteRequest *)request
{
  NSData *screenshotData = [[[XCUIScreen mainScreen] screenshot] PNGRepresentation];
  if (nil == screenshotData) {
    NSString *message = @"Cannot take a screenshot of the main screen";
    return FBResponseWithStatus([FBCommandStatus unableToCaptureScreenErrorWithMessage:message
                                                                             traceback:nil]);
  }
  NSString *screenshot = [screenshotData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  return FBResponseWithObject(screenshot);
}

+ (id<FBResponsePayload>)handleGetScreenshots:(FBRouteRequest *)request
{
  NSMutableDictionary <NSNumber *, NSDictionary *> *result = [NSMutableDictionary new];
  for (XCUIScreen *screen in XCUIScreen.screens) {
    NSNumber *displayId = [screen valueForKey:@"_displayID"];
    NSNumber *isMainDisplay = [screen valueForKey:@"_isMainScreen"];
    NSData *screenshotData = screen.screenshot.PNGRepresentation;
    NSDictionary *screenInfo = @{
      @"id": displayId == nil ? @(-1) : displayId,
      @"isMain": isMainDisplay == nil ? @(NO) : isMainDisplay,
      @"payload": screenshotData == nil ? NSNull.null : [screenshotData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]
    };
    [result setObject:screenInfo forKey:displayId];
  }
  return FBResponseWithObject(result);
}

@end
