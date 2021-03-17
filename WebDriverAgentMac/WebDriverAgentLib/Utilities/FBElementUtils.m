/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBElementUtils.h"

#import "FBExceptions.h"
#import "FBMacros.h"

@implementation FBElementUtils

+ (NSString *)wdAttributeNameForAttributeName:(NSString *)name
{
  NSAssert(name.length > 0, @"Attribute name cannot be empty", nil);
  if (![self.class.wdAttributeNames containsObject:name]) {
    NSString *description = [NSString stringWithFormat:@"The attribute '%@' is unknown. Valid attribute names are: %@",
                             name, [self.class.wdAttributeNames sortedArrayUsingSelector:@selector(compare:)]];
    @throw [NSException exceptionWithName:FBElementAttributeUnknownException
                                   reason:description
                                 userInfo:@{}];
  }
  return name;
}

+ (NSArray<NSString *> *)wdAttributeNames
{
  static NSArray *attributeNames;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    attributeNames = @[
      @"selected",
      @"hittable",
      FBStringify(XCUIElement, placeholderValue),
      @"enabled",
      FBStringify(XCUIElement, elementType),
      FBStringify(XCUIElement, label),
      FBStringify(XCUIElement, title),
      FBStringify(XCUIElement, value),
      FBStringify(XCUIElement, frame),
      FBStringify(XCUIElement, identifier)
    ];
  });
  return attributeNames;
}

+ (NSString *)stringValueWithValue:(id)value
{
  if (nil == value) {
    return nil;
  }

  if ([value isKindOfClass:[NSValue class]]) {
    return [value stringValue];
  } else if ([value isKindOfClass:[NSString class]]) {
    return value;
  }
  return [value description];
}

@end
