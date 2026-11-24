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

#import "FBClassChainQueryParser.h"
#import "FBElementTypeTransformer.h"
#import "XCUIElement+FBClassChain.h"

@interface FBClassChainTests : XCTestCase
@end

@implementation FBClassChainTests

- (void)testValidChain
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow/XCUIElementTypeButton" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 2);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeWindow);
  XCTAssertNil(firstElement.position);
  XCTAssertFalse(firstElement.isDescendant);

  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertNil(secondElement.position);
  XCTAssertFalse(secondElement.isDescendant);
}

- (void)testValidChainWithStar
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow/XCUIElementTypeButton[3]/*[4]/*[5]/XCUIElementTypeAlert" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 5);
  
    FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeWindow);
  XCTAssertNil(firstElement.position);
  XCTAssertFalse(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertEqual(secondElement.position.integerValue, 3);
  XCTAssertFalse(secondElement.isDescendant);
  
  FBClassChainItem *thirdElement = [result.elements objectAtIndex:2];
  XCTAssertEqual(thirdElement.type, XCUIElementTypeAny);
  XCTAssertEqual(thirdElement.position.integerValue, 4);
  XCTAssertFalse(thirdElement.isDescendant);
  
  FBClassChainItem *fourthElement = [result.elements objectAtIndex:3];
  XCTAssertEqual(fourthElement.type, XCUIElementTypeAny);
  XCTAssertEqual(fourthElement.position.integerValue, 5);
  XCTAssertFalse(fourthElement.isDescendant);
  
  FBClassChainItem *fifthsElement = [result.elements objectAtIndex:4];
  XCTAssertEqual(fifthsElement.type, XCUIElementTypeAlert);
  XCTAssertNil(fifthsElement.position);
  XCTAssertFalse(fifthsElement.isDescendant);
}

- (void)testValidSingleStarChain
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"*" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 1);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeAny);
  XCTAssertNil(firstElement.position);
  XCTAssertFalse(firstElement.isDescendant);
}

- (void)testValidSingleStarIndirectChain
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"**/*/*/XCUIElementTypeButton" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 3);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeAny);
  XCTAssertNil(firstElement.position);
  XCTAssertTrue(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeAny);
  XCTAssertNil(secondElement.position);
  XCTAssertFalse(secondElement.isDescendant);
  
  FBClassChainItem *thirdElement = [result.elements objectAtIndex:2];
  XCTAssertEqual(thirdElement.type, XCUIElementTypeButton);
  XCTAssertNil(thirdElement.position);
  XCTAssertFalse(thirdElement.isDescendant);
}

- (void)testValidDoubleIndirectChainAndStar
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"**/XCUIElementTypeButton/**/*" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 2);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeButton);
  XCTAssertNil(firstElement.position);
  XCTAssertTrue(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeAny);
  XCTAssertNil(secondElement.position);
  XCTAssertTrue(secondElement.isDescendant);
}

- (void)testValidDoubleIndirectChainAndClassName
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"**/XCUIElementTypeButton/**/XCUIElementTypeImage" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 2);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeButton);
  XCTAssertNil(firstElement.position);
  XCTAssertTrue(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeImage);
  XCTAssertNil(secondElement.position);
  XCTAssertTrue(secondElement.isDescendant);
}

- (void)testValidChainWithNegativeIndex
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow/XCUIElementTypeButton[-1]" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 2);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeWindow);
  XCTAssertNil(firstElement.position);
  XCTAssertEqual(firstElement.predicates.count, 0);
  XCTAssertFalse(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertEqual(secondElement.position.integerValue, -1);
  XCTAssertEqual(secondElement.predicates.count, 0);
  XCTAssertFalse(secondElement.isDescendant);
}

- (void)testValidChainWithSinglePredicate
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow[`identifier == 'blabla'`]/XCUIElementTypeButton" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 2);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeWindow);
  XCTAssertNil(firstElement.position);
  XCTAssertEqual(firstElement.predicates.count, 1);
  XCTAssertFalse(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertNil(secondElement.position);
  XCTAssertEqual(secondElement.predicates.count, 0);
  XCTAssertFalse(secondElement.isDescendant);
}

- (void)testValidChainWithMultiplePredicates
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow[`identifier == 'blabla'`]/XCUIElementTypeButton[`value == 'blabla'`]" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 2);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeWindow);
  XCTAssertNil(firstElement.position);
  XCTAssertEqual(firstElement.predicates.count, 1);
  XCTAssertFalse(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertNil(secondElement.position);
  XCTAssertEqual(secondElement.predicates.count, 1);
  XCTAssertFalse(secondElement.isDescendant);
}

