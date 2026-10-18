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
 Access to the accessibility interface that XCTest uses itself. XCTest does not call the
 Accessibility API from the test process, but asks a privileged daemon to do that. Therefore,
 this does not need the Accessibility permission to be granted to the process.
 The interface is a private XCTest API, which is why it is always checked for availability.
 */
@interface AMXCTAccessibility : NSObject

/**
 @returns YES if the XCTest accessibility interface is available in the current Xcode version
 */
+ (BOOL)isAvailable;

/**
 @returns The XCTest accessibility element of the snapshot or nil
 */
+ (nullable id)accessibilityElementWithSnapshot:(nullable id)snapshot;

/**
 @returns The XCTest accessibility element of the application or nil
 */
+ (nullable id)accessibilityElementWithApplication:(XCUIApplication *)application;

/**
 Fetches the accessibility attributes of the element.

 @param names AX attribute names, for example AXPosition
 @param element XCTest accessibility element
 @returns The attributes dictionary or nil. Position is {X, Y} and size is {Width, Height}
 */
+ (nullable NSDictionary<NSString *, id> *)attributes:(NSArray<NSString *> *)names
                                            ofElement:(id)element;

/**
 Performs the AXPress action on the element
 */
+ (BOOL)pressElement:(id)element error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
