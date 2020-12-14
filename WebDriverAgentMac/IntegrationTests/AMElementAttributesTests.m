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
#import "FBTestMacros.h"
#import "XCUIElement+AMAttributes.h"
#import "XCUIElement+AMEditable.h"
#import "XCUIElement+AMHitPoint.h"
#import "XCUIElement+AMCoordinates.h"


@interface AMElementAttributesTests : AMIntegrationTestCase
@end

@implementation AMElementAttributesTests

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
  });
}

- (void)testChangingCheckboxState
{
  XCUIElement *checkbox = self.testedApplication.checkBoxes.firstMatch;
  NSString *state = [checkbox am_wdAttributeValueWithName:@"value"];
  [checkbox click];
  XCTAssertNotEqualObjects(state, [checkbox am_wdAttributeValueWithName:@"value"]);
}

- (void)testGettingAttributes
{
  NSString *buttonTitle = @"Click Me";
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title == %@", buttonTitle];
  XCUIElement *button = [self.testedApplication.buttons matchingPredicate:predicate].firstMatch;
  NSString *enabled = [button am_wdAttributeValueWithName:@"enabled"];
  XCTAssertEqualObjects(enabled, @"true");
  NSString *selected = [button am_wdAttributeValueWithName:@"selected"];
  XCTAssertEqualObjects(selected, @"false");
  NSString *title = [button am_wdAttributeValueWithName:@"title"];
  XCTAssertEqualObjects(title, buttonTitle);
  NSString *value = [button am_wdAttributeValueWithName:@"value"];
  XCTAssertEqualObjects(value, @"");
  NSString *placeholderValue = [button am_wdAttributeValueWithName:@"placeholderValue"];
  XCTAssertEqualObjects(placeholderValue, @"");
  NSString *identifier = [button am_wdAttributeValueWithName:@"identifier"];
  XCTAssertNotNil(identifier);
  NSString *text = button.am_text;
  XCTAssertEqualObjects(text, buttonTitle);
  NSDictionary *rect = button.am_rect;
  XCTAssertNotNil(rect[@"x"]);
  XCTAssertNotNil(rect[@"y"]);
  XCTAssertNotNil(rect[@"width"]);
  XCTAssertNotNil(rect[@"height"]);
  BOOL hasFocus = button.am_hasKeyboardInputFocus;
  XCTAssertFalse(hasFocus);
  NSInteger type = [[button am_wdAttributeValueWithName:@"elementType"] integerValue];
  XCTAssertEqual(type, XCUIElementTypeButton);
}

- (void)testDisabledAttribute
{
  NSString *buttonTitle = @"I Am Disabled";
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title == %@", buttonTitle];
  XCUIElement *button = [self.testedApplication.buttons matchingPredicate:predicate].firstMatch;
  NSString *enabled = [button am_wdAttributeValueWithName:@"enabled"];
  XCTAssertEqualObjects(enabled, @"false");
}

- (void)testAppCoordinates
{
  CGPoint buttonCoords = CGPointMake(20, 30);
  XCUICoordinate *abosuluteCoordinate = [self.testedApplication am_coordinateWithPoint:buttonCoords];
  XCTAssertEqualWithAccuracy(abosuluteCoordinate.screenPoint.x, buttonCoords.x, 0.1);
  XCTAssertEqualWithAccuracy(abosuluteCoordinate.screenPoint.y, buttonCoords.y, 0.1);
}

- (void)testSliderValueAttribute
{
  XCUIElement *slider = self.testedApplication.sliders.firstMatch;
  NSString *value = [slider am_wdAttributeValueWithName:@"value"];
  XCTAssertTrue([value doubleValue] > 0);
  [slider am_setValue:@([value doubleValue] / 100.0 + 0.1)];
  XCTAssertNotEqualObjects(value, [slider am_wdAttributeValueWithName:@"value"]);
}

- (void)testAccessingInvalidAttribute
{
  XCTAssertThrows([self.testedApplication am_wdAttributeValueWithName:@"foo"]);
}

- (void)testHitPointRetrieval
{
  XCTAssertNotNil(self.testedApplication.sliders.firstMatch.am_hitPointCoordinate);
}

@end
