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

/**
 Collects the hashes of snapshot tree nodes whose identifier equals the given value.

 @return YES if the caller should stop descending, which happens as soon as a match is
 found while only the first one is wanted
 */
static BOOL AMCollectIdentifierMatches(id<XCUIElementSnapshot> snapshot,
                                       NSString *accessibilityId,
                                       BOOL firstMatchOnly,
                                       NSMutableSet<NSString *> *matchedHashes)
{
  if (nil == snapshot) {
    return NO;
  }
  if ([[AMSnapshotUtils wdIdentifierWithSnapshot:snapshot] isEqualToString:accessibilityId]) {
    [matchedHashes addObject:[AMSnapshotUtils hashWithSnapshot:snapshot]];
    if (firstMatchOnly) {
      return YES;
    }
  }
  for (id<XCUIElementSnapshot> child in snapshot.children) {
    if (AMCollectIdentifierMatches(child, accessibilityId, firstMatchOnly, matchedHashes)) {
      return YES;
    }
  }
  return NO;
}

@interface XCUIElement (FBFindPrivate)

- (NSArray<XCUIElement *> *)am_descendantsMatchingDomIdentifier:(NSString *)accessibilityId
                                    shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch;

@end

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
      || !FBConfiguration.sharedConfiguration.useDomIdAsAccessibilityId) {
    return result.copy;
  }
  // WebKit leaves the standard accessibility identifier of web nodes empty, so the
  // above query cannot match them. Retry through their DOM identifiers.
  return [self am_descendantsMatchingDomIdentifier:accessibilityId
                       shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch];
}

- (NSArray<XCUIElement *> *)am_descendantsMatchingDomIdentifier:(NSString *)accessibilityId
                                    shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  // Walk a single root snapshot in memory and only resolve the matching nodes back
  // to elements. Binding every descendant up front and snapshotting each one
  // separately exceeds the request timeout on large web trees.
  id<XCUIElementSnapshot> rootSnapshot = [self snapshotWithError:nil];
  if (nil == rootSnapshot) {
    return @[];
  }
  NSMutableSet<NSString *> *matchedHashes = [NSMutableSet set];
  AMCollectIdentifierMatches(rootSnapshot, accessibilityId, shouldReturnAfterFirstMatch, matchedHashes);
  return [AMSnapshotUtils elementsWithHashes:matchedHashes.copy
                                 rootElement:self
                                rootSnapshot:rootSnapshot
                       includeOnlyFirstMatch:shouldReturnAfterFirstMatch];
}

@end
