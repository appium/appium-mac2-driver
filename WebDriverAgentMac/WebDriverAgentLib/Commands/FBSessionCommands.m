/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBSessionCommands.h"

#import "FBConfiguration.h"
#import "FBLogger.h"
#import "FBProtocolHelpers.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "FBSettings.h"
#import "FBRuntimeUtils.h"
#import "XCUIApplication+AMHelpers.h"


@implementation FBSessionCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute POST:@"/url"] respondWithTarget:self action:@selector(handleOpenURL:)],
    [[FBRoute POST:@"/session"].withoutSession respondWithTarget:self action:@selector(handleCreateSession:)],
    [[FBRoute POST:@"/wda/apps/launch"] respondWithTarget:self action:@selector(handleSessionAppLaunch:)],
    [[FBRoute POST:@"/wda/apps/activate"] respondWithTarget:self action:@selector(handleSessionAppActivate:)],
    [[FBRoute POST:@"/wda/apps/terminate"] respondWithTarget:self action:@selector(handleSessionAppTerminate:)],
    [[FBRoute POST:@"/wda/apps/state"] respondWithTarget:self action:@selector(handleSessionAppState:)],
    [[FBRoute GET:@""] respondWithTarget:self action:@selector(handleGetActiveSession:)],
    [[FBRoute DELETE:@""] respondWithTarget:self action:@selector(handleDeleteSession:)],
    [[FBRoute GET:@"/status"].withoutSession respondWithTarget:self action:@selector(handleGetStatus:)],

    // Settings endpoints
    [[FBRoute GET:@"/appium/settings"] respondWithTarget:self action:@selector(handleGetSettings:)],
    [[FBRoute POST:@"/appium/settings"] respondWithTarget:self action:@selector(handleSetSettings:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleOpenURL:(FBRouteRequest *)request
{
  NSString *urlString = request.arguments[@"url"];
  NSURL *url = [NSURL URLWithString:urlString];
  if (!url) {
    NSString *message = [NSString stringWithFormat:@"'%@' should be a valid URL", urlString];
    return FBResponseWithStatus([FBCommandStatus invalidArgumentErrorWithMessage:message
                                                                       traceback:nil]);
  }
  if (![[NSWorkspace sharedWorkspace] openURL:url]) {
    NSString *message = [NSString stringWithFormat:@"'%@' cannot be opened", urlString];
    return FBResponseWithStatus([FBCommandStatus unknownErrorWithMessage:message
                                                               traceback:nil]);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleCreateSession:(FBRouteRequest *)request
{
  NSDictionary<NSString *, id> *requirements;
  NSError *error;
  if (![request.arguments[@"capabilities"] isKindOfClass:NSDictionary.class]) {
    return FBResponseWithStatus([FBCommandStatus sessionNotCreatedError:@"'capabilities' is mandatory to create a new session"
                                                              traceback:nil]);
  }
  if (nil == (requirements = FBParseCapabilities((NSDictionary *)request.arguments[@"capabilities"], &error))) {
    return FBResponseWithStatus([FBCommandStatus sessionNotCreatedError:error.description traceback:nil]);
  }

  NSString *bundleID = requirements[@"bundleId"];
  XCUIApplication *app = nil;
  if (bundleID != nil) {
    app = [[XCUIApplication alloc] initWithBundleIdentifier:bundleID];
    app.launchArguments = (NSArray<NSString *> *)requirements[@"arguments"] ?: @[];
    app.launchEnvironment = (NSDictionary <NSString *, NSString *> *)requirements[@"environment"] ?: @{};
    [app launch];
    if (app.state <= XCUIApplicationStateNotRunning) {
      return FBResponseWithStatus([FBCommandStatus sessionNotCreatedError:[NSString stringWithFormat:@"Failed to launch %@ application", bundleID] traceback:nil]);
    }
  }
  [FBSession initWithApplication:app];

  return FBResponseWithObject(FBSessionCommands.sessionInformation);
}

+ (id<FBResponsePayload>)handleSessionAppLaunch:(FBRouteRequest *)request
{
  [request.session launchApplicationWithBundleId:(id)request.arguments[@"bundleId"]
                                       arguments:request.arguments[@"arguments"]
                                     environment:request.arguments[@"environment"]];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleSessionAppActivate:(FBRouteRequest *)request
{
  [request.session activateApplicationWithBundleId:(id)request.arguments[@"bundleId"]];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleSessionAppTerminate:(FBRouteRequest *)request
{
  BOOL result = [request.session terminateApplicationWithBundleId:(id)request.arguments[@"bundleId"]];
  return FBResponseWithObject(@(result));
}

+ (id<FBResponsePayload>)handleSessionAppState:(FBRouteRequest *)request
{
  NSUInteger state = [request.session applicationStateWithBundleId:(id)request.arguments[@"bundleId"]];
  return FBResponseWithObject(@(state));
}

+ (id<FBResponsePayload>)handleGetActiveSession:(FBRouteRequest *)request
{
  return FBResponseWithObject(FBSessionCommands.sessionInformation);
}

+ (id<FBResponsePayload>)handleDeleteSession:(FBRouteRequest *)request
{
  [request.session kill];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleGetStatus:(FBRouteRequest *)request
{
  NSMutableDictionary *buildInfo = [NSMutableDictionary dictionaryWithDictionary:@{
    @"time" : [self.class buildTimestamp],
  }];
  NSString *upgradeTimestamp = NSProcessInfo.processInfo.environment[@"UPGRADE_TIMESTAMP"];
  if (nil != upgradeTimestamp && upgradeTimestamp.length > 0) {
    [buildInfo setObject:upgradeTimestamp forKey:@"upgradedAt"];
  }

  return FBResponseWithObject(
    @{
      @"ready" : @YES,
      @"message" : @"WebDriverAgent is ready to accept commands",
      @"state" : @"success",
      @"os" :
        @{
          @"version" : [[NSProcessInfo processInfo] operatingSystemVersionString],
        },
      @"build" : buildInfo.copy
    }
  );
}

+ (id<FBResponsePayload>)handleGetSettings:(FBRouteRequest *)request
{
  return FBResponseWithObject(
    @{
      BOUND_ELEMENTS_BY_INDEX: @([FBConfiguration.sharedConfiguration boundElementsByIndex]),
    }
  );
}

+ (id<FBResponsePayload>)handleSetSettings:(FBRouteRequest *)request
{
  NSDictionary* settings = request.arguments[@"settings"];

  if (nil != [settings objectForKey:BOUND_ELEMENTS_BY_INDEX]) {
    FBConfiguration.sharedConfiguration.boundElementsByIndex = [[settings objectForKey:BOUND_ELEMENTS_BY_INDEX] boolValue];
  }

  return [self handleGetSettings:request];
}


#pragma mark - Helpers

+ (NSString *)buildTimestamp
{
  return [NSString stringWithFormat:@"%@ %@",
    [NSString stringWithUTF8String:__DATE__],
    [NSString stringWithUTF8String:__TIME__]
  ];
}

+ (NSDictionary *)sessionInformation
{
  return
  @{
    @"sessionId" : [FBSession activeSession].identifier ?: NSNull.null,
    @"capabilities" : FBSessionCommands.currentCapabilities
  };
}

+ (NSDictionary *)currentCapabilities
{
  XCUIApplication *application = [FBSession activeSession].currentApplication;
  return @{
    @"CFBundleIdentifier": application.am_bundleID ?: [NSNull null],
  };
}

@end
