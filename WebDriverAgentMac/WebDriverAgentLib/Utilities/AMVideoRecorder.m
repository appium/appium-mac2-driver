/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * See the NOTICE file distributed with this work for additional
 * information regarding copyright ownership.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "AMVideoRecorder.h"

#import "FBErrorBuilder.h"
#import "FBScreenRecordingPromise.h"
#import "FBScreenRecordingRequest.h"
#import "FBRunLoopSpinner.h"
#import "AMXCTRunnerDaemonSessionWrapper.h"
#import "AMXCTRunnerDaemonSession.h"


@implementation AMVideoRecorder

+ (instancetype)sharedInstance
{
  static AMVideoRecorder *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (FBScreenRecordingPromise *)startScreenRecordingWithRequest:(FBScreenRecordingRequest *)request
                                                        error:(NSError *__autoreleasing*)error
{
  AMXCTRunnerDaemonSessionWrapper *wrapper = AMXCTRunnerDaemonSessionWrapper.sharedInstance;
  if (!wrapper.canRecordVideo) {
    [[[FBErrorBuilder builder]
      withDescriptionFormat:@"The current Xcode SDK does not support screen recording. Consider upgrading to Xcode 15+"]
     buildError:error];
    return nil;
  }
  if (![wrapper.daemonSession supportsScreenRecording]) {
    [[[FBErrorBuilder builder]
      withDescriptionFormat:@"Your device does not support screen recording"]
     buildError:error];
    return nil;
  }

  id nativeRequest = [request toNativeRequestWithError:error];
  if (nil == nativeRequest) {
    return nil;
  }

  __block id futureMetadata = nil;
  __block NSError *innerError = nil;
  [FBRunLoopSpinner spinUntilCompletion:^(void(^completion)(void)){
    [wrapper.daemonSession startScreenRecordingWithRequest:nativeRequest withReply:^(id reply, NSError *invokeError) {
      if (nil == invokeError) {
        futureMetadata = reply;
      } else {
        innerError = invokeError;
      }
      completion();
    }];
  }];
  if (nil != innerError) {
    if (error) {
      *error = innerError;
    }
    return nil;
  }
  return [[FBScreenRecordingPromise alloc] initWithNativePromise:futureMetadata];
}

- (BOOL)stopScreenRecordingWithUUID:(NSUUID *)uuid error:(NSError *__autoreleasing*)error
{
  AMXCTRunnerDaemonSessionWrapper *wrapper = AMXCTRunnerDaemonSessionWrapper.sharedInstance;
  if (!wrapper.canRecordVideo) {
    return [[[FBErrorBuilder builder]
             withDescriptionFormat:@"The current Xcode SDK does not support screen recording. Consider upgrading to Xcode 15+"]
            buildError:error];

  }
  if (![wrapper.daemonSession supportsScreenRecording]) {
    return [[[FBErrorBuilder builder]
             withDescriptionFormat:@"Your device does not support screen recording"]
            buildError:error];
  }

  __block NSError *innerError = nil;
  [FBRunLoopSpinner spinUntilCompletion:^(void(^completion)(void)){
    [wrapper.daemonSession stopScreenRecordingWithUUID:uuid withReply:^(NSError *invokeError) {
      if (nil != invokeError) {
        innerError = invokeError;
      }
      completion();
    }];
  }];
  if (nil != innerError && error) {
    *error = innerError;
  }
  return nil == innerError;
}

@end
