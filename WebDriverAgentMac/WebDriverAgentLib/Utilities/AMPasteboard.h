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

NS_ASSUME_NONNULL_BEGIN

@interface AMPasteboard : NSObject

/**
 Sets data to the general pasteboard

 @param data base64-encoded string containing the data chunk which is going to be written to the pasteboard
 @param type one of the possible data types to set: plaintext, url, image
 @param error If there is an error, upon return contains an NSError object that describes the problem
 @return YES if the operation was successful
 */
+ (BOOL)setData:(NSData *)data forType:(NSString *)type error:(NSError **)error;

/**
 Gets the data contained in the general pasteboard

 @param type one of the possible data types to get: plaintext, url, image
 @param error If there is an error, upon return contains an NSError object that describes the problem
 @return NSData object, containing the pasteboard content or an empty string if the pasteboard is empty.
 nil is returned if there was an error while getting the data from the pasteboard
 */
+ (nullable NSData *)dataForType:(NSString *)type error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

