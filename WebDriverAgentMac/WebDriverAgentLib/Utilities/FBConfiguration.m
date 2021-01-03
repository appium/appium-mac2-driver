/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBConfiguration.h"

static NSUInteger const DefaultStartingPort = 10100;
static NSUInteger const DefaultPortRange = 100;

static BOOL FBShouldBoundElementsByIndex = NO;

@implementation FBConfiguration

static FBConfiguration *instance;

#pragma mark Public

+ (instancetype)sharedConfiguration
{
  static dispatch_once_t onceInstance;
  dispatch_once(&onceInstance, ^{
    instance = [self new];
  });
  return instance;
}

- (BOOL)remoteQueryEvaluation
{
  id value = [NSUserDefaults.standardUserDefaults objectForKey:@"XCTDisableRemoteQueryEvaluation"];
  return nil == value ? YES : [value boolValue];
}

- (void)setRemoteQueryEvaluation:(BOOL)remoteQueryEvaluation
{
  [[NSUserDefaults standardUserDefaults] setBool:remoteQueryEvaluation
                                          forKey:@"XCTDisableRemoteQueryEvaluation"];
}

- (BOOL)attributeKeyPathAnalysis
{
  id value = [NSUserDefaults.standardUserDefaults objectForKey:@"XCTDisableAttributeKeyPathAnalysis"];
  return nil == value ? YES : [value boolValue];
}

- (void)setAttributeKeyPathAnalysis:(BOOL)attributeKeyPathAnalysis
{
  [[NSUserDefaults standardUserDefaults] setBool:attributeKeyPathAnalysis
                                          forKey:@"XCTDisableAttributeKeyPathAnalysis"];
}

- (BOOL)automaticScreenshots
{
  id value = [NSUserDefaults.standardUserDefaults objectForKey:@"DisableScreenshots"];
  return nil == value ? YES : ![value boolValue];
}

- (void)setAutomaticScreenshots:(BOOL)automaticScreenshots
{
  [[NSUserDefaults standardUserDefaults] setBool:!automaticScreenshots
                                          forKey:@"DisableScreenshots"];
}

- (NSRange)bindingPortRange
{
  // 'WebDriverAgent --port 8080' can be passed via the arguments to the process
  if (self.class.bindingPortRangeFromArguments.location != NSNotFound) {
    return self.class.bindingPortRangeFromArguments;
  }

  // Existence of USE_PORT in the environment implies the port range is managed by the launching process.
  if (NSProcessInfo.processInfo.environment[@"USE_PORT"] &&
      [NSProcessInfo.processInfo.environment[@"USE_PORT"] length] > 0) {
    return NSMakeRange([NSProcessInfo.processInfo.environment[@"USE_PORT"] integerValue], 1);
  }

  return NSMakeRange(DefaultStartingPort, DefaultPortRange);
}

- (NSString *)serverInterface
{
  // Existence of USE_HOST in the environment is managed by the launching process.
  NSString *host = NSProcessInfo.processInfo.environment[@"USE_HOST"];
  if (nil != host && host.length > 0) {
    return [host isEqualToString:@"0.0.0.0"] ? nil : host;
  }

  return @"127.0.0.1";
}

- (BOOL)verboseLoggingEnabled
{
  return [NSProcessInfo.processInfo.environment[@"VERBOSE_LOGGING"] boolValue];
}

- (void)setBoundElementsByIndex:(BOOL)enabled
{
  FBShouldBoundElementsByIndex = enabled;
}

- (BOOL)boundElementsByIndex
{
  return FBShouldBoundElementsByIndex;
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
