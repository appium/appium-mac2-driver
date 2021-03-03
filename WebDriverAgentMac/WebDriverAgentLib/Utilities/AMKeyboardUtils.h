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

/**
 Transforms key name to its string representation, which could be used with XCTest
 If no match is found then the original string is returned

 @param name one of available keyboard key names defined in https://developer.apple.com/documentation/xctest/xcuikeyboardkey?language=objc
 @return Either the key value or the original string if no matches have been found
 */
NSString *AMKeyValueForName(NSString *name);

NS_ASSUME_NONNULL_END
