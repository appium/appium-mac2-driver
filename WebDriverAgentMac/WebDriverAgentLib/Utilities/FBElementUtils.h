/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBElementUtils : NSObject

/**
 Returns property name if it is defined by XCTest's XCUIElementAttributes protocol
 
 @param name WebDriver Spec property name
 @return the corresponding property name
 @throws FBElementAttributeUnknownException if there is no matching attribute defined by XCTest
 */
+ (NSString *)wdAttributeNameForAttributeName:(NSString *)name;

/**
 Returns available attributes names of an element
 
 @return list of attribute names, basically memebers of XCUIElementAttributeName enum
 */
+ (NSArray<NSString *> *)wdAttributeNames;

/**
 Converts element's value attribute to a string representation

 @param value the actual value
 @return The string representation of the value
 */
+ (nullable NSString *)stringValueWithValue:(nullable id)value;

@end

NS_ASSUME_NONNULL_END