- (void)testValidChainWithIndirectSearchAndPredicates
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"**/XCUIElementTypeTable[`identifier == 'blabla'`][10]/**/XCUIElementTypeButton[`value == 'blabla'`]" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 2);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeTable);
  XCTAssertEqual(firstElement.position.integerValue, 10);
  XCTAssertEqual(firstElement.predicates.count, 1);
  XCTAssertTrue(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertNil(secondElement.position);
  XCTAssertEqual(secondElement.predicates.count, 1);
  XCTAssertTrue(secondElement.isDescendant);
}

- (void)testValidChainWithMultiplePredicatesAndPositions
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"*[`identifier == \"к``ири````'лиця\"`][3]/XCUIElementTypeButton[`value == \"blabla\"`][-1]" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 2);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeAny);
  XCTAssertEqual(firstElement.position.integerValue, 3);
  XCTAssertEqual(firstElement.predicates.count, 1);
  XCTAssertFalse(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertEqual(secondElement.position.integerValue, -1);
  XCTAssertEqual(secondElement.predicates.count, 1);
  XCTAssertFalse(secondElement.isDescendant);
}

- (void)testValidChainWithDescendantPredicate
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"**/XCUIElementTypeTable[$title == 'XCUIElementTypeImage' AND identifier == 'olala'$][`identifier == 'blabla'`][10]" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 1);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeTable);
  XCTAssertEqual(firstElement.position.integerValue, 10);
  XCTAssertEqual(firstElement.predicates.count, 2);
  XCTAssertTrue(firstElement.isDescendant);
}

- (void)testValidChainWithMultipleDescendantPredicates
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"**/XCUIElementTypeTable[$title == 'XCUIElementTypeImage' AND identifier == 'olala'$][`value == 'peace'`][$value == 'yolo'$][`identifier == 'blabla'`][10]" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 1);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeTable);
  XCTAssertEqual(firstElement.position.integerValue, 10);
  XCTAssertEqual(firstElement.predicates.count, 4);
  XCTAssertTrue(firstElement.isDescendant);
}

- (void)testInvalidChains
{
  NSArray *invalidQueries = @[
    @"/XCUIElementTypeWindow"
    ,@"XCUIElementTypeWindow/"
    ,@"XCUIElementTypeWindow//*"
    ,@"XCUIElementTypeWindow*/*"
    ,@"**"
    ,@"***"
    ,@"**/*/**"
    ,@"/**"
    ,@"XCUIElementTypeWindow/**"
    ,@"**[1]/XCUIElementTypeWindow"
    ,@"**[`identifier == '1'`]/XCUIElementTypeWindow"
    ,@"XCUIElementTypeWindow[0]"
    ,@"XCUIElementTypeWindow[1][1]"
    ,@"blabla"
    ,@"XCUIElementTypeWindow/blabla"
    ,@" XCUIElementTypeWindow"
    ,@"XCUIElementTypeWindow[ 2 ]"
    ,@"XCUIElementTypeWindow[[2]"
    ,@"XCUIElementTypeWindow[2]]"
    ,@"XCUIElementType[Window[2]]"
    ,@"XCUIElementTypeWindow[enabled = 1]"
    ,@"XCUIElementTypeWindow[1][`enabled = 1`]"
    ,@"XCUIElementTypeWindow[1] [`enabled = 1`]"
    ,@"XCUIElementTypeWindow[ `enabled = 1`]"
    ,@"XCUIElementTypeWindow[`enabled = 1][`identifier = \"bla\"`]"
    ,@"XCUIElementTypeWindow[`enabled = 1]"
    ,@"XCUIElementTypeWindow[$enabled = 1]"
    ,@"XCUIElementTypeWindow[``]"
    ,@"XCUIElementTypeWindow[$$]"
    ,@"XCUIElementTypeWindow[`identifier = \"bla```bla\"`]"
    ,@"XCUIElementTypeWindow[$identifier = \"bla$$$bla\"$]"
  ];
  for (NSString *invalidQuery in invalidQueries) {
    NSError *error;
    FBClassChain *result = [FBClassChainQueryParser parseQuery:invalidQuery error:&error];
    XCTAssertNil(result);
    XCTAssertNotNil(error);
  }
}

