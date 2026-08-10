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
#import "FBConfiguration.h"
#import "XCUIElement+AMAttributes.h"
#import "XCUIElement+FBFind.h"
#import "XCUIElement+FBClassChain.h"


static NSString *const AMWebContainerDomId = @"am-web-container";
static NSString *const AMWebButtonDomId = @"am-dom-button";
static NSTimeInterval const AMWebContentTimeout = 10.0;

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

- (void)tearDown
{
  // Other test classes assume the app is on the Buttons tab by default and do not
  // switch to it themselves - restore it so tests that dwell on the WebView tab here
  // do not leak that state into whichever test class happens to run next.
  [self switchToButtonsTab];
  [super tearDown];
}

/**
 WebKit builds a web view's accessibility subtree lazily, so the very first lookup
 after the page appears may need a retry before the web content shows up. Polls the
 given lookup until it finds something or the timeout elapses.
 */
- (NSArray<XCUIElement *> *)am_waitForWebContentUsingBlock:(NSArray<XCUIElement *> *(^)(void))block
{
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:AMWebContentTimeout];
  NSArray<XCUIElement *> *matches = @[];
  do {
    matches = block();
    if (matches.count > 0) {
      return matches;
    }
    [NSThread sleepForTimeInterval:0.5];
  } while ([deadline timeIntervalSinceNow] > 0);
  return matches;
}

- (void)testSingleDescendantWithIdentifier
{
  NSArray<XCUIElement *> *matches = [self.testedApplication fb_descendantsMatchingIdentifier:@"_XCUI:CloseWindow"
                                                                 shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matches.count, 1);
  XCTAssertEqualObjects(matches.firstObject.identifier, @"_XCUI:CloseWindow");
}

- (void)testSingleDescendantWithIdentifierWhileDomIdFallbackIsEnabled
{
  [self skipUnlessAccessibilityTrusted];
  [self switchToWebViewTab];
  FBConfiguration.sharedConfiguration.useDomIdAsAccessibilityId = YES;
  @try {
    // Native identifiers must keep resolving as usual
    NSArray<XCUIElement *> *matches = [self.testedApplication fb_descendantsMatchingIdentifier:@"_XCUI:CloseWindow"
                                                                   shouldReturnAfterFirstMatch:NO];
    XCTAssertEqual(matches.count, 1);
    XCTAssertEqualObjects(matches.firstObject.identifier, @"_XCUI:CloseWindow");

    NSArray<XCUIElement *> *noMatches = [self.testedApplication fb_descendantsMatchingIdentifier:@"there_is_no_such_dom_id"
                                                                     shouldReturnAfterFirstMatch:NO];
    XCTAssertEqual(noMatches.count, 0);

    // The web button has no native accessibility identifier, only a DOM id - the
    // fallback must resolve it
    NSArray<XCUIElement *> *webMatches = [self am_waitForWebContentUsingBlock:^NSArray<XCUIElement *> * {
      return [self.testedApplication fb_descendantsMatchingIdentifier:AMWebButtonDomId
                                            shouldReturnAfterFirstMatch:NO];
    }];
    XCTAssertEqual(webMatches.count, 1);
    XCTAssertEqual(webMatches.firstObject.elementType, XCUIElementTypeButton);
  } @finally {
    FBConfiguration.sharedConfiguration.useDomIdAsAccessibilityId = NO;
  }
}

- (void)testSingleDescendantWithIdentifierFindsNothingForDomIdWhenFallbackIsDisabled
{
  [self switchToWebViewTab];
  NSArray<XCUIElement *> *matches = [self.testedApplication fb_descendantsMatchingIdentifier:AMWebButtonDomId
                                                                 shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matches.count, 0);
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
  NSString *query = @"//XCUIElementTypeButton[starts-with(@identifier, \"_XCUI:\")]";
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

- (void)testMultipleDescendantsWithXPath2
{
  NSString *query = @"*//XCUIElementTypeButton[matches(@identifier, \"_xcui:\", \"i\")]";
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

- (void)testSingleDescendantWithPredicateMatchingAmIdentifierWhileDomIdFallbackIsEnabled
{
  [self skipUnlessAccessibilityTrusted];
  [self switchToWebViewTab];
  FBConfiguration.sharedConfiguration.useDomIdAsAccessibilityId = YES;
  @try {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"amIdentifier == %@ AND elementType == %lu",
                              AMWebButtonDomId, XCUIElementTypeButton];
    NSArray<XCUIElement *> *matches = [self am_waitForWebContentUsingBlock:^NSArray<XCUIElement *> * {
      return [self.testedApplication fb_descendantsMatchingPredicate:predicate
                                          shouldReturnAfterFirstMatch:NO];
    }];
    XCTAssertEqual(matches.count, 1);
    XCTAssertEqual(matches.firstObject.elementType, XCUIElementTypeButton);
  } @finally {
    FBConfiguration.sharedConfiguration.useDomIdAsAccessibilityId = NO;
  }
}

- (void)testSingleDescendantWithPredicateAmIdentifierAliasesNativeIdentifierWhenFallbackIsDisabled
{
  // amIdentifier mirrors am_identifier: with the setting off it is just the native
  // identifier, same as the standard identifier attribute
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"amIdentifier == %@", @"_XCUI:CloseWindow"];
  NSArray<XCUIElement *> *matches = [self.testedApplication fb_descendantsMatchingPredicate:predicate
                                                                shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matches.count, 1);
}

