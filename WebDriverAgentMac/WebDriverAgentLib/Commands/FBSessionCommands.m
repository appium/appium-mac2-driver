/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBSessionCommands.h"

#import "AMSessionCapabilities.h"
#import "AMSettings.h"
#import "FBConfiguration.h"
#import "FBLogger.h"
#import "FBProtocolHelpers.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "FBRuntimeUtils.h"
#import "XCUIApplication+AMHelpers.h"
#import "XCUIApplication+AMUIInterruptions.h"

const static NSString *CAPABILITIES_KEY = @"capabilities";

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
  if (![request.arguments[CAPABILITIES_KEY] isKindOfClass:NSDictionary.class]) {
    NSString *message = [NSString stringWithFormat:@"'%@' key is mandatory to create a new session", CAPABILITIES_KEY];
    return FBResponseWithStatus([FBCommandStatus sessionNotCreatedError:message
                                                              traceback:nil]);
  }

  NSError *error;
  NSDictionary<NSString *, id> *requirements = FBParseCapabilities([request requireDictionaryArgumentWithName:(NSString *)CAPABILITIES_KEY], &error);
  if (nil == requirements) {
    return FBResponseWithStatus([FBCommandStatus sessionNotCreatedError:error.description
                                                              traceback:nil]);
  }

  NSString *bundleID = requirements[AM_BUNDLE_ID_CAPABILITY];
  BOOL noReset = [requirements[AM_NO_RESET_CAPABILITY] boolValue];
  FBSession *session;
  if (nil == bundleID) {
    session = [FBSession initWithApplication:nil];
  } else {
    XCUIApplication *app = [[XCUIApplication alloc] initWithBundleIdentifier:bundleID];
    session = [FBSession initWithApplication:app];
    if (noReset && app.state > XCUIApplicationStateNotRunning) {
      [app activate];
    } else {
      app.launchArguments = (NSArray<NSString *> *)requirements[AM_APP_ARGUMENTS_CAPABILITY] ?: @[];
      app.launchEnvironment = (NSDictionary <NSString *, NSString *> *)requirements[AM_APP_ENVIRONMENT_CAPABILITY] ?: @{};
      [app launch];
      if (app.state <= XCUIApplicationStateNotRunning) {
        NSString *message = [NSString stringWithFormat:@"Failed to launch '%@' application", bundleID];
        return FBResponseWithStatus([FBCommandStatus sessionNotCreatedError:message
                                                                  traceback:nil]);
      }
    }
  }
  if (nil != requirements[AM_SKIP_APP_KILL_CAPABILITY]) {
    session.skipAppTermination = [requirements[AM_SKIP_APP_KILL_CAPABILITY] boolValue];
  } else if (nil == bundleID) {
    // never kill apps that we don't "own"
    session.skipAppTermination = YES;
  } else {
    session.skipAppTermination = noReset;
  }

  return FBResponseWithObject(FBSessionCommands.sessionInformation);
}

+ (id<FBResponsePayload>)handleSessionAppLaunch:(FBRouteRequest *)request
{
  [request.session launchApplicationWithBundleId:[request requireStringArgumentWithName:@"bundleId"]
                                       arguments:request.arguments[@"arguments"]
                                     environment:request.arguments[@"environment"]];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleSessionAppActivate:(FBRouteRequest *)request
{
  [request.session activateApplicationWithBundleId:[request requireStringArgumentWithName:@"bundleId"]];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleSessionAppTerminate:(FBRouteRequest *)request
{
  BOOL result = [request.session terminateApplicationWithBundleId:[request requireStringArgumentWithName:@"bundleId"]];
  return FBResponseWithObject(@(result));
}

+ (id<FBResponsePayload>)handleSessionAppState:(FBRouteRequest *)request
{
  NSUInteger state = [request.session applicationStateWithBundleId:[request requireStringArgumentWithName:@"bundleId"]];
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
  XCUIApplication *application = FBSession.activeSession.currentApplication;
  return FBResponseWithObject(
    @{
      AM_BOUND_ELEMENTS_BY_INDEX_SETTING: @([FBConfiguration.sharedConfiguration boundElementsByIndex]),
      AM_USE_DEFAULT_UI_INTERRUPTIONS_HANDLING_SETTING: @(!application.am_doesNotHandleUIInterruptions),
    }
  );
}

+ (id<FBResponsePayload>)handleSetSettings:(FBRouteRequest *)request
{
  NSDictionary* settings = [request requireDictionaryArgumentWithName:@"settings"];

  if (nil != [settings objectForKey:AM_BOUND_ELEMENTS_BY_INDEX_SETTING]) {
    FBConfiguration.sharedConfiguration.boundElementsByIndex = [[settings objectForKey:AM_BOUND_ELEMENTS_BY_INDEX_SETTING] boolValue];
  }
  if (nil != [settings objectForKey:AM_USE_DEFAULT_UI_INTERRUPTIONS_HANDLING_SETTING]) {
    XCUIApplication *application = FBSession.activeSession.currentApplication;
    application.am_doesNotHandleUIInterruptions = ![[settings objectForKey:AM_USE_DEFAULT_UI_INTERRUPTIONS_HANDLING_SETTING] boolValue];
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
    @"sessionId" : FBSession.activeSession.identifier ?: NSNull.null,
    @"capabilities" : FBSessionCommands.currentCapabilities
  };
}

+ (NSDictionary *)currentCapabilities
{
  XCUIApplication *application = FBSession.activeSession.currentApplication;
  return @{
    @"CFBundleIdentifier": application.am_bundleID ?: [NSNull null],
  };
}

@end