// Type, optional position and the number of self/descendant predicates of every item, e.g. "**/Window[2]{1,0}"
static NSString *FBDescribeChain(FBClassChain *chain)
{
  NSMutableArray<NSString *> *items = [NSMutableArray array];
  for (FBClassChainItem *item in chain.elements) {
    NSUInteger selfPredicates = 0;
    NSUInteger descendantPredicates = 0;
    for (FBAbstractPredicateItem *predicate in item.predicates) {
      if ([predicate isKindOfClass:FBSelfPredicateItem.class]) {
        ++selfPredicates;
      } else {
        ++descendantPredicates;
      }
    }
    NSString *type = [[FBElementTypeTransformer stringWithElementType:item.type] stringByReplacingOccurrencesOfString:@"XCUIElementType" withString:@""];
    NSDictionary<NSNumber *, NSString *> *prefixes = @{
      @(FBClassChainAxisDescendant): @"**/",
      @(FBClassChainAxisAncestor): @"^",
      @(FBClassChainAxisFollowingSibling): @">",
      @(FBClassChainAxisPrecedingSibling): @"<",
      @(FBClassChainAxisSibling): @"~",
    };
    if (FBClassChainAxisParent == item.axis) {
      type = @"..";
    }
    [items addObject:[NSString stringWithFormat:@"%@%@%@{%lu,%lu}", prefixes[@(item.axis)] ?: @"", type,
                      nil == item.position ? @"" : [NSString stringWithFormat:@"[%@]", item.position],
                      (unsigned long)selfPredicates, (unsigned long)descendantPredicates]];
  }
  return [items componentsJoinedByString:@" "];
}

- (void)testParsedItems
{
  NSDictionary<NSString *, NSString *> *expectations = @{
    @"XCUIElementTypeWindow[12]/XCUIElementTypeAny[-1]": @"Window[12]{0,0} Any[-1]{0,0}",
    @"*/*/*[2]/*/XCUIElementTypeButton": @"Any{0,0} Any{0,0} Any[2]{0,0} Any{0,0} Button{0,0}",
    @"**/*/*/XCUIElementTypeButton[1]": @"**/Any{0,0} Any{0,0} Button[1]{0,0}",
    @"XCUIElementTypeWindow/**/*": @"Window{0,0} **/Any{0,0}",
    @"**/XCUIElementTypeCell[1]/**/XCUIElementTypeButton": @"**/Cell[1]{0,0} **/Button{0,0}",
    @"XCUIElementTypeWindow[`identifier == \"a\"`][`label == \"1\"`][2]": @"Window[2]{2,0}",
    @"XCUIElementTypeWindow[$identifier == 'a'$][$label == 'b'$]": @"Window{0,2}",
    @"XCUIElementTypeWindow[`identifier == 'a'`][$label == 'b'$][`value == 'c'`]": @"Window{2,1}",
    @"XCUIElementTypeWindow[`identifier == \"a``b\"`]": @"Window{1,0}",
    @"XCUIElementTypeWindow[$identifier == \"a$$b\"$]": @"Window{0,1}",
    @"XCUIElementTypeWindow[`value == \"[1]/**/\"`]": @"Window{1,0}",
    @"XCUIElementTypeWindow[`value == \"a\"\n`]": @"Window{1,0}",
    @"**/XCUIElementTypeWindow[`identifier == \"a\"`]/**/XCUIElementTypeButton[`identifier == \"b\"`][2]": @"**/Window{1,0} **/Button[2]{1,0}",
    @"XCUIElementTypeWindow[2147483647]/XCUIElementTypeButton[-2147483647]": @"Window[2147483647]{0,0} Button[-2147483647]{0,0}",
  };
  for (NSString *query in expectations) {
    NSError *error = nil;
    FBClassChain *chain = [FBClassChainQueryParser parseQuery:query error:&error];
    XCTAssertNotNil(chain, @"%@", query);
    XCTAssertEqualObjects(FBDescribeChain(chain), expectations[query], @"%@", query);
  }
}

- (void)testMoreInvalidChains
{
  NSArray<NSString *> *invalidQueries = @[
    @"", @"**/", @"**//*", @"****/*", @"/**/*", @"XCUIElementTypeWindow/**/",
    @"XCUIElementTypeWindow/***/*", @"**/[1]", @"**/[`identifier == '1'`]",
    @"XCUIElementTypeWindow[1][2]", @"XCUIElementTypeWindow[-0]", @"XCUIElementTypeWindow[-]",
    @"XCUIElementTypeWindow[--1]", @"XCUIElementTypeWindow[1-]", @"XCUIElementTypeWindow[1-1]",
    @"XCUIElementTypeWindow1", @"XCUIElementType_Window", @"XCUIElementTypeWindow ",
    @"XCUIElementTypeWindow/ XCUIElementTypeButton", @"XCUIElementTypeWindow[]", @"XCUIElementTypeWindow[",
    @"XCUIElementTypeWindow[1", @"XCUIElementTypeWindow[`enabled = 1`] [1]", @"XCUIElementTypeWindow[`enabled = 1",
    @"XCUIElementTypeWindow[`enabled = 1`", @"XCUIElementTypeWindow[```]", @"XCUIElementTypeWindow[``]x`]",
    @"XCUIElementTypeWindow[`identifier = \"bla\"`]x", @"XCUIElementTypeWindow[`identifier = \"bla\"`]*",
    @"XCUIElementTypeWindow[1]*", @"XCUIElementTypeWindow[1]x", @"*[1]*", @"*x",
    @"**/**/XCUIElementTypeWindow", @"XCUIElementTypeWindow/**/**/XCUIElementTypeButton",
    @"XCUIElementTypeWindow/**/**/**/XCUIElementTypeButton", @"**/**/**/*",
  ];
  for (NSString *query in invalidQueries) {
    NSError *error = nil;
    XCTAssertNil([FBClassChainQueryParser parseQuery:query error:&error], @"%@", query);
    XCTAssertNotNil(error, @"%@", query);
  }
}

