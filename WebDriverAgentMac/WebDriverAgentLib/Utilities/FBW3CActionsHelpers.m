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

NSNumber* AMToMetaModifier(NSString *value)
{
  if (0 == value.length) {
    return nil;
  }

  unichar charCode = [value characterAtIndex:0];
  switch (charCode) {
    case 0xE000:
      return @(XCUIKeyModifierNone);
    case 0xE03D:
      return @(XCUIKeyModifierCommand);
    case 0xE009:
      return @(XCUIKeyModifierControl);
    case 0xE00A:
      return @(XCUIKeyModifierOption);
    case 0xE008:
      return @(XCUIKeyModifierShift);
    default:
      return nil;
  }
}

NSString* AMToSpecialKey(NSString *value)
{
  if (0 == [value length]) {
    return nil;
  }

  unichar charCode = [value characterAtIndex:0];
  switch (charCode) {
    case 0xE000:
      return @"";
    case 0xE002:
      return XCUIKeyboardKeyHelp;
    case 0xE003:
      return XCUIKeyboardKeyDelete;
    case 0xE004:
      return XCUIKeyboardKeyTab;
    case 0xE005:
      return XCUIKeyboardKeyClear;
    case 0xE006:
      return XCUIKeyboardKeyReturn;
    case 0xE007:
      return XCUIKeyboardKeyEnter;
    case 0xE00C:
      return XCUIKeyboardKeyEscape;
    case 0xE00D:
      return @" ";
    case 0xE00E:
    case 0xE054:
      return XCUIKeyboardKeyPageUp;
    case 0xE00F:
    case 0xE055:
      return XCUIKeyboardKeyPageDown;
    case 0xE010:
    case 0xE056:
      return XCUIKeyboardKeyEnd;
    case 0xE011:
    case 0xE057:
      return XCUIKeyboardKeyHome;
    case 0xE012:
    case 0xE058:
      return XCUIKeyboardKeyLeftArrow;
    case 0xE013:
    case 0xE059:
      return XCUIKeyboardKeyUpArrow;
    case 0xE014:
    case 0xE05A:
      return XCUIKeyboardKeyRightArrow;
    case 0xE015:
    case 0xE05B:
      return XCUIKeyboardKeyDownArrow;
    case 0xE017:
    case 0xE05D:
      return XCUIKeyboardKeyForwardDelete;
    case 0xE018:
      return @";";
    case 0xE019:
      return @"=";
    case 0xE01A:
      return @"0";
    case 0xE01B:
      return @"1";
    case 0xE01C:
      return @"2";
    case 0xE01D:
      return @"3";
    case 0xE01E:
      return @"4";
    case 0xE01F:
      return @"5";
    case 0xE020:
      return @"6";
    case 0xE021:
      return @"7";
    case 0xE022:
      return @"8";
    case 0xE023:
      return @"9";
    case 0xE024:
      return @"*";
    case 0xE025:
      return @"+";
    case 0xE026:
      return @",";
    case 0xE027:
      return @"-";
    case 0xE028:
      return @".";
    case 0xE029:
      return @"/";
    case 0xE031:
      return XCUIKeyboardKeyF1;
    case 0xE032:
      return XCUIKeyboardKeyF2;
    case 0xE033:
      return XCUIKeyboardKeyF3;
    case 0xE034:
      return XCUIKeyboardKeyF4;
    case 0xE035:
      return XCUIKeyboardKeyF5;
    case 0xE036:
      return XCUIKeyboardKeyF6;
    case 0xE037:
      return XCUIKeyboardKeyF7;
    case 0xE038:
      return XCUIKeyboardKeyF8;
    case 0xE039:
      return XCUIKeyboardKeyF9;
    case 0xE03A:
      return XCUIKeyboardKeyF10;
    case 0xE03B:
      return XCUIKeyboardKeyF11;
    case 0xE03C:
      return XCUIKeyboardKeyF12;
    case 0xE050:
      return XCUIKeyboardKeyShift;
    case 0xE051:
      return XCUIKeyboardKeyControl;
    case 0xE052:
      return XCUIKeyboardKeyOption;
    case 0xE053:
      return XCUIKeyboardKeyCommand;
    default:
      return charCode >= 0xE000 && charCode <= 0xE05D ? @"" : nil;
  }
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