- (void)testSingleDescendantWithPredicateAmIdentifierFindsNothingForDomIdWhenFallbackIsDisabled
{
  [self switchToWebViewTab];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"amIdentifier == %@", AMWebButtonDomId];
  NSArray<XCUIElement *> *matches = [self.testedApplication fb_descendantsMatchingPredicate:predicate
                                                                shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matches.count, 0);
}

- (void)testSingleDescendantWithPredicateMatchingNestedAmRectKeyPath
{
  // A nested key path into an am_* attribute's resolved value (amRect is a
  // {x, y, width, height} dictionary) must resolve through the same block-predicate
  // rewrite as a bare am_* reference, not fall through to native key path resolution.
  NSArray<XCUIElement *> *matches = [self.testedApplication fb_descendantsMatchingIdentifier:@"_XCUI:CloseWindow"
                                                                 shouldReturnAfterFirstMatch:YES];
  XCTAssertEqual(matches.count, 1);
  NSNumber *x = matches.firstObject.am_rect[@"x"];
  XCTAssertNotNil(x);

  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@ AND amRect.x == %@",
                            @"_XCUI:CloseWindow", x];
  NSArray<XCUIElement *> *nestedMatches = [self.testedApplication fb_descendantsMatchingPredicate:predicate
                                                                        shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(nestedMatches.count, 1);
  XCTAssertEqualObjects(nestedMatches.firstObject.identifier, @"_XCUI:CloseWindow");

  NSPredicate *nonMatchingPredicate = [NSPredicate predicateWithFormat:@"identifier == %@ AND amRect.x == %@",
                                       @"_XCUI:CloseWindow", @(x.doubleValue + 1000)];
  NSArray<XCUIElement *> *noMatches = [self.testedApplication fb_descendantsMatchingPredicate:nonMatchingPredicate
                                                                    shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(noMatches.count, 0);
}

- (void)testSingleDescendantWithClassChainMatchingAmIdentifierOnLastSegmentWhileDomIdFallbackIsEnabled
{
  [self skipUnlessAccessibilityTrusted];
  [self switchToWebViewTab];
  FBConfiguration.sharedConfiguration.useDomIdAsAccessibilityId = YES;
  @try {
    NSString *query = [NSString stringWithFormat:@"**/XCUIElementTypeButton[`amIdentifier == '%@'`]", AMWebButtonDomId];
    NSArray<XCUIElement *> *matches = [self am_waitForWebContentUsingBlock:^NSArray<XCUIElement *> * {
      return [self.testedApplication fb_descendantsMatchingClassChain:query
                                            shouldReturnAfterFirstMatch:NO];
    }];
    XCTAssertEqual(matches.count, 1);
    XCTAssertEqual(matches.firstObject.elementType, XCUIElementTypeButton);
  } @finally {
    FBConfiguration.sharedConfiguration.useDomIdAsAccessibilityId = NO;
  }
}

- (void)testSingleDescendantWithClassChainMatchingAmIdentifierOnAncestorSegmentWhileDomIdFallbackIsEnabled
{
  [self skipUnlessAccessibilityTrusted];
  [self switchToWebViewTab];
  FBConfiguration.sharedConfiguration.useDomIdAsAccessibilityId = YES;
  @try {
    // The amIdentifier predicate sits on a non-terminal (ancestor) segment here, not
    // the last one - this works because every class chain segment's predicate is
    // formatted through the same NSPredicate+FBFormat rewrite, regardless of position
    NSString *query = [NSString stringWithFormat:@"**/XCUIElementTypeGroup[`amIdentifier == '%@'`]/XCUIElementTypeButton",
                       AMWebContainerDomId];
    NSArray<XCUIElement *> *matches = [self am_waitForWebContentUsingBlock:^NSArray<XCUIElement *> * {
      return [self.testedApplication fb_descendantsMatchingClassChain:query
                                            shouldReturnAfterFirstMatch:NO];
    }];
    XCTAssertEqual(matches.count, 1);
    XCTAssertEqual(matches.firstObject.elementType, XCUIElementTypeButton);
  } @finally {
    FBConfiguration.sharedConfiguration.useDomIdAsAccessibilityId = NO;
  }
}

- (void)testSingleDescendantWithClassChainAmIdentifierFindsNothingForDomIdWhenFallbackIsDisabled
{
  [self switchToWebViewTab];
  NSString *query = [NSString stringWithFormat:@"**/XCUIElementTypeButton[`amIdentifier == '%@'`]", AMWebButtonDomId];
  NSArray<XCUIElement *> *matches = [self.testedApplication fb_descendantsMatchingClassChain:query
                                                                 shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matches.count, 0);
}

@end