// An invalid predicate raises, but only if nothing before it in the query is an error
- (void)testFirstProblemWins
{
  NSArray<NSString *> *errors = @[
    @"XCUIElementTypeWindow[`identifier == \"a\"`]/blabla",
    @"blabla/XCUIElementTypeWindow[`identifier ==`]",
    @"XCUIElementTypeWindow[`identifier == \"a\"`]/**/**/XCUIElementTypeButton[`identifier ==`]",
    @"XCUIElementTypeWindow[`identifier == \"a\"`][1][`identifier ==`]",
    @"XCUIElementTypeWindow[1][`identifier ==`]/XCUIElementTypeButton[`identifier ==`]",
    // syntax is checked before any predicate is compiled
    @"XCUIElementTypeWindow[`identifier ==`]/XCUIElementTypeButton[`identifier == \"a\"`]x",
  ];
  for (NSString *query in errors) {
    NSError *error = nil;
    XCTAssertNil([FBClassChainQueryParser parseQuery:query error:&error], @"%@", query);
    XCTAssertNotNil(error, @"%@", query);
  }
  NSArray<NSString *> *invalidPredicates = @[
    @"XCUIElementTypeWindow[`identifier ==`]/blabla",
    @"XCUIElementTypeWindow[`identifier ==`]/XCUIElementTypeButton[0]",
    @"XCUIElementTypeWindow[`identifier ==`]/**/**/XCUIElementTypeButton",
    @"XCUIElementTypeWindow[`identifier ==`][1][`identifier ==`]",
    @"XCUIElementTypeWindow[`identifier == `]",
  ];
  for (NSString *query in invalidPredicates) {
    NSError *error = nil;
    XCTAssertThrowsSpecificNamed([FBClassChainQueryParser parseQuery:query error:&error], NSException, NSInvalidArgumentException, @"%@", query);
  }
  NSArray<NSString *> *unknownAttributes = @[
    @"XCUIElementTypeWindow[`nosuchattribute == 1`]",
    @"XCUIElementTypeWindow[$nosuchattribute == 1$]",
    @"XCUIElementTypeWindow[`nosuchattribute == 1`]/blabla",
  ];
  for (NSString *query in unknownAttributes) {
    NSError *error = nil;
    XCTAssertThrowsSpecificNamed([FBClassChainQueryParser parseQuery:query error:&error], NSException, @"FBElementAttributeUnknownException", @"%@", query);
  }
}

- (void)testStarsDirectlyBeforeClassNameAreRejected
{
  for (NSString *query in @[@"**XCUIElementTypeButton", @"***XCUIElementTypeButton", @"XCUIElementTypeWindow/**XCUIElementTypeButton", @"**/**XCUIElementTypeButton"]) {
    NSError *error = nil;
    XCTAssertNil([FBClassChainQueryParser parseQuery:query error:&error], @"%@", query);
    XCTAssertNotNil(error, @"%@", query);
  }
}

- (void)testEmptyPredicateIsRejected
{
  for (NSString *query in @[@"XCUIElementTypeWindow[``]", @"XCUIElementTypeWindow[$$]"]) {
    NSError *error = nil;
    XCTAssertNil([FBClassChainQueryParser parseQuery:query error:&error], @"%@", query);
    XCTAssertNotNil(error, @"%@", query);
  }
}

