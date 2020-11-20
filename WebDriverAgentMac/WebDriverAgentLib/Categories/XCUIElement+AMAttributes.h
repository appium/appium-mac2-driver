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

@interface XCUIElement (AMAttributes)

/**
 Retrieves WebDriver-compatible value for the given attribute name

 @param name one of supported attribute names. See https://developer.apple.com/documentation/xctest/xcuielementattributes?language=objc
 @return The attribute value converted to a string or nil. Only `frame` value is returned as dictionary
 */
- (nullable id)am_wdAttributeValueWithName:(NSString *)name;

/**
 Element rectangle in dictionary representation
 */
- (NSDictionary<NSString *, NSNumber *> *)am_rect;

/**
 Element text
 */
- (nullable NSString *)am_text;

/**
 Element type represented as string
 */
- (NSString *)am_type;

/**
 Results in YES if the current element has the keyboard input focus
 */
- (BOOL)am_hasKeyboardInputFocus;

@end

NS_ASSUME_NONNULL_END
