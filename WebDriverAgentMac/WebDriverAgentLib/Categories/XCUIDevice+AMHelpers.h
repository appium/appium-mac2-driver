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
#import "XCUIApplicationProcessManaging-Protocol.h"

@class XCSynthesizedEventRecord;

NS_ASSUME_NONNULL_BEGIN

@interface XCUIDevice (AMHelpers)

- (BOOL)am_supportsOpenUrl;

/**
 Opens the particular url scheme using the default application assigned to it.
 This API only works since XCode 14.3

 @param url The url scheme represented as a string, for example https://apple.com
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation was successful
 */
- (BOOL)am_openUrl:(NSURL *)url error:(NSError **)error;

/**
 Opens the particular url scheme using the given application
 This API only works since XCode 14.3

 @param url The url scheme represented as a string, for example https://apple.com
 @param bundleId The bundle identifier of an application to use in order to open the given URL
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation was successful
 */
- (BOOL)am_openUrl:(NSURL *)url 
   withApplication:(NSString *)bundleId
             error:(NSError **)error;

/**
 Synthesizes an input event according to the given event spec

 @param event The event spec
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation was successful
 */
- (BOOL)am_synthesizeEvent:(XCSynthesizedEventRecord *)event
                     error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