- (void)testLeadingPredicateMarkersAreNotSwallowed
{
  NSError *error = nil;
  // The first marker opens the predicate and the second one closes it, so nothing valid follows
  XCTAssertNil([FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow[``identifier == 'a'`]" error:&error]);
  XCTAssertNotNil(error);
  // The predicate text is "`identifier == 'a'", where the doubled marker is an escaped one
  XCTAssertThrowsSpecificNamed([FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow[```identifier == 'a'`]" error:&error], NSException, NSInvalidArgumentException);
}

- (void)testPositionIsAnAsciiInt
{
  NSArray<NSString *> *invalid = @[@"[٣]", @"[0]", @"[4294967296]", @"[99999999999999999999]", @"[-99999999999999999999]", @"[2147483648]", @"[-2147483648]", @"[-9223372036854775808]"];
  for (NSString *position in invalid) {
    NSString *query = [@"XCUIElementTypeWindow" stringByAppendingString:position];
    NSError *error = nil;
    XCTAssertNil([FBClassChainQueryParser parseQuery:query error:&error], @"%@", query);
    XCTAssertNotNil(error, @"%@", query);
  }
}

- (void)testPredicateTextIsNotAFormatString
{
  NSError *error = nil;
  FBClassChain *chain = [FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow[`identifier LIKE '50%'`]" error:&error];
  XCTAssertNotNil(chain);
  XCTAssertEqual(chain.elements.firstObject.predicates.count, 1);
  XCTAssertThrowsSpecificNamed([FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow[`identifier == %@`]" error:&error], NSException, NSInvalidArgumentException);
  XCTAssertThrowsSpecificNamed([FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow[`identifier == %d AND label == %@`]" error:&error], NSException, NSInvalidArgumentException);
}

- (void)testAxisItems
{
  NSDictionary<NSString *, NSString *> *expectations = @{
    @"..": @"..{0,0}",
    @"../..": @"..{0,0} ..{0,0}",
    @"..[`identifier == 'a'`][$enabled == 1$]": @"..{1,1}",
    @"^XCUIElementTypeCell": @"^Cell{0,0}",
    @"^XCUIElementTypeCell[1]": @"^Cell[1]{0,0}",
    @"^*[-1]": @"^Any[-1]{0,0}",
    @">XCUIElementTypeButton[`enabled == 1`][2]": @">Button[2]{1,0}",
    @"<XCUIElementTypeButton": @"<Button{0,0}",
    @"~*": @"~Any{0,0}",
    @"XCUIElementTypeButton/..": @"Button{0,0} ..{0,0}",
    @"XCUIElementTypeButton/../XCUIElementTypeTextField[2]": @"Button{0,0} ..{0,0} TextField[2]{0,0}",
    @"**/XCUIElementTypeButton/..": @"**/Button{0,0} ..{0,0}",
    @"**/XCUIElementTypeButton/>*[1]/**/XCUIElementTypeImage": @"**/Button{0,0} >Any[1]{0,0} **/Image{0,0}",
    @"XCUIElementTypeButton/../**/XCUIElementTypeImage": @"Button{0,0} ..{0,0} **/Image{0,0}",
    @"XCUIElementTypeButton/^XCUIElementTypeCell/<XCUIElementTypeCell[-1]/~*": @"Button{0,0} ^Cell{0,0} <Cell[-1]{0,0} ~Any{0,0}",
    @"../XCUIElementTypeButton": @"..{0,0} Button{0,0}",
  };
  for (NSString *query in expectations) {
    NSError *error = nil;
    FBClassChain *chain = [FBClassChainQueryParser parseQuery:query error:&error];
    XCTAssertNotNil(chain, @"%@ %@", query, error);
    XCTAssertEqualObjects(FBDescribeChain(chain), expectations[query], @"%@", query);
  }
}

- (void)testInvalidAxes
{
  NSArray<NSString *> *invalidQueries = @[
    @".", @"...", @"....", @"..XCUIElementTypeButton", @"..*", @"..[1]", @"..[`identifier == 'a'`][1]", @"..[1][`identifier == 'a'`]",
    @"**/..", @"XCUIElementTypeWindow/**/..", @"**/^XCUIElementTypeCell", @"XCUIElementTypeWindow/**/>*",
    @"XCUIElementTypeWindow/**/<*", @"**/~*", @"^", @">", @"<", @"~", @"^[1]", @"~/*", @"XCUIElementTypeWindow/^",
    @"XCUIElementTypeWindow/..x", @"XCUIElementTypeWindow/.", @"XCUIElementTypeWindow./..", @"XCUIElementTypeWindow..",
    @"^^XCUIElementTypeCell", @">>*", @"^>*", @">**/*", @"^**", @"^XCUIElementTypeCell[0]", @"^XCUIElementTypeCell[1][2]",
    @"^XCUIElementTypeCell[1][`identifier == 'a'`]", @"^blabla", @"XCUIElementTypeWindow/../", @"XCUIElementTypeWindow/..//*",
    @"XCUIElementTypeWindow^XCUIElementTypeCell", @"XCUIElementTypeWindow>*", @"XCUIElementTypeWindow/ ..",
  ];
  for (NSString *query in invalidQueries) {
    NSError *error = nil;
    XCTAssertNil([FBClassChainQueryParser parseQuery:query error:&error], @"%@", query);
    XCTAssertNotNil(error, @"%@", query);
  }
}

- (void)testAxisErrorMessages
{
  NSDictionary<NSString *, NSString *> *expectations = @{
    @"**/..": @"Cannot parse class chain query '**/..'. Unexpected character detected at position 4:\n**/. <----",
    @"..XCUIElementTypeButton": @"Cannot parse class chain query '..XCUIElementTypeButton'. Unexpected character detected at position 3:\n..X <----",
    @"..[1]": @"Cannot parse class chain query '..[1]'. Unexpected character detected at position 4:\n..[1 <----",
    @"XCUIElementTypeWindow/.": @"Cannot parse class chain query 'XCUIElementTypeWindow/.'. Unexpected character detected at position 23:\nXCUIElementTypeWindow/. <----",
    @"XCUIElementTypeWindow/**/^*": @"Cannot parse class chain query 'XCUIElementTypeWindow/**/^*'. Unexpected character detected at position 26:\nXCUIElementTypeWindow/**/^ <----",
    @"^blabla": @"Cannot parse class chain query '^blabla'. 'blabla' class name is unknown to WDA",
  };
  for (NSString *query in expectations) {
    NSError *error = nil;
    XCTAssertNil([FBClassChainQueryParser parseQuery:query error:&error], @"%@", query);
    XCTAssertEqualObjects(error.localizedDescription, expectations[query], @"%@", query);
  }
}

- (void)testAxisItemsKeepLegacyInitializerSemantics
{
  FBClassChainItem *child = [[FBClassChainItem alloc] initWithType:XCUIElementTypeButton position:nil predicates:@[] isDescendant:NO];
  FBClassChainItem *descendant = [[FBClassChainItem alloc] initWithType:XCUIElementTypeButton position:nil predicates:@[] isDescendant:YES];
  FBClassChainItem *parent = [[FBClassChainItem alloc] initWithType:XCUIElementTypeAny position:nil predicates:@[] axis:FBClassChainAxisParent];
  XCTAssertEqual(child.axis, FBClassChainAxisChild);
  XCTAssertFalse(child.isDescendant);
  XCTAssertEqual(descendant.axis, FBClassChainAxisDescendant);
  XCTAssertTrue(descendant.isDescendant);
  XCTAssertFalse(parent.isDescendant);
}

- (void)testErrorMessages
{
  NSDictionary<NSString *, NSString *> *expectations = @{
    @"": @"Cannot parse class chain query ''. The query must not be empty.",
    @"XCUIElementTypeWindow//*": @"Cannot parse class chain query 'XCUIElementTypeWindow//*'. Unexpected character detected at position 23:\nXCUIElementTypeWindow// <----",
    @"XCUIElementTypeWindow/": @"Cannot parse class chain query 'XCUIElementTypeWindow/'. Unexpected character detected at position 22:\nXCUIElementTypeWindow/ <----",
    @"blabla": @"Cannot parse class chain query 'blabla'. 'blabla' class name is unknown to WDA",
    @"XCUIElementTypeWindow[0]": @"Cannot parse class chain query 'XCUIElementTypeWindow[0]'. Position value '0' is expected to be a valid integer number not equal to zero.",
    @"XCUIElementTypeWindow[1][2]": @"Cannot parse class chain query 'XCUIElementTypeWindow[1][2]'. Position value '2' is expected to be set only once.",
    @"XCUIElementTypeWindow[1][`identifier == 'a'`]": @"Cannot parse class chain query 'XCUIElementTypeWindow[1][`identifier == 'a'`]'. Predicate value 'identifier == 'a'' must be set before position value.",
    @"**/**/XCUIElementTypeWindow": @"Cannot parse class chain query '**/**/XCUIElementTypeWindow'. Unexpected token '**/'. Descendant markers cannot be duplicated.",
  };
  for (NSString *query in expectations) {
    NSError *error = nil;
    XCTAssertNil([FBClassChainQueryParser parseQuery:query error:&error], @"%@", query);
    XCTAssertEqualObjects(error.localizedDescription, expectations[query], @"%@", query);
  }
}

@end


// A snapshot tree with just enough behavior for the in-memory class chain evaluation
@interface FBTreeSnapshotDouble : NSObject
@property (nonatomic, assign) XCUIElementType elementType;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSArray<FBTreeSnapshotDouble *> *children;
@end

@implementation FBTreeSnapshotDouble

+ (instancetype)type:(XCUIElementType)type label:(NSString *)label children:(NSArray<FBTreeSnapshotDouble *> *)children
{
  FBTreeSnapshotDouble *result = [FBTreeSnapshotDouble new];
  result.elementType = type;
  result.label = label;
  result.children = children;
  return result;
}

@end

@interface XCUIElement (FBClassChainTesting)
+ (NSArray *)am_snapshotsMatchingChainItems:(NSArray<FBClassChainItem *> *)chainItems
                            contextSnapshot:(id)contextSnapshot
                               rootSnapshot:(id)rootSnapshot
                shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch;
@end

// Evaluates the axis queries over a snapshot tree
@interface FBClassChainAxisEvaluationTests : XCTestCase
@property (nonatomic) FBTreeSnapshotDouble *root;
@end

@implementation FBClassChainAxisEvaluationTests

- (void)setUp
{
  [super setUp];
  // app > window > [group g1 > [b1 b2 b3 b4], group g2 > [b5], v0 > v1 > v2 > v3]
  FBTreeSnapshotDouble *(^button)(NSString *) = ^FBTreeSnapshotDouble *(NSString *label) {
    return [FBTreeSnapshotDouble type:XCUIElementTypeButton label:label children:@[]];
  };
  FBTreeSnapshotDouble *group1 = [FBTreeSnapshotDouble type:XCUIElementTypeOther label:@"g1"
                                                   children:@[button(@"b1"), button(@"b2"), button(@"b3"), button(@"b4")]];
  FBTreeSnapshotDouble *group2 = [FBTreeSnapshotDouble type:XCUIElementTypeOther label:@"g2" children:@[button(@"b5")]];
  FBTreeSnapshotDouble *nested = [FBTreeSnapshotDouble type:XCUIElementTypeOther label:@"v3" children:@[]];
  for (NSString *label in @[@"v2", @"v1", @"v0"]) {
    nested = [FBTreeSnapshotDouble type:XCUIElementTypeOther label:label children:@[nested]];
  }
  FBTreeSnapshotDouble *window = [FBTreeSnapshotDouble type:XCUIElementTypeWindow label:@"window" children:@[group1, group2, nested]];
  self.root = [FBTreeSnapshotDouble type:XCUIElementTypeApplication label:@"app" children:@[window]];
}

- (NSArray<NSString *> *)labelsForQuery:(NSString *)query
{
  return [self labelsForQuery:query from:self.root firstMatch:NO];
}

- (NSArray<NSString *> *)labelsForQuery:(NSString *)query from:(FBTreeSnapshotDouble *)start firstMatch:(BOOL)firstMatch
{
  NSError *error;
  FBClassChain *chain = [FBClassChainQueryParser parseQuery:query error:&error];
  XCTAssertNotNil(chain, @"%@", error);
  NSArray *matches = [XCUIElement am_snapshotsMatchingChainItems:chain.elements
                                                 contextSnapshot:start
                                                    rootSnapshot:self.root
                                     shouldReturnAfterFirstMatch:firstMatch];
  return [matches valueForKey:@"label"];
}

- (void)testParentAndAncestors
{
  NSString *prefix = @"**/XCUIElementTypeButton[`label == 'b2'`]/";
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@".."]], @[@"g1"]);
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"../.."]], @[@"window"]);
  // Document order: the outermost ancestor comes first
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"^*"]], (@[@"app", @"window", @"g1"]));
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"^XCUIElementTypeOther[1]"]], @[@"g1"]);
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"^*[2]"]], @[@"window"]);
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"^*[-1]"]], @[@"app"]);
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"^XCUIElementTypeWindow"]], @[@"window"]);
}

