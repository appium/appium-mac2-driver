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
 Walks an in-memory snapshot tree and collects the hashes of nodes whose WebKit
 DOM identifier equals the given value.
 */
static void AMCollectDomIdentifierMatches(id<XCUIElementSnapshot> snapshot,
                                          NSString *accessibilityId,
                                          BOOL firstMatchOnly,
                                          NSMutableArray<NSString *> *matchedHashes)
{
  if (nil == snapshot || (firstMatchOnly && matchedHashes.count > 0)) {
    return;
  }
  NSString *domIdentifier = [AMSnapshotUtils domIdentifierWithSnapshot:snapshot];
  if (nil != domIdentifier && [domIdentifier isEqualToString:accessibilityId]) {
    [matchedHashes addObject:[AMSnapshotUtils hashWithSnapshot:snapshot]];
    if (firstMatchOnly) {
      return;
    }
  }
  for (id<XCUIElementSnapshot> child in snapshot.children) {
    AMCollectDomIdentifierMatches(child, accessibilityId, firstMatchOnly, matchedHashes);
  }
}

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

  // Fallback for WebKit (WKWebView) web content. XCUIElement.identifier maps to
  // the standard AXIdentifier attribute, which WebKit leaves empty for web
  // nodes, publishing the element's HTML `id` through the non-standard
  // AXDOMIdentifier attribute instead. Match against that, so web content is
  // locatable by accessibility id the same way as on other platforms.
  //
  // This only runs when the setting is enabled, the native match set is empty
  // (native identifiers always win) and the process is Accessibility-trusted,
  // so locating native elements is never affected.
  //
  // Take a single root snapshot and walk it in memory, then resolve just the
  // matching nodes back to elements with one hash predicate query, which is the
  // same technique the XPath search uses. Binding every descendant up front and
  // snapshotting each one separately is orders of magnitude slower and exceeds
  // the request timeout on large web trees.
  id<XCUIElementSnapshot> rootSnapshot = [self snapshotWithError:nil];
  if (nil == rootSnapshot) {
    return result.copy;
  }
  NSMutableArray<NSString *> *matchedHashes = [NSMutableArray array];
  AMCollectDomIdentifierMatches(rootSnapshot, accessibilityId, shouldReturnAfterFirstMatch, matchedHashes);
  if (0 == matchedHashes.count) {
    return result.copy;
  }
  if ([matchedHashes containsObject:[AMSnapshotUtils hashWithSnapshot:rootSnapshot]]) {
    [result addObject:self];
    if (shouldReturnAfterFirstMatch) {
      return result.copy;
    }
  }
  NSPredicate *hashPredicate = [NSPredicate predicateWithBlock:^BOOL(id snapshot, NSDictionary *bindings) {
    return [matchedHashes containsObject:[AMSnapshotUtils hashWithSnapshot:snapshot]];
  }];
  XCUIElementQuery *domQuery = [[self descendantsMatchingType:XCUIElementTypeAny]
                                matchingPredicate:hashPredicate];
  [result addObjectsFromArray:[self.class fb_extractMatchingElementsFromQuery:domQuery
                                                  shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch]];
  return result.copy;
}

@end
