/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBScreenshotCommands.h"

#import "AMScreenUtils.h"
#import "FBRouteRequest.h"

@implementation FBScreenshotCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/screenshot"].withoutSession respondWithTarget:self action:@selector(handleGetScreenshot:)],
    [[FBRoute GET:@"/screenshot"] respondWithTarget:self action:@selector(handleGetScreenshot:)],

    [[FBRoute POST:@"/wda/screenshots"].withoutSession respondWithTarget:self action:@selector(handleGetScreenshots:)],
    [[FBRoute POST:@"/wda/screenshots"] respondWithTarget:self action:@selector(handleGetScreenshots:)],
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
  NSString *screenshot = [screenshotData base64EncodedStringWithOptions:0];
  return FBResponseWithObject(screenshot);
}

+ (id<FBResponsePayload>)handleGetScreenshots:(FBRouteRequest *)request
{
  NSNumber *desiredId = request.arguments[@"displayId"];
  NSMutableDictionary <NSString *, NSDictionary<NSString *, id> *> *result = [NSMutableDictionary new];
  NSMutableArray <NSNumber *> *availableDisplayIds = [NSMutableArray new];
  for (XCUIScreen *screen in XCUIScreen.screens) {
    long long currentScreenId = AMFetchScreenId(screen);
    if (nil != desiredId && desiredId.longLongValue != currentScreenId) {
      continue;
    }

    [availableDisplayIds addObject:@(currentScreenId)];
    result[[NSString stringWithFormat:@"%lld", currentScreenId]] = @{
      @"id": @(currentScreenId),
      @"isMain": @(AMIsMainScreen(screen)),
      @"payload": [screen.screenshot.PNGRepresentation base64EncodedStringWithOptions:0] ?: NSNull.null
    };
  }
  if (nil != desiredId && 0 == [result count]) {
    NSString *message = [NSString stringWithFormat:@"The screen identified by %@ is not available to XCTest. Only the following identifiers are available: %@",
                         desiredId, [availableDisplayIds componentsJoinedByString:@","]];
    return FBResponseWithStatus([FBCommandStatus unableToCaptureScreenErrorWithMessage:message
                                                                             traceback:nil]);
  }
  return FBResponseWithObject(result.copy);
}

@end