- (void)testSiblings
{
  NSString *prefix = @"**/XCUIElementTypeButton[`label == 'b2'`]/";
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@">XCUIElementTypeButton"]], (@[@"b3", @"b4"]));
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"<XCUIElementTypeButton"]], @[@"b1"]);
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"~XCUIElementTypeButton"]], (@[@"b1", @"b3", @"b4"]));
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@">XCUIElementTypeButton[1]"]], @[@"b3"]);
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@">XCUIElementTypeButton[-1]"]], @[@"b4"]);
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"~XCUIElementTypeButton[-1]"]], @[@"b4"]);
  prefix = @"**/XCUIElementTypeButton[`label == 'b4'`]/";
  // Preceding positions count backwards from the starting element
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"<XCUIElementTypeButton[1]"]], @[@"b3"]);
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"<XCUIElementTypeButton[-1]"]], @[@"b1"]);
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"<XCUIElementTypeButton"]], (@[@"b1", @"b2", @"b3"]));
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"~XCUIElementTypeButton[`label != 'b2'`][2]"]], @[@"b3"]);
}

- (void)testPredicatesOnAxisSteps
{
  NSString *prefix = @"**/XCUIElementTypeButton[`label == 'b1'`]/";
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"~XCUIElementTypeButton[`label IN {'b2', 'b4'}`]"]], (@[@"b2", @"b4"]));
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"..[`label == 'g1'`]/XCUIElementTypeButton[1]"]], @[@"b1"]);
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"..[`label == 'nope'`]"]], @[]);
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"^*[`label == 'window'`]"]], @[@"window"]);
}

