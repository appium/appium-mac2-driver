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

#import <XCTest/XCTest.h>

#import "AMIntegrationTestCase.h"
#import "XCUIElement+AMAttributes.h"
#import "XCUIElement+AMEditable.h"


@interface AMEditElementTests : AMIntegrationTestCase
@end

@implementation AMEditElementTests

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
    [self switchToEditsTab];
  });
}

- (void)testSendingTextIntoNonFocusedEdit
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"placeholderValue.length == 0"];
  XCUIElement *edit = [self.testedApplication.textFields matchingPredicate:predicate].firstMatch;
  NSString *text = @"yolo😎";
  [edit am_setValue:text];
  XCTAssertTrue(edit.am_hasKeyboardInputFocus);
  NSString *value = [edit am_wdAttributeValueWithName:@"value"];
  XCTAssertEqualObjects(value, text);
  XCTAssertEqualObjects(value, edit.am_text);
}

- (void)testSendingTextIntoNonFocusedEditWithPlaceholderText
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"placeholderValue.length > 0"];
  XCUIElement *edit = [self.testedApplication.textFields matchingPredicate:predicate].firstMatch;
  NSString *text = @"yolo😎";
  [edit am_setValue:text];
  XCTAssertTrue(edit.am_hasKeyboardInputFocus);
  NSString *value = [edit am_wdAttributeValueWithName:@"value"];
  XCTAssertEqualObjects(value, text);
  XCTAssertEqualObjects(value, edit.am_text);
}

- (void)testClearingTextField
{
  XCUIElement *edit = self.testedApplication.textFields.firstMatch;
  NSString *text = @"yolo😎";
  [edit am_setValue:text];
  XCTAssertEqualObjects([edit am_wdAttributeValueWithName:@"value"], text);
  NSError *error = nil;
  XCTAssertTrue([edit am_clearTextWithError:&error]);
  XCTAssertNil(error);
  XCTAssertEqualObjects([edit am_wdAttributeValueWithName:@"value"], @"");
}

@end
