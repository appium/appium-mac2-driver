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
#import "XCUIApplication+AMSource.h"


@interface AMSourceTests : AMIntegrationTestCase
@end

@implementation AMSourceTests

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
  });
}

- (void)testDescriptionRepresentation
{
  NSString *description = self.testedApplication.am_descriptionRepresentation;
  XCTAssertTrue(description.length > 0);
}

- (void)testXmlRepresentation
{
  NSString *xml = self.testedApplication.am_xmlRepresentation;
  XCTAssertTrue(xml.length > 0);
}

@end
