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

#import "AMKeyboardUtils.h"

NSString *AMKeyValueForName(NSString *name)
{
  static dispatch_once_t onceKeys;
  static NSDictionary<NSString *, NSString *> *keysMapping;
  dispatch_once(&onceKeys, ^{
    keysMapping = @{
      @"XCUIKeyboardKeyDelete": XCUIKeyboardKeyDelete,
      @"XCUIKeyboardKeyReturn": XCUIKeyboardKeyReturn,
      @"XCUIKeyboardKeyEnter": XCUIKeyboardKeyEnter,
      @"XCUIKeyboardKeyTab": XCUIKeyboardKeyTab,
      @"XCUIKeyboardKeySpace": XCUIKeyboardKeySpace,
      @"XCUIKeyboardKeyEscape": XCUIKeyboardKeyEscape,

      @"XCUIKeyboardKeyUpArrow": XCUIKeyboardKeyUpArrow,
      @"XCUIKeyboardKeyDownArrow": XCUIKeyboardKeyDownArrow,
      @"XCUIKeyboardKeyLeftArrow": XCUIKeyboardKeyLeftArrow,
      @"XCUIKeyboardKeyRightArrow": XCUIKeyboardKeyRightArrow,

      @"XCUIKeyboardKeyF1": XCUIKeyboardKeyF1,
      @"XCUIKeyboardKeyF2": XCUIKeyboardKeyF2,
      @"XCUIKeyboardKeyF3": XCUIKeyboardKeyF3,
      @"XCUIKeyboardKeyF4": XCUIKeyboardKeyF4,
      @"XCUIKeyboardKeyF5": XCUIKeyboardKeyF5,
      @"XCUIKeyboardKeyF6": XCUIKeyboardKeyF6,
      @"XCUIKeyboardKeyF7": XCUIKeyboardKeyF7,
      @"XCUIKeyboardKeyF8": XCUIKeyboardKeyF8,
      @"XCUIKeyboardKeyF9": XCUIKeyboardKeyF9,
      @"XCUIKeyboardKeyF10": XCUIKeyboardKeyF10,
      @"XCUIKeyboardKeyF11": XCUIKeyboardKeyF11,
      @"XCUIKeyboardKeyF12": XCUIKeyboardKeyF12,
      @"XCUIKeyboardKeyF13": XCUIKeyboardKeyF13,
      @"XCUIKeyboardKeyF14": XCUIKeyboardKeyF14,
      @"XCUIKeyboardKeyF15": XCUIKeyboardKeyF15,
      @"XCUIKeyboardKeyF16": XCUIKeyboardKeyF16,
      @"XCUIKeyboardKeyF17": XCUIKeyboardKeyF17,
      @"XCUIKeyboardKeyF18": XCUIKeyboardKeyF18,
      @"XCUIKeyboardKeyF19": XCUIKeyboardKeyF19,

      @"XCUIKeyboardKeyForwardDelete": XCUIKeyboardKeyForwardDelete,
      @"XCUIKeyboardKeyHome": XCUIKeyboardKeyHome,
      @"XCUIKeyboardKeyEnd": XCUIKeyboardKeyEnd,
      @"XCUIKeyboardKeyPageUp": XCUIKeyboardKeyPageUp,
      @"XCUIKeyboardKeyPageDown": XCUIKeyboardKeyPageDown,
      @"XCUIKeyboardKeyClear": XCUIKeyboardKeyClear,
      @"XCUIKeyboardKeyHelp": XCUIKeyboardKeyHelp,

      @"XCUIKeyboardKeyCapsLock": XCUIKeyboardKeyCapsLock,
      @"XCUIKeyboardKeyShift": XCUIKeyboardKeyShift,
      @"XCUIKeyboardKeyControl": XCUIKeyboardKeyControl,
      @"XCUIKeyboardKeyOption": XCUIKeyboardKeyOption,
      @"XCUIKeyboardKeyCommand": XCUIKeyboardKeyCommand,
      @"XCUIKeyboardKeyRightShift": XCUIKeyboardKeyRightShift,
      @"XCUIKeyboardKeyRightControl": XCUIKeyboardKeyRightControl,
      @"XCUIKeyboardKeyRightOption": XCUIKeyboardKeyRightOption,
      @"XCUIKeyboardKeyRightCommand": XCUIKeyboardKeyRightCommand,
      @"XCUIKeyboardKeySecondaryFn": XCUIKeyboardKeySecondaryFn
    };
  });
  return keysMapping[name];
}
