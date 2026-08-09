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
#import "AMSnapshotUtils.h"
#import "FBConfiguration.h"
#import "FBElementTypeTransformer.h"
#import "FBElementUtils.h"
#import "FBExceptions.h"
#import "FBMacros.h"
#import "XCUIElementQuery+AMHelpers.h"

NSString *const AM_IDENTIFIER_ATTRIBUTE_NAME = @"amIdentifier";
NSString *const AM_RECT_ATTRIBUTE_NAME = @"amRect";
NSString *const AM_TEXT_ATTRIBUTE_NAME = @"amText";
NSString *const AM_TYPE_ATTRIBUTE_NAME = @"amType";
NSString *const AM_HAS_KEYBOARD_INPUT_FOCUS_ATTRIBUTE_NAME = @"amHasKeyboardInputFocus";

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
  } else if ([wdAttributeName isEqualToString:FBStringify(XCUIElement, identifier)]
             || [wdAttributeName isEqualToString:AM_IDENTIFIER_ATTRIBUTE_NAME]) {
    return self.am_identifier;
  } else if ([wdAttributeName isEqualToString:AM_RECT_ATTRIBUTE_NAME]) {
    return self.am_rect;
  } else if ([wdAttributeName isEqualToString:AM_TEXT_ATTRIBUTE_NAME]) {
    return self.am_text;
  } else if ([wdAttributeName isEqualToString:AM_TYPE_ATTRIBUTE_NAME]) {
    return self.am_type;
  } else if ([wdAttributeName isEqualToString:AM_HAS_KEYBOARD_INPUT_FOCUS_ATTRIBUTE_NAME]) {
    return FBBoolToStr(self.am_hasKeyboardInputFocus);
  }
  // This should not happen
  NSString *description = [NSString stringWithFormat:@"The attribute '%@' is unknown", wdAttributeName];
  @throw [NSException exceptionWithName:FBElementAttributeUnknownException
                                 reason:description
                               userInfo:@{}];
}

+ (NSArray<NSString *> *)am_predicateAttributeNames
{
  return @[
    AM_IDENTIFIER_ATTRIBUTE_NAME,
    AM_RECT_ATTRIBUTE_NAME,
    AM_TEXT_ATTRIBUTE_NAME,
    AM_TYPE_ATTRIBUTE_NAME,
    AM_HAS_KEYBOARD_INPUT_FOCUS_ATTRIBUTE_NAME,
  ];
}

+ (nullable id)am_valueForPredicateAttributeName:(NSString *)name target:(id)target
{
  if ([name isEqualToString:AM_IDENTIFIER_ATTRIBUTE_NAME]) {
    NSString *identifier = [target valueForKey:@"identifier"];
    // Snapshotting is not free, so only pay for it when the fallback can apply.
    if (identifier.length > 0 || !FBConfiguration.sharedConfiguration.useDomIdAsAccessibilityId) {
      return identifier;
    }
    // domIdentifierWithSnapshot: relies on snapshot-only key paths (_accessibilityElement._token),
    // which a live XCUIElement does not have, so it must be snapshotted first.
    id snapshotTarget = [target isKindOfClass:XCUIElement.class]
      ? [(XCUIElement *)target snapshotWithError:nil]
      : target;
    return [AMSnapshotUtils domIdentifierWithSnapshot:snapshotTarget] ?: identifier;
  }
  if ([name isEqualToString:AM_RECT_ATTRIBUTE_NAME]) {
    return AMCGRectToDict([[target valueForKey:@"frame"] rectValue]);
  }
  if ([name isEqualToString:AM_TEXT_ATTRIBUTE_NAME]) {
    return [self am_textWithSource:target];
  }
  if ([name isEqualToString:AM_TYPE_ATTRIBUTE_NAME]) {
    return [FBElementTypeTransformer stringWithElementType:[[target valueForKey:@"elementType"] unsignedLongLongValue]];
  }
  if ([name isEqualToString:AM_HAS_KEYBOARD_INPUT_FOCUS_ATTRIBUTE_NAME]) {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hasKeyboardFocus == YES"];
    return @([predicate evaluateWithObject:target]);
  }
  return nil;
}

- (NSString *)am_identifier
{
  return [self.class am_valueForPredicateAttributeName:AM_IDENTIFIER_ATTRIBUTE_NAME target:self];
}

- (NSDictionary<NSString *, NSNumber *> *)am_rect
{
  return [self.class am_valueForPredicateAttributeName:AM_RECT_ATTRIBUTE_NAME target:self];
}

- (NSString *)am_text
{
  if (!FBConfiguration.sharedConfiguration.fetchFullText) {
    return [self.class am_valueForPredicateAttributeName:AM_TEXT_ATTRIBUTE_NAME target:self];
  }

  NSError *error;
  XCUIElementQuery *query = [self valueForKey:@"query"];
  id<XCUIElementAttributes> snapshot = [query am_uniqueSnapshotWithError:&error];
  if (nil != snapshot) {
    return [self.class am_valueForPredicateAttributeName:AM_TEXT_ATTRIBUTE_NAME target:snapshot];
  }

  NSString *reason = [NSString stringWithFormat:@"Cannot extract the full text of '%@' element. Original error: %@",
    self.description, error.description];
  @throw [NSException exceptionWithName:FBInvalidElementStateException reason:reason userInfo:@{}];
}

- (NSString *)am_type
{
  return [self.class am_valueForPredicateAttributeName:AM_TYPE_ATTRIBUTE_NAME target:self];
}

- (BOOL)am_hasKeyboardInputFocus
{
  return [[self.class am_valueForPredicateAttributeName:AM_HAS_KEYBOARD_INPUT_FOCUS_ATTRIBUTE_NAME target:self] boolValue];
}

+ (NSString *)am_textWithSource:(id<XCUIElementAttributes>)source
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
