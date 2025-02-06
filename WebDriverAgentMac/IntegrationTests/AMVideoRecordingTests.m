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

#import <XCTest/XCTest.h>

#import "AMIntegrationTestCase.h"
#import "AMVideoRecorder.h"
#import "FBScreenRecordingRequest.h"
#import "FBTestMacros.h"
#import "FBScreenRecordingContainer.h"
#import "FBScreenRecordingPromise.h"


@interface AMVideoRecordingTests : AMIntegrationTestCase
@end

@implementation AMVideoRecordingTests

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
  });
}

- (void)testVideoRecording
{
  AMVideoRecorder *recorder = AMVideoRecorder.sharedInstance;
  FBScreenRecordingRequest *request = [[FBScreenRecordingRequest alloc] initWithFps:24
                                                                              codec:0
                                                                          displayID:nil];
  NSError *error;
  FBScreenRecordingPromise *promise = [recorder startScreenRecordingWithRequest:request
                                                                          error:&error];
  XCTAssertNotNil(promise);
  XCTAssertNil(error);
  FBWaitExact(5);
  XCTAssertTrue([recorder stopScreenRecordingWithUUID:promise.identifier error:&error]);
  XCTAssertNil(error);
}

@end
