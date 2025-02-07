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

#import <Foundation/Foundation.h>

@class FBScreenRecordingPromise;
@class FBScreenRecordingRequest;

NS_ASSUME_NONNULL_BEGIN

@interface AMVideoRecorder : NSObject

+ (instancetype)sharedInstance;

/**
 Starts native video recording

 @param request Video recording options
 @param error Actual error instance if there was an error while starting the video recording
 @returns The recording promise or nil in case of failure
 */
- (nullable FBScreenRecordingPromise *)startScreenRecordingWithRequest:(FBScreenRecordingRequest *)request
                                                                 error:(NSError **)error;

/**
 Stops native video recording

 @param uuid The unique identifier of the recording process
 @param error Actual error instance if there was an error while stopping the video recording
 @returns YES if the recording has been successfully stopped
 */
- (BOOL)stopScreenRecordingWithUUID:(NSUUID *)uuid
                              error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
