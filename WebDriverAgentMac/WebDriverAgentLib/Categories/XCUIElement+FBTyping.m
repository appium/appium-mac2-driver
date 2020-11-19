/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBTyping.h"

#import "FBErrorBuilder.h"
#import "XCUIElement+AMAttributes.h"

#define MAX_CLEAR_RETRIES 2


@interface NSString (FBTyping)

- (NSString *)fb_repeatTimes:(NSUInteger)times;
- (NSUInteger)fb_visualLength;

@end

@implementation NSString (FBTyping)

- (NSString *)fb_repeatTimes:(NSUInteger)times {
  return [@"" stringByPaddingToLength:times * self.length
                           withString:self
                      startingAtIndex:0];
}

- (NSUInteger)fb_visualLength
{
  return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length;
}

@end


@implementation XCUIElement (FBTyping)

- (BOOL)fb_typeText:(NSString *)text
        shouldClear:(BOOL)shouldClear
              error:(NSError **)error
{
  if (shouldClear) {
    if (![self fb_clearTextWithError:error]) {
      return NO;
    }
  } else {
    if (!self.am_hasKeyboardInputFocus) {
      [self click];
    }
  }
  [self typeText:text];
  return YES;
}

- (BOOL)fb_clearTextWithError:(NSError **)error
{
  if (!self.am_hasKeyboardInputFocus) {
    [self click];
  }

  id currentValue = self.value;
  if (nil != currentValue && ![currentValue isKindOfClass:NSString.class]) {
    return [[[FBErrorBuilder builder]
             withDescriptionFormat:@"The value of '%@' is not a string and thus cannot be edited", self.description]
            buildError:error];
  }

  if (nil == currentValue || 0 == [currentValue fb_visualLength]) {
    // Short circuit if the content is not present
    return YES;
  }

  static NSString *backspaceDeleteSequence;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    backspaceDeleteSequence = [[NSString alloc] initWithData:(NSData *)[@"\\u0008\\u007F" dataUsingEncoding:NSASCIIStringEncoding]
                                                    encoding:NSNonLossyASCIIStringEncoding];
  });

  NSUInteger retry = 0;
  NSString *placeholderValue = self.placeholderValue;
  NSUInteger preClearTextLength = [currentValue fb_visualLength];
  do {
    if (retry >= MAX_CLEAR_RETRIES - 1) {
      // Last chance retry. Double-click the field to select its content
      [self doubleClick];
      [self typeText:backspaceDeleteSequence];
      return YES;
    }

    NSString *textToType = [backspaceDeleteSequence fb_repeatTimes:preClearTextLength];
    [self typeText:textToType];

    currentValue = self.value;
    if (nil != placeholderValue && [currentValue isEqualToString:placeholderValue]) {
      // Short circuit if only the placeholder value left
      return YES;
    }
    preClearTextLength = [currentValue fb_visualLength];

    retry++;
  } while (preClearTextLength > 0);
  return YES;
}

@end
