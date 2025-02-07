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
#import "FBScreenRecordingContainer.h"
#import "FBScreenRecordingPromise.h"
#import "AMVideoRecorder.h"

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
  FBScreenRecordingContainer *screenRecordingContainer = FBScreenRecordingContainer.sharedInstance;
  NSUUID *videoRecordingId = screenRecordingContainer.screenRecordingPromise.identifier;
  if (nil != videoRecordingId) {
    NSError *error;
    if (![AMVideoRecorder.sharedInstance stopScreenRecordingWithUUID:videoRecordingId error:&error]) {
      NSLog(@"Could not stop the active video recording. Original error: %@", error.description);
    }
  }
  if (nil != screenRecordingContainer.screenRecordingPromise) {
    [screenRecordingContainer reset];
  }
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

- (XCUIApplication *)launchApplicationWithBundleId:(nullable NSString *)bundleIdentifier
                                              path:(nullable NSString *)path
                                         arguments:(nullable NSArray<NSString *> *)arguments
                                       environment:(nullable NSDictionary <NSString *, NSString *> *)environment
{
  XCUIApplication *app = [self applicationWithBundleId:bundleIdentifier orPath:path];
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

- (XCUIApplication *)activateApplicationWithBundleId:(nullable NSString *)bundleIdentifier
                                                path:(nullable NSString *)path
{
  BOOL isCurrentApp = [self isCurrentApplicationForBundleId:bundleIdentifier orPath:path];
  XCUIApplication *app = isCurrentApp
    ? self.testedApplication
    : [self applicationWithBundleId:bundleIdentifier orPath:path];
  [app activate];
  if (!isCurrentApp) {
    self.testedApplication = app;
  }
  return app;
}

- (BOOL)terminateApplicationWithBundleId:(nullable NSString *)bundleIdentifier
                                    path:(nullable NSString *)path
{
  BOOL isCurrentApp = [self isCurrentApplicationForBundleId:bundleIdentifier orPath:path];
  XCUIApplication *app = isCurrentApp
    ? self.testedApplication
    : [self applicationWithBundleId:bundleIdentifier orPath:path];
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

- (NSUInteger)applicationStateWithBundleId:(nullable NSString *)bundleIdentifier
                                      path:(nullable NSString *)path
{
  XCUIApplication *app = [self isCurrentApplicationForBundleId:bundleIdentifier orPath:path]
    ? self.testedApplication
    : [self applicationWithBundleId:bundleIdentifier orPath:path];
  return app.state;
}

- (BOOL)isCurrentApplicationForBundleId:(nullable NSString *)bundleId
                                 orPath:(nullable NSString *)path
{
  if (nil == self.testedApplication) {
    return NO;
  }
  if (nil != path) {
    NSURL *appUrl = [NSURL fileURLWithPath:self.testedApplication.am_path].URLByStandardizingPath;
    NSURL *expectedUrl = [NSURL fileURLWithPath:path].URLByStandardizingPath;
    return [appUrl.path compare:expectedUrl.path] == NSOrderedSame;
  }
  return nil != bundleId && [self.testedApplication.am_bundleID isEqualToString:bundleId];
}

- (XCUIApplication *)applicationWithBundleId:(nullable NSString *)bundleId
                                      orPath:(nullable NSString *)path
{
  if (nil == bundleId && nil == path) {
    @throw [NSException exceptionWithName:FBInvalidArgumentException
                                   reason:@"Either app bundle identifier or app path must be provided"
                                 userInfo:@{}];
  }
  return nil != path
    ? [[XCUIApplication alloc] initWithURL:[NSURL fileURLWithPath:(id)path]]
    : [[XCUIApplication alloc] initWithBundleIdentifier:(id)bundleId];
}

@end
