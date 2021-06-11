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

@interface XCUIElement (AMSwipe)

/**
 * Performs swipe gesture on the element
 *
 * @param direction Swipe direction. The following values are supported: up, down, left and right
 * @param velocity Swipe speed in pixels per second. This parameter is only supported since Xcode 11.4
 * nil value means that the default velocity is going to be used.
 * @param error The actual error description if the method fails to perform swipe
 * @returns YES if the swipe action was successful
 */
- (BOOL)am_swipeWithDirection:(NSString *)direction
                     velocity:(nullable NSNumber *)velocity
                        error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
