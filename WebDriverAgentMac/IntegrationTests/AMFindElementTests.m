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
#import "XCUIElement+FBFind.h"
#import "XCUIElement+FBClassChain.h"


@interface AMFindElementTests : AMIntegrationTestCase
@end

@implementation AMFindElementTests

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
  });
}

- (void)testSingleDescendantWithIdentifier
{
  NSArray<XCUIElement *> *matches = [self.testedApplication fb_descendantsMatchingIdentifier:@"_XCUI:CloseWindow"
                                                                 shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matches.count, 1);
  XCTAssertEqualObjects(matches.firstObject.identifier, @"_XCUI:CloseWindow");
}

- (void)testSingleDescendantWithClassName
{
  NSArray<XCUIElement *> *matches = [self.testedApplication fb_descendantsMatchingClassName:@"XCUIElementTypeButton"
                                                                shouldReturnAfterFirstMatch:YES];
  XCTAssertEqual(matches.count, 1);
}

- (void)testMultipleDescendantsWithClassName
{
  NSArray<XCUIElement *> *matches = [self.testedApplication fb_descendantsMatchingClassName:@"XCUIElementTypeButton"
                                                                shouldReturnAfterFirstMatch:NO];
  XCTAssertTrue(matches.count >= 3);
}

- (void)testSingleDescendantWithPredicate
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"elementType == %lu AND identifier BEGINSWITH %@", XCUIElementTypeButton, @"_XCUI:"];
  NSArray<XCUIElement *> *matches = [self.testedApplication fb_descendantsMatchingPredicate:predicate
                                                                shouldReturnAfterFirstMatch:YES];
  XCTAssertEqual(matches.count, 1);
  XCTAssertEqualObjects(matches.firstObject.identifier, @"_XCUI:CloseWindow");
}

- (void)testMultipleDescendantsWithPredicate
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"elementType == %lu AND identifier BEGINSWITH %@", XCUIElementTypeButton, @"_XCUI:"];
  NSArray<XCUIElement *> *matches = [self.testedApplication fb_descendantsMatchingPredicate:predicate
                                                                shouldReturnAfterFirstMatch:NO];
  XCTAssertTrue(matches.count >= 3);
  XCTAssertEqualObjects(matches.firstObject.identifier, @"_XCUI:CloseWindow");
  XCTAssertEqualObjects([matches objectAtIndex:2].identifier, @"_XCUI:MinimizeWindow");
}

- (void)testSingleDescendantWithXPath
{
  NSString *query = @"*//XCUIElementTypeButton[starts-with(@identifier, \"_XCUI:\")]";
  NSArray<XCUIElement *> *matches = [self.testedApplication fb_descendantsMatchingXPathQuery:query
                                                                 shouldReturnAfterFirstMatch:YES];
  XCTAssertEqual(matches.count, 1);
  XCTAssertEqualObjects(matches.firstObject.identifier, @"_XCUI:CloseWindow");
}

- (void)testMultipleDescendantsWithXPath
{
  NSString *query = @"*//XCUIElementTypeButton[starts-with(@identifier, \"_XCUI:\")]";
  NSArray<XCUIElement *> *matches = [self.testedApplication fb_descendantsMatchingXPathQuery:query
                                                                 shouldReturnAfterFirstMatch:NO];
  XCTAssertTrue(matches.count >= 3);
  XCTAssertEqualObjects(matches.firstObject.identifier, @"_XCUI:CloseWindow");
  XCTAssertEqualObjects([matches objectAtIndex:2].identifier, @"_XCUI:MinimizeWindow");
}

- (void)testSingleDescendantWithClassChain
{
  NSString *query = @"**/XCUIElementTypeButton[`identifier == '_XCUI:CloseWindow'`]";
  NSArray<XCUIElement *> *matches = [self.testedApplication fb_descendantsMatchingClassChain:query
                                                                 shouldReturnAfterFirstMatch:YES];
  XCTAssertEqual(matches.count, 1);
  XCTAssertEqualObjects(matches.firstObject.identifier, @"_XCUI:CloseWindow");
}

- (void)testMultipleDescendantsWithClassChain
{
  NSString *query = @"**/XCUIElementTypeButton[`identifier BEGINSWITH '_XCUI:'`]";
  NSArray<XCUIElement *> *matches = [self.testedApplication fb_descendantsMatchingClassChain:query
                                                                 shouldReturnAfterFirstMatch:NO];
  XCTAssertTrue(matches.count >= 3);
  XCTAssertEqualObjects(matches.firstObject.identifier, @"_XCUI:CloseWindow");
  XCTAssertEqualObjects([matches objectAtIndex:2].identifier, @"_XCUI:MinimizeWindow");
}

@end