- (void)testPositionedStepsBeforeAxes
{
  XCTAssertEqualObjects([self labelsForQuery:@"**/XCUIElementTypeButton[3]/>XCUIElementTypeButton[1]"], @[@"b4"]);
  XCTAssertEqualObjects([self labelsForQuery:@"**/XCUIElementTypeOther[`label == 'g1'`][1]/XCUIElementTypeButton[2]/<XCUIElementTypeButton"], @[@"b1"]);
}

- (void)testChainedAxesAndLaterSteps
{
  NSString *prefix = @"**/XCUIElementTypeButton[`label == 'b2'`]/";
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"../XCUIElementTypeButton[`label == 'b4'`]"]], @[@"b4"]);
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"../**/XCUIElementTypeButton[`label == 'b3'`]"]], @[@"b3"]);
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@">XCUIElementTypeButton[2]/<XCUIElementTypeButton[1]"]], @[@"b3"]);
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"^XCUIElementTypeWindow/XCUIElementTypeOther[2]/XCUIElementTypeButton"]], @[@"b5"]);
}

- (void)testSeveralStartingElements
{
  // Overlapping roots do not produce duplicates, the matches come in document order
  XCTAssertEqualObjects([self labelsForQuery:@"**/XCUIElementTypeButton/.."], (@[@"g1", @"g2"]));
  XCTAssertEqualObjects([self labelsForQuery:@"**/XCUIElementTypeButton/^XCUIElementTypeWindow"], @[@"window"]);
  // Candidates of all the starting elements are merged in document order before the position is applied
  NSString *prefix = @"**/XCUIElementTypeButton[`label IN {'b2', 'b4'}`]/";
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"~XCUIElementTypeButton[1]"]], @[@"b1"]);
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"~XCUIElementTypeButton[-1]"]], @[@"b4"]);
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@">XCUIElementTypeButton[1]"]], @[@"b3"]);
  XCTAssertEqualObjects([self labelsForQuery:[prefix stringByAppendingString:@"<XCUIElementTypeButton"]], (@[@"b1", @"b2", @"b3"]));
}

