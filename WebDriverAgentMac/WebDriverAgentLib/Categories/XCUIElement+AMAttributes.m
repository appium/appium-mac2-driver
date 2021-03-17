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

#import "XCUIElement+AMAttributes.h"

#import "AMGeometryUtils.h"
#import "FBElementTypeTransformer.h"
#import "FBElementUtils.h"
#import "FBExceptions.h"
#import "FBMacros.h"

@implementation XCUIElement (AMAttributes)

- (id)am_wdAttributeValueWithName:(NSString *)name
{
  NSString *wdAttributeName = [FBElementUtils wdAttributeNameForAttributeName:name];
  if ([wdAttributeName isEqualToString:FBStringify(XCUIElement, frame)]) {
    return self.am_rect;
  } else if ([wdAttributeName isEqualToString:FBStringify(XCUIElement, elementType)]) {
    return [NSString stringWithFormat:@"%lu", self.elementType];
  } else if ([wdAttributeName isEqualToString:FBStringify(XCUIElement, placeholderValue)]) {
    return self.placeholderValue;
  } else if ([wdAttributeName isEqualToString:@"hittable"]) {
    return self.hittable ? @"true" : @"false";
  } else if ([wdAttributeName isEqualToString:@"enabled"]) {
    return self.enabled ? @"true" : @"false";
  } else if ([wdAttributeName isEqualToString:@"selected"]) {
    return self.selected ? @"true" : @"false";
  } else if ([wdAttributeName isEqualToString:FBStringify(XCUIElement, label)]) {
    return self.label;
  } else if ([wdAttributeName isEqualToString:FBStringify(XCUIElement, title)]) {
    return self.title;
  } else if ([wdAttributeName isEqualToString:FBStringify(XCUIElement, value)]) {
    return [FBElementUtils stringValueWithValue:self.value];
  } else if ([wdAttributeName isEqualToString:FBStringify(XCUIElement, identifier)]) {
    return self.identifier;
  }
  // This should not happen
  NSString *description = [NSString stringWithFormat:@"The attribute '%@' is unknown", wdAttributeName];
  @throw [NSException exceptionWithName:FBElementAttributeUnknownException
                                 reason:description
                               userInfo:@{}];
}

- (NSDictionary<NSString *, NSNumber *> *)am_rect
{
  return AMCGRectToDict(self.frame);
}

- (NSString *)am_text
{
  NSString *value = [FBElementUtils stringValueWithValue:self.value];
  if (nil != value && value.length > 0) {
    return value;
  }
  NSString *label = self.label;
  if (nil != label && label.length > 0) {
    return label;
  }
  NSString *placeholderValue = self.placeholderValue;
  if (nil != placeholderValue && placeholderValue.length > 0) {
    return placeholderValue;
  }
  NSString *title = self.title;
  if (nil != title && title.length > 0) {
    return title;
  }
  return @"";
}

- (NSString *)am_type
{
  return [FBElementTypeTransformer stringWithElementType:self.elementType];
}

- (BOOL)am_hasKeyboardInputFocus
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hasKeyboardFocus == YES"];
  return [predicate evaluateWithObject:self];
}

@end
