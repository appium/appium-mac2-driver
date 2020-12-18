/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBSession.h"
#import "FBSession-Private.h"

#import <objc/runtime.h>

#import "FBConfiguration.h"
#import "FBElementCache.h"
#import "FBExceptions.h"
#import "FBMacros.h"
#import "XCUIApplication+AMHelpers.h"

NSString *const FINDER_BUNDLE_ID = @"com.apple.finder";

@interface FBSession ()
@property (nonatomic, nullable) XCUIApplication *testedApplication;
@end

@implementation FBSession

static FBSession *_activeSession = nil;

+ (instancetype)activeSession
{
  return _activeSession;
}

+ (void)markSessionActive:(FBSession *)session
{
  [_activeSession kill];
  _activeSession = session;
}

+ (instancetype)sessionWithIdentifier:(NSString *)identifier
{
  if (!identifier) {
    return nil;
  }
  if (![identifier isEqualToString:_activeSession.identifier]) {
    return nil;
  }
  return _activeSession;
}

+ (instancetype)initWithApplication:(XCUIApplication *)application
{
  FBSession *session = [FBSession new];
  session.identifier = [[NSUUID UUID] UUIDString];
  session.testedApplication = application;
  session.elementCache = [FBElementCache new];
  [FBSession markSessionActive:session];
  return session;
}

- (void)kill
{
  if (!self.skipAppTermination
      && nil != self.testedApplication
      && self.testedApplication.state > XCUIApplicationStateNotRunning
      && ![self.testedApplication.am_bundleID isEqualToString:FINDER_BUNDLE_ID]) {
    [self.testedApplication terminate];
  }
  self.testedApplication = nil;
  [self.elementCache reset];
  _activeSession = nil;
}

- (XCUIApplication *)currentApplication
{
  if (nil != self.testedApplication) {
    if (self.testedApplication.state <= XCUIApplicationStateNotRunning) {
      NSString *description = @"The application under test is not running, possibly crashed";
      @throw [NSException exceptionWithName:FBApplicationCrashedException reason:description userInfo:nil];
    }
    return self.testedApplication;
  }
  return [[XCUIApplication alloc] initWithBundleIdentifier:FINDER_BUNDLE_ID];
}

- (XCUIApplication *)launchApplicationWithBundleId:(NSString *)bundleIdentifier
                                         arguments:(nullable NSArray<NSString *> *)arguments
                                       environment:(nullable NSDictionary <NSString *, NSString *> *)environment
{
  XCUIApplication *app = [[XCUIApplication alloc] initWithBundleIdentifier:bundleIdentifier];
  if (app.state <= XCUIApplicationStateNotRunning) {
    app.launchArguments = arguments ?: @[];
    app.launchEnvironment = environment ?: @{};
    [app launch];
  } else {
    [app activate];
  }
  self.testedApplication = app;
  return app;
}

- (XCUIApplication *)activateApplicationWithBundleId:(NSString *)bundleIdentifier
{
  BOOL isCurrentApp = nil != self.testedApplication
    && [self.testedApplication.am_bundleID isEqualToString:bundleIdentifier];
  XCUIApplication *app = isCurrentApp
    ? self.testedApplication
    : [[XCUIApplication alloc] initWithBundleIdentifier:bundleIdentifier];
  [app activate];
  if (!isCurrentApp) {
    self.testedApplication = app;
  }
  return app;
}

- (BOOL)terminateApplicationWithBundleId:(NSString *)bundleIdentifier
{
  BOOL isCurrentApp = nil != self.testedApplication && [self.testedApplication.am_bundleID isEqualToString:bundleIdentifier];
  XCUIApplication *app = isCurrentApp
    ? self.testedApplication
    : [[XCUIApplication alloc] initWithBundleIdentifier:bundleIdentifier];
  BOOL result = NO;
  if (app.state > XCUIApplicationStateNotRunning) {
    [app terminate];
    result = YES;
  }
  if (isCurrentApp) {
    self.testedApplication = nil;
  }
  return result;
}

- (NSUInteger)applicationStateWithBundleId:(NSString *)bundleIdentifier
{
  XCUIApplication *app = (nil != self.testedApplication && [self.testedApplication.am_bundleID isEqualToString:bundleIdentifier])
    ? self.testedApplication
    : [[XCUIApplication alloc] initWithBundleIdentifier:bundleIdentifier];
  return app.state;
}

@end
