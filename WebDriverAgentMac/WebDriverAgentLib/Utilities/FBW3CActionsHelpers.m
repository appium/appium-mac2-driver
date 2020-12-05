/**
* Copyright (c) 2015-present, Facebook, Inc.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

#import "FBW3CActionsHelpers.h"

#import "FBErrorBuilder.h"
#import "FBLogger.h"

static NSString *const FB_ACTION_ITEM_KEY_VALUE = @"value";
static NSString *const FB_ACTION_ITEM_KEY_DURATION = @"duration";
NSUInteger const AM_LEFT_BUTTON_CODE = 0x1;
NSUInteger const AM_RIGHT_BUTTON_CODE = 0x2;

NSString *FBRequireValue(NSDictionary<NSString *, id> *actionItem, NSError **error)
{
  id value = [actionItem objectForKey:FB_ACTION_ITEM_KEY_VALUE];
  if (![value isKindOfClass:NSString.class] || [value length] == 0) {
    NSString *description = [NSString stringWithFormat:@"Key value must be present and should be a valid non-empty string for '%@'", actionItem];
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:description] build];
    }
    return nil;
  }
  NSRange r = [(NSString *)value rangeOfComposedCharacterSequenceAtIndex:0];
  return [(NSString *)value substringWithRange:r];
}

NSNumber *_Nullable FBOptDuration(NSDictionary<NSString *, id> *actionItem, NSNumber *defaultValue, NSError **error)
{
  NSNumber *durationObj = [actionItem objectForKey:FB_ACTION_ITEM_KEY_DURATION];
  if (nil == durationObj) {
    if (nil == defaultValue) {
      NSString *description = [NSString stringWithFormat:@"Duration must be present for '%@' action item", actionItem];
      if (error) {
        *error = [[FBErrorBuilder.builder withDescription:description] build];
      }
      return nil;
    }
    return defaultValue;
  }
  if ([durationObj doubleValue] < 0.0) {
    NSString *description = [NSString stringWithFormat:@"Duration must be a valid positive number for '%@' action item", actionItem];
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:description] build];
    }
    return nil;
  }
  return durationObj;
}

BOOL FBIsMetaModifier(NSString *value)
{
  unichar charCode = [value characterAtIndex:0];
  return charCode == 0xE000
    || charCode == 0xE03D
    || charCode == 0xE009
    || charCode == 0xE00A
    || charCode == 0xE008;
}

NSUInteger FBToMetaModifier(NSString *value, BOOL reverse)
{
  if (!FBIsMetaModifier(value)) {
    return 0;
  }

  unichar charCode = [value characterAtIndex:0];
  NSUInteger result = 0;
  switch (charCode) {
    case 0xE000:
      result = XCUIKeyModifierNone;
      break;
    case 0xE03D:
      result = XCUIKeyModifierCommand;
      break;
    case 0xE009:
      result = XCUIKeyModifierControl;
      break;
    case 0xE00A:
      result = XCUIKeyModifierOption;
      break;
    case 0xE008:
      result = XCUIKeyModifierShift;
      break;
    default:
      [FBLogger logFmt:@"Skipping the unsupported meta modifier with code %@", @(charCode)];
      result = 0;
      break;
  }
  if (reverse) {
    result = ~result;
  }
  return result;
}

NSUInteger AMToXCTestButtonCode(NSUInteger w3cButtonCode)
{
  switch (w3cButtonCode) {
    case 0:
      return AM_LEFT_BUTTON_CODE;
    case 1:
      return 0x3;
    case 2:
      return AM_RIGHT_BUTTON_CODE;
    default:
      return AM_LEFT_BUTTON_CODE;
  }
}
