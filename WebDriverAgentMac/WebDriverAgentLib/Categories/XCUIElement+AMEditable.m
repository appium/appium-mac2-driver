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

#import "XCUIElement+AMEditable.h"

#import "FBErrorBuilder.h"
#import "FBExceptions.h"
#import "XCUIElement+AMAttributes.h"

#define MAX_CLEAR_RETRIES 2

@interface NSString (AMTyping)

- (NSString *)am_repeatTimes:(NSUInteger)times;
- (NSUInteger)am_visualLength;

@end

@implementation NSString (AMTyping)

- (NSString *)am_repeatTimes:(NSUInteger)times {
  return [@"" stringByPaddingToLength:times * self.length
                           withString:self
                      startingAtIndex:0];
}

- (NSUInteger)am_visualLength
{
  return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length;
}

@end


@implementation XCUIElement (AMEditable)

- (BOOL)am_typeText:(NSString *)text error:(NSError **)error
{
  if (![self am_clearTextWithError:error]) {
    return NO;
  }
  [self typeText:text];
  return YES;
}

- (BOOL)am_clearTextWithError:(NSError **)error
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

  if (nil == currentValue || 0 == [currentValue am_visualLength]) {
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
  NSUInteger preClearTextLength = [currentValue am_visualLength];
  do {
    if (retry >= MAX_CLEAR_RETRIES - 1) {
      // Last chance retry. Double-click the field to select its content
      [self doubleClick];
      [self typeText:backspaceDeleteSequence];
      return YES;
    }

    NSString *textToType = [backspaceDeleteSequence am_repeatTimes:preClearTextLength];
    [self typeText:textToType];

    currentValue = self.value;
    if (nil != placeholderValue && [currentValue isEqualToString:placeholderValue]) {
      // Short circuit if only the placeholder value left
      return YES;
    }
    preClearTextLength = [currentValue am_visualLength];

    retry++;
  } while (preClearTextLength > 0);
  return YES;
}

- (void)am_setValue:(id)value
{
  NSString *textToType = [value isKindOfClass:NSArray.class]
    ? [value componentsJoinedByString:@""]
    : value;
  XCUIElementType elementType = self.elementType;
  if (elementType == XCUIElementTypeSlider) {
    CGFloat sliderValue = textToType.floatValue;
    if (sliderValue < 0.0 || sliderValue > 1.0 ) {
      NSString *reason = [NSString stringWithFormat:@"Value of slider should be in 0..1 range. Got '%@' instead", value];
      @throw [NSException exceptionWithName:FBInvalidArgumentException
                                     reason:reason
                                   userInfo:@{}];
    }
    [self adjustToNormalizedSliderPosition:sliderValue];
    return;
  }
  NSError *error;
  if (![self am_typeText:textToType error:&error]) {
    @throw [NSException exceptionWithName:FBInvalidElementStateException
                                   reason:error.description
                                 userInfo:@{}];
  }
}

@end
