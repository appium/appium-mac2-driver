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

#import "FBExceptions.h"
#import "XCUIElement+FBTyping.h"

@implementation XCUIElement (AMEditable)

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
  if (![self fb_typeText:textToType
                shouldClear:NO
                      error:&error]) {
    @throw [NSException exceptionWithName:FBInvalidElementStateException
                                   reason:error.description
                                 userInfo:@{}];
  }
}

@end
