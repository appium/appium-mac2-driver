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
#import "XCUIElement+AMSwipe.h"
#import "XCUICoordinate+AMSwipe.h"

@interface AMVariousElementTests : AMIntegrationTestCase
@end

@implementation AMVariousElementTests

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
  });
}

- (void)testSwipeElement
{
  XCUIElement *slider = self.testedApplication.sliders.firstMatch;
  NSError *error;
  XCTAssertTrue([slider am_swipeWithDirection:@"right" velocity:nil error:&error]);
  XCTAssertNil(error);
}

- (void)testSwipeCoordinates
{
  XCUIElement *slider = self.testedApplication.sliders.firstMatch;
  NSError *error;
  XCUICoordinate *destPoint = [slider coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)];
  XCTAssertTrue([destPoint am_swipeWithDirection:@"right"
                                        velocity:@(200)
                                           error:&error]);
  XCTAssertNil(error);
}

@end
