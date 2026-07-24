/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBFind.h"

#import "AMSnapshotUtils.h"
#import "FBConfiguration.h"
#import "FBElementTypeTransformer.h"
#import "FBElementUtils.h"
#import "FBXPath.h"
#import "NSPredicate+FBFormat.h"
#import "XCUIElementQuery+AMHelpers.h"

@implementation XCUIElement (FBFind)

+ (NSArray<XCUIElement *> *)fb_extractMatchingElementsFromQuery:(XCUIElementQuery *)query
                                    shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  if (!shouldReturnAfterFirstMatch) {
    return query.am_allMatches;
  }
  XCUIElement *matchedElement = query.am_firstMatch;
  return matchedElement ? @[matchedElement] : @[];
}

#pragma mark - Search by ClassName

- (NSArray<XCUIElement *> *)fb_descendantsMatchingClassName:(NSString *)className
                                shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  XCUIElementType type = [FBElementTypeTransformer elementTypeWithTypeName:className];
  NSMutableArray *result = [NSMutableArray array];
  if (type == XCUIElementTypeAny || self.elementType == type) {
    [result addObject:self];
    if (shouldReturnAfterFirstMatch) {
      return result.copy;
    }
  }
  XCUIElementQuery *query = [self descendantsMatchingType:type];
  [result addObjectsFromArray:[self.class fb_extractMatchingElementsFromQuery:query
                                                  shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch]];
  return result.copy;
}

#pragma mark - Search by Predicate String

- (NSArray<XCUIElement *> *)fb_descendantsMatchingPredicate:(NSPredicate *)predicate
                                shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  NSPredicate *formattedPredicate = [NSPredicate fb_formatSearchPredicate:predicate];
  NSMutableArray<XCUIElement *> *result = [NSMutableArray array];
  // Include self element into predicate search
  if ([formattedPredicate evaluateWithObject:self]) {
    [result addObject:self];
    if (shouldReturnAfterFirstMatch) {
      return result.copy;
    }
  }
  XCUIElementQuery *query = [[self descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:formattedPredicate];
  [result addObjectsFromArray:[self.class fb_extractMatchingElementsFromQuery:query
                                                  shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch]];
  return result.copy;
}


#pragma mark - Search by xpath

- (NSArray<XCUIElement *> *)fb_descendantsMatchingXPathQuery:(NSString *)xpathQuery
                                 shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  // XPath will try to match elements only class name, so requesting elements by XCUIElementTypeAny will not work. We should use '*' instead.
  xpathQuery = [xpathQuery stringByReplacingOccurrencesOfString:@"XCUIElementTypeAny" withString:@"*"];
  return [FBXPath matchesWithRootElement:self
                                forQuery:xpathQuery
                   includeOnlyFirstMatch:shouldReturnAfterFirstMatch];
}


#pragma mark - Search by Accessibility Id

- (NSArray<XCUIElement *> *)fb_descendantsMatchingIdentifier:(NSString *)accessibilityId
                                 shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  NSMutableArray *result = [NSMutableArray array];
  if (nil != self.identifier && [self.identifier isEqualToString:accessibilityId]) {
    [result addObject:self];
    if (shouldReturnAfterFirstMatch) {
      return result.copy;
    }
  }
  XCUIElementQuery *query = [[self descendantsMatchingType:XCUIElementTypeAny] matchingIdentifier:accessibilityId];
  [result addObjectsFromArray:[self.class fb_extractMatchingElementsFromQuery:query
                                                  shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch]];
  if (result.count > 0
      || !FBConfiguration.sharedConfiguration.useDomIdAsAccessibilityId
      || ![AMSnapshotUtils isAccessibilityTrusted]) {
    return result.copy;
  }

  // Fallback for WebKit (WKWebView) web content: XCUIElement.identifier maps to
  // the standard AXIdentifier, which WebKit leaves empty for web nodes. The DOM
  // `id` is exposed via the non-standard AXDOMIdentifier attribute instead, so
  // match against that. Runs only when the `useDomIdAsAccessibilityId` setting is
  // enabled, the native match set is empty (native identifiers always win), and the
  // process is Accessibility-trusted — so native element locating is never altered.
  //
  // Performance: this materializes all descendants and reads AXDOMIdentifier per
  // element via a cross-process AX call. It runs only on the native-miss path and
  // short-circuits on the first match when requested; hence it is opt-in via the
  // setting (off by default).
  NSArray<XCUIElement *> *webDescendants = [[self descendantsMatchingType:XCUIElementTypeAny]
    allElementsBoundByAccessibilityElement];
  for (XCUIElement *descendant in webDescendants) {
    @autoreleasepool {
      NSString *domIdentifier = [AMSnapshotUtils domIdentifierWithSnapshot:[descendant snapshotWithError:nil]];
      if (nil != domIdentifier && [domIdentifier isEqualToString:accessibilityId]) {
        [result addObject:descendant];
        if (shouldReturnAfterFirstMatch) {
          return result.copy;
        }
      }
    }
  }
  return result.copy;
}

@end
