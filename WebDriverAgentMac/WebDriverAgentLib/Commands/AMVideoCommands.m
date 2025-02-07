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

#import "AMVideoCommands.h"

#import "FBRouteRequest.h"
#import "FBScreenRecordingContainer.h"
#import "FBScreenRecordingPromise.h"
#import "FBScreenRecordingRequest.h"
#import "AMScreenUtils.h"
#import "FBSession.h"
#import "AMVideoRecorder.h"
#import "FBErrorBuilder.h"

const NSUInteger DEFAULT_FPS = 24;
const NSUInteger DEFAULT_CODEC = 0;

@implementation AMVideoCommands

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute POST:@"/wda/video/start"] respondWithTarget:self action:@selector(handleStartVideoRecording:)],
    [[FBRoute POST:@"/wda/video/stop"] respondWithTarget:self action:@selector(handleStopVideoRecording:)],
    [[FBRoute GET:@"/wda/video"] respondWithTarget:self action:@selector(handleGetVideoRecording:)],

    [[FBRoute POST:@"/wda/video/start"].withoutSession respondWithTarget:self action:@selector(handleStartVideoRecording:)],
    [[FBRoute POST:@"/wda/video/stop"].withoutSession respondWithTarget:self action:@selector(handleStopVideoRecording:)],
    [[FBRoute GET:@"/wda/video"].withoutSession respondWithTarget:self action:@selector(handleGetVideoRecording:)],
  ];
}

+ (id<FBResponsePayload>)handleStartVideoRecording:(FBRouteRequest *)request
{
  FBScreenRecordingPromise *activeScreenRecording = FBScreenRecordingContainer.sharedInstance.screenRecordingPromise;
  if (nil != activeScreenRecording) {
    return FBResponseWithObject([FBScreenRecordingContainer.sharedInstance toDictionary] ?: [NSNull null]);
  }

  NSNumber *fps = (NSNumber *)request.arguments[@"fps"] ?: @(DEFAULT_FPS);
  NSNumber *codec = (NSNumber *)request.arguments[@"codec"] ?: @(DEFAULT_CODEC);
  NSNumber *displayID = (NSNumber *)request.arguments[@"displayId"];
  if (nil != displayID) {
    NSError *error;
    if (![self verifyDisplayWithID:displayID.longLongValue error:&error]) {
      return FBResponseWithStatus([FBCommandStatus invalidArgumentErrorWithMessage:error.description
                                                                         traceback:nil]);
    }
  }
  FBScreenRecordingRequest *recordingRequest = [[FBScreenRecordingRequest alloc] initWithFps:fps.integerValue
                                                                                       codec:codec.longLongValue
                                                                                   displayID:displayID];
  NSError *error;
  FBScreenRecordingPromise* promise = [AMVideoRecorder.sharedInstance startScreenRecordingWithRequest:recordingRequest
                                                                                                error:&error];
  if (nil == promise) {
    [FBScreenRecordingContainer.sharedInstance reset];
    return FBResponseWithUnknownError(error);
  }
  [FBScreenRecordingContainer.sharedInstance storeScreenRecordingPromise:promise
                                                                     fps:fps.integerValue
                                                                   codec:codec.longLongValue
                                                               displayID:displayID];
  return FBResponseWithObject([FBScreenRecordingContainer.sharedInstance toDictionary]);
}

+ (id<FBResponsePayload>)handleStopVideoRecording:(FBRouteRequest *)request
{
  FBScreenRecordingPromise *activeScreenRecording = FBScreenRecordingContainer.sharedInstance.screenRecordingPromise;
  if (nil == activeScreenRecording) {
    return FBResponseWithOK();
  }

  NSUUID *recordingId = activeScreenRecording.identifier;
  NSDictionary *response = [FBScreenRecordingContainer.sharedInstance toDictionary];
  NSError *error;
  if (![AMVideoRecorder.sharedInstance stopScreenRecordingWithUUID:recordingId error:&error]) {
    [FBScreenRecordingContainer.sharedInstance reset];
    return FBResponseWithUnknownError(error);
  }
  [FBScreenRecordingContainer.sharedInstance reset];
  return FBResponseWithObject(response);
}

+ (id<FBResponsePayload>)handleGetVideoRecording:(FBRouteRequest *)request
{
  return FBResponseWithObject([FBScreenRecordingContainer.sharedInstance toDictionary] ?: [NSNull null]);
}

+ (BOOL)verifyDisplayWithID:(long long)displayID error:(NSError **)error
{
  NSMutableArray* availableIds = [NSMutableArray array];
  for (XCUIScreen *screen in XCUIScreen.screens) {
    long long currentDisplayId = AMFetchScreenId(screen);
    if (displayID == currentDisplayId) {
      return YES;
    }
    [availableIds addObject:@(currentDisplayId)];
  }
  return [[[FBErrorBuilder builder]
           withDescriptionFormat:@"The provided display identifier %lld is not known. Only the following values are allowed: %@",
           displayID, [availableIds componentsJoinedByString:@","]]
          buildError:error];
}

@end
