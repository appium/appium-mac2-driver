/**
 *
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBScreenRecordingContainer.h"

#import "AMScreenUtils.h"
#import "FBScreenRecordingPromise.h"

@interface FBScreenRecordingContainer ()

@property (readwrite) NSUInteger fps;
@property (readwrite) long long codec;
@property (readwrite) NSNumber *displayID;
@property (readwrite) FBScreenRecordingPromise* screenRecordingPromise;
@property (readwrite) NSNumber *startedAt;

@end

@implementation FBScreenRecordingContainer

+ (instancetype)sharedInstance
{
  static FBScreenRecordingContainer *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (void)storeScreenRecordingPromise:(FBScreenRecordingPromise *)screenRecordingPromise
                                fps:(NSUInteger)fps
                              codec:(long long)codec
                          displayID:(nullable NSNumber *)displayID
{
  self.fps = fps;
  self.codec = codec;
  self.displayID = displayID;
  self.screenRecordingPromise = screenRecordingPromise;
  self.startedAt = @([NSDate.date timeIntervalSince1970]);
}

- (void)reset;
{
  self.fps = 0;
  self.codec = 0;
  self.displayID = nil;
  self.screenRecordingPromise = nil;
  self.startedAt = nil;
}

- (nullable NSDictionary *)toDictionary
{
  if (nil == self.screenRecordingPromise) {
    return nil;
  }

  return @{
    @"fps": @(self.fps),
    @"codec": @(self.codec),
    @"displayId": self.displayID ?: @(AMFetchScreenId(XCUIScreen.mainScreen)),
    @"uuid": [self.screenRecordingPromise identifier].UUIDString ?: [NSNull null],
    @"startedAt": self.startedAt ?: [NSNull null],
  };
}

@end
