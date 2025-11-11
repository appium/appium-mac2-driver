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
#import "FBConfiguration.h"
#import "FBElementTypeTransformer.h"
#import "FBElementUtils.h"
#import "FBExceptions.h"
#import "FBMacros.h"
#import "XCUIElementQuery+AMHelpers.h"

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
    return FBBoolToStr(self.hittable);
  } else if ([wdAttributeName isEqualToString:@"enabled"]) {
    return FBBoolToStr(self.enabled);
  } else if ([wdAttributeName isEqualToString:@"focused"]) {
    return FBBoolToStr(self.am_hasKeyboardInputFocus);
  } else if ([wdAttributeName isEqualToString:@"selected"]) {
    return FBBoolToStr(self.selected);
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
  if (!FBConfiguration.sharedConfiguration.fetchFullText) {
    return [self am_textWithSource:self];
  }

  NSError *error;
  XCUIElementQuery *query = [self valueForKey:@"query"];
  id<XCUIElementAttributes> snapshot = [query am_uniqueSnapshotWithError:&error];
  if (nil != snapshot) {
    return [self am_textWithSource:snapshot];
  }

  NSString *reason = [NSString stringWithFormat:@"Cannot extract the full text of '%@' element. Original error: %@",
    self.description, error.description];
  @throw [NSException exceptionWithName:FBInvalidElementStateException reason:reason userInfo:@{}];
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

- (NSString *)am_textWithSource:(id<XCUIElementAttributes>)source
{
  NSArray<NSString *> *candidates = @[
    [FBElementUtils stringValueWithValue:source.value],
    source.label,
    source.placeholderValue,
    source.title
  ];
  for (NSString *text in candidates) {
    if (nil != text && text.length > 0) {
      return text;
    }
  }
  return @"";
}

@end