- (void)testNextStepFollowsAxisMatchesInDocumentOrder
{
  // The ancestors of v2 come before the ancestors of v3 in the candidates, but not in the document
  NSString *query = @"**/XCUIElementTypeOther[`label IN {'v2', 'v3'}`]/^XCUIElementTypeOther[`label BEGINSWITH 'v'`]/XCUIElementTypeOther[1]";
  XCTAssertEqualObjects([self labelsForQuery:query], @[@"v1"]);
}

- (void)testFirstMatch
{
  NSString *query = @"**/XCUIElementTypeButton[`label == 'b3'`]/~XCUIElementTypeButton";
  XCTAssertEqualObjects([self labelsForQuery:query from:self.root firstMatch:YES], @[@"b1"]);
  XCTAssertEqualObjects([self labelsForQuery:@"**/XCUIElementTypeButton/.." from:self.root firstMatch:YES], @[@"g1"]);
}

- (void)testEmptyResults
{
  XCTAssertEqualObjects([self labelsForQuery:@".."], @[]);
  XCTAssertEqualObjects([self labelsForQuery:@"**/XCUIElementTypeButton[`label == 'nope'`]/.."], @[]);
  XCTAssertEqualObjects([self labelsForQuery:@"**/XCUIElementTypeButton[`label == 'b1'`]/<XCUIElementTypeButton"], @[]);
  XCTAssertEqualObjects([self labelsForQuery:@"**/XCUIElementTypeButton[`label == 'b1'`]/>XCUIElementTypeButton[20]"], @[]);
  XCTAssertEqualObjects([self labelsForQuery:@"**/XCUIElementTypeButton[`label == 'b1'`]/^XCUIElementTypeButton"], @[]);
  XCTAssertEqualObjects([self labelsForQuery:@"**/XCUIElementTypeButton[`label == 'b5'`]/~XCUIElementTypeButton"], @[]);
}

- (void)testContextElement
{
  FBTreeSnapshotDouble *b3 = self.root.children.firstObject.children.firstObject.children[2];
  XCTAssertEqualObjects([self labelsForQuery:@">XCUIElementTypeButton[1]" from:b3 firstMatch:NO], @[@"b4"]);
  XCTAssertEqualObjects([self labelsForQuery:@"<XCUIElementTypeButton[1]" from:b3 firstMatch:NO], @[@"b2"]);
  XCTAssertEqualObjects([self labelsForQuery:@".." from:b3 firstMatch:NO], @[@"g1"]);
  XCTAssertEqualObjects([self labelsForQuery:@"../XCUIElementTypeButton[`label == 'b1'`]" from:b3 firstMatch:NO], @[@"b1"]);
  XCTAssertEqualObjects([self labelsForQuery:@"^XCUIElementTypeOther[1]" from:b3 firstMatch:NO], @[@"g1"]);
}

@end
