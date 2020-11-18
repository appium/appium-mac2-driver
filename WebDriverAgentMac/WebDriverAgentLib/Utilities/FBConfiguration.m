/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBConfiguration.h"

#include "TargetConditionals.h"
#include <dlfcn.h>

static NSUInteger const DefaultStartingPort = 8100;
static NSUInteger const DefaultPortRange = 100;

static BOOL FBShouldUseFirstMatch = NO;
static BOOL FBShouldBoundElementsByIndex = NO;
// This is diabled by default because enabling it prevents the accessbility snapshot to be taken
// (it always errors with kxIllegalArgument error)
static BOOL FBIncludeNonModalElements = NO;

@implementation FBConfiguration

#pragma mark Public

+ (void)disableRemoteQueryEvaluation
{
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"XCTDisableRemoteQueryEvaluation"];
}

+ (void)disableAttributeKeyPathAnalysis
{
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"XCTDisableAttributeKeyPathAnalysis"];
}

+ (void)disableScreenshots
{
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DisableScreenshots"];
}

+ (NSRange)bindingPortRange
{
  // 'WebDriverAgent --port 8080' can be passed via the arguments to the process
  if (self.bindingPortRangeFromArguments.location != NSNotFound) {
    return self.bindingPortRangeFromArguments;
  }

  // Existence of USE_PORT in the environment implies the port range is managed by the launching process.
  if (NSProcessInfo.processInfo.environment[@"USE_PORT"] &&
      [NSProcessInfo.processInfo.environment[@"USE_PORT"] length] > 0) {
    return NSMakeRange([NSProcessInfo.processInfo.environment[@"USE_PORT"] integerValue] , 1);
  }

  return NSMakeRange(DefaultStartingPort, DefaultPortRange);
}

+ (BOOL)verboseLoggingEnabled
{
  return [NSProcessInfo.processInfo.environment[@"VERBOSE_LOGGING"] boolValue];
}

+ (void)setUseFirstMatch:(BOOL)enabled
{
  FBShouldUseFirstMatch = enabled;
}

+ (BOOL)useFirstMatch
{
  return FBShouldUseFirstMatch;
}

+ (void)setBoundElementsByIndex:(BOOL)enabled
{
  FBShouldBoundElementsByIndex = enabled;
}

+ (BOOL)boundElementsByIndex
{
  return FBShouldBoundElementsByIndex;
}

+ (void)setIncludeNonModalElements:(BOOL)isEnabled
{
  FBIncludeNonModalElements = isEnabled;
}

+ (BOOL)includeNonModalElements
{
  return FBIncludeNonModalElements;
}

#pragma mark Private

+ (NSString*)valueFromArguments: (NSArray<NSString *> *)arguments forKey: (NSString*)key
{
  NSUInteger index = [arguments indexOfObject:key];
  if (index == NSNotFound || index == arguments.count - 1) {
    return nil;
  }
  return arguments[index + 1];
}

+ (NSRange)bindingPortRangeFromArguments
{
  NSString *portNumberString = [self valueFromArguments:NSProcessInfo.processInfo.arguments
                                                 forKey: @"--port"];
  NSUInteger port = (NSUInteger)[portNumberString integerValue];
  if (port == 0) {
    return NSMakeRange(NSNotFound, 0);
  }
  return NSMakeRange(port, 1);
}

@end
