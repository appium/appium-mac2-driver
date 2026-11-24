/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBClassChain.h"

#import "AMSnapshotUtils.h"
#import "FBClassChainQueryParser.h"
#import "FBExceptions.h"
#import "FBSession.h"
#import "XCUIElementQuery+AMHelpers.h"

static BOOL AMIsAxisItem(FBClassChainItem *item)
{
  return FBClassChainAxisChild != item.axis && FBClassChainAxisDescendant != item.axis;
}

/*! The parent, children and document order of every node of a snapshot tree, collected in one pass */
@interface AMSnapshotTree : NSObject

@property (nonatomic, readonly) id<XCUIElementSnapshot> root;

- (instancetype)initWithRoot:(id<XCUIElementSnapshot>)root;
- (nullable id<XCUIElementSnapshot>)parentOf:(id<XCUIElementSnapshot>)snapshot;
- (NSArray<id<XCUIElementSnapshot>> *)childrenOf:(id<XCUIElementSnapshot>)snapshot;
- (NSArray<id<XCUIElementSnapshot>> *)descendantsOf:(id<XCUIElementSnapshot>)snapshot;
- (NSArray<id<XCUIElementSnapshot>> *)inDocumentOrder:(NSArray<id<XCUIElementSnapshot>> *)snapshots;

@end

@implementation AMSnapshotTree {
  NSMapTable<id, id> *_parents;
  NSMapTable<id, NSArray *> *_children;
  NSMapTable<id, NSNumber *> *_positions;
}

- (instancetype)initWithRoot:(id<XCUIElementSnapshot>)root
{
  self = [super init];
  if (self) {
    _root = root;
    _parents = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality
                                     valueOptions:NSPointerFunctionsObjectPointerPersonality];
    _children = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality
                                      valueOptions:NSPointerFunctionsStrongMemory];
    _positions = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPointerPersonality
                                       valueOptions:NSPointerFunctionsStrongMemory];
    [self indexSubtree:root];
  }
  return self;
}

// Iterative pre-order walk, so deep trees cannot overflow the stack
- (void)indexSubtree:(id<XCUIElementSnapshot>)root
{
  NSUInteger position = 0;
  NSMutableArray<id<XCUIElementSnapshot>> *stack = [NSMutableArray arrayWithObject:root];
  while (stack.count > 0) {
    id<XCUIElementSnapshot> node = stack.lastObject;
    [stack removeLastObject];
    [_positions setObject:@(position++) forKey:node];
    NSArray<id<XCUIElementSnapshot>> *children = node.children ?: @[];
    [_children setObject:children forKey:node];
    for (id<XCUIElementSnapshot> child in children.reverseObjectEnumerator) {
      [_parents setObject:node forKey:child];
      [stack addObject:child];
    }
  }
}

- (id<XCUIElementSnapshot>)parentOf:(id<XCUIElementSnapshot>)snapshot
{
  return [_parents objectForKey:snapshot];
}

- (NSArray<id<XCUIElementSnapshot>> *)childrenOf:(id<XCUIElementSnapshot>)snapshot
{
  return [_children objectForKey:snapshot] ?: @[];
}

- (NSArray<id<XCUIElementSnapshot>> *)descendantsOf:(id<XCUIElementSnapshot>)snapshot
{
  NSMutableArray<id<XCUIElementSnapshot>> *result = [NSMutableArray array];
  NSMutableArray<id<XCUIElementSnapshot>> *stack = [NSMutableArray arrayWithArray:[[self childrenOf:snapshot] reverseObjectEnumerator].allObjects];
  while (stack.count > 0) {
    id<XCUIElementSnapshot> node = stack.lastObject;
    [stack removeLastObject];
    [result addObject:node];
    [stack addObjectsFromArray:[[self childrenOf:node] reverseObjectEnumerator].allObjects];
  }
  return result.copy;
}

- (NSArray<id<XCUIElementSnapshot>> *)inDocumentOrder:(NSArray<id<XCUIElementSnapshot>> *)snapshots
{
  if (snapshots.count < 2) {
    return snapshots;
  }
  NSNumber *unknown = @(NSUIntegerMax);
  return [snapshots sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(id a, id b) {
    return [([_positions objectForKey:a] ?: unknown) compare:([_positions objectForKey:b] ?: unknown)];
  }];
}

@end

@interface XCUIElement (AMClassChainAxes)

/*! Evaluates the chain in memory on the tree under the root snapshot, the context snapshot belongs to it */
+ (NSArray<id<XCUIElementSnapshot>> *)am_snapshotsMatchingChainItems:(NSArray<FBClassChainItem *> *)chainItems
                                                     contextSnapshot:(id<XCUIElementSnapshot>)contextSnapshot
                                                        rootSnapshot:(id<XCUIElementSnapshot>)rootSnapshot
                                         shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch;

+ (NSArray<id<XCUIElementSnapshot>> *)am_snapshotsMatchingChainItems:(NSArray<FBClassChainItem *> *)chainItems
                                                     contextSnapshot:(id<XCUIElementSnapshot>)contextSnapshot
                                                                tree:(AMSnapshotTree *)tree
                                         shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch;

@end

@implementation XCUIElement (FBClassChain)

- (NSArray<XCUIElement *> *)fb_descendantsMatchingClassChain:(NSString *)classChainQuery
                                 shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  NSError *error;
  FBClassChain *parsedChain = [FBClassChainQueryParser parseQuery:classChainQuery error:&error];
  if (nil == parsedChain) {
    @throw [NSException exceptionWithName:FBClassChainQueryParseException reason:error.localizedDescription userInfo:error.userInfo];
    return nil;
  }
  for (FBClassChainItem *item in parsedChain.elements) {
    if (AMIsAxisItem(item)) {
      // XCUIElementQuery has no parent/sibling axes, so such chains are evaluated on snapshots
      return [self am_descendantsMatchingAxisChainItems:parsedChain.elements
                            shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch];
    }
  }
  NSMutableArray<FBClassChainItem *> *lookupChain = parsedChain.elements.mutableCopy;
  FBClassChainItem *chainItem = lookupChain.firstObject;
  XCUIElement *currentRoot = self;
  XCUIElementQuery *query = [currentRoot fb_queryWithChainItem:chainItem query:nil];
  [lookupChain removeObjectAtIndex:0];
  while (lookupChain.count > 0) {
    BOOL isRootChanged = NO;
    if (nil != chainItem.position) {
      // It is necessary to resolve the query if intermediate element index is not zero or one,
      // because predicates don't support search by indexes
      NSArray<XCUIElement *> *currentRootMatch = [self.class fb_matchingElementsWithItem:chainItem
                                                                                   query:query
                                                             shouldReturnAfterFirstMatch:nil];
      if (0 == currentRootMatch.count) {
        return @[];
      }
      currentRoot = currentRootMatch.firstObject;
      isRootChanged = YES;
    }
    chainItem = [lookupChain firstObject];
    query = [currentRoot fb_queryWithChainItem:chainItem query:isRootChanged ? nil : query];
    [lookupChain removeObjectAtIndex:0];
  }
  return [self.class fb_matchingElementsWithItem:chainItem
                                           query:query
                     shouldReturnAfterFirstMatch:@(shouldReturnAfterFirstMatch)];
}

- (XCUIElementQuery *)fb_queryWithChainItem:(FBClassChainItem *)item
                                      query:(nullable XCUIElementQuery *)query
{
  if (item.isDescendant) {
    if (query) {
      query = [query descendantsMatchingType:item.type];
    } else {
      query = [self descendantsMatchingType:item.type];
    }
  } else {
    if (query) {
      query = [query childrenMatchingType:item.type];
    } else {
      query = [self childrenMatchingType:item.type];
    }
  }
  if (item.predicates) {
    for (FBAbstractPredicateItem *predicate in item.predicates) {
      if ([predicate isKindOfClass:FBSelfPredicateItem.class]) {
        query = [query matchingPredicate:predicate.value];
      } else if ([predicate isKindOfClass:FBDescendantPredicateItem.class]) {
        query = [query containingPredicate:predicate.value];
      }
    }
  }
  return query;
}

+ (NSArray<XCUIElement *> *)fb_matchingElementsWithItem:(FBClassChainItem *)item
                                                  query:(XCUIElementQuery *)query
                            shouldReturnAfterFirstMatch:(nullable NSNumber *)shouldReturnAfterFirstMatch
{
  if (1 == item.position.integerValue || (0 == item.position.integerValue && shouldReturnAfterFirstMatch.boolValue)) {
    XCUIElement *result = query.am_firstMatch;
    return result ? @[result] : @[];
  }
  NSArray<XCUIElement *> *allMatches = query.am_allMatches;
  if (0 == item.position.integerValue) {
    return allMatches;
  }
  if (allMatches.count >= (NSUInteger)ABS(item.position.integerValue)) {
    return item.position.integerValue > 0
      ? @[[allMatches objectAtIndex:item.position.integerValue - 1]]
      : @[[allMatches objectAtIndex:allMatches.count + item.position.integerValue]];
  }
  return @[];
}

#pragma mark - Axis chains

- (NSArray<XCUIElement *> *)am_descendantsMatchingAxisChainItems:(NSArray<FBClassChainItem *> *)chainItems
                                     shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  NSError *error;
  id<XCUIElementSnapshot> contextSnapshot = [self snapshotWithError:&error];
  if (nil == contextSnapshot) {
    NSString *reason = [NSString stringWithFormat:@"Cannot take a snapshot of the element to evaluate the class chain. Original error: %@", error.description];
    @throw [NSException exceptionWithName:FBClassChainQueryParseException reason:reason userInfo:@{}];
  }
  // Axes may leave the subtree of the element, so the whole application is snapshotted if the element belongs to it
  XCUIElement *rootElement = self;
  AMSnapshotTree *tree = nil;
  XCUIApplication *application = [self am_owningApplication];
  id<XCUIElementSnapshot> applicationSnapshot = application ? [application snapshotWithError:nil] : nil;
  if (nil != applicationSnapshot) {
    AMSnapshotTree *applicationTree = [[AMSnapshotTree alloc] initWithRoot:applicationSnapshot];
    id<XCUIElementSnapshot> mappedContext = [self.class am_snapshotWithHash:[AMSnapshotUtils hashWithSnapshot:contextSnapshot]
                                                                     inTree:applicationTree];
    if (nil != mappedContext) {
      rootElement = application;
      tree = applicationTree;
      contextSnapshot = mappedContext;
    }
  }
  if (nil == tree) {
    tree = [[AMSnapshotTree alloc] initWithRoot:contextSnapshot];
  }
  NSArray<id<XCUIElementSnapshot>> *matches = [self.class am_snapshotsMatchingChainItems:chainItems
                                                                         contextSnapshot:contextSnapshot
                                                                                    tree:tree
                                                             shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch];
  if (0 == matches.count) {
    return @[];
  }
  NSMutableSet<NSString *> *hashes = [NSMutableSet setWithCapacity:matches.count];
  for (id<XCUIElementSnapshot> match in matches) {
    [hashes addObject:[AMSnapshotUtils hashWithSnapshot:match]];
  }
  return [AMSnapshotUtils elementsWithHashes:hashes.copy
                                 rootElement:rootElement
                                rootSnapshot:tree.root
                       includeOnlyFirstMatch:shouldReturnAfterFirstMatch];
}

- (nullable XCUIApplication *)am_owningApplication
{
  if ([self isKindOfClass:XCUIApplication.class]) {
    return (XCUIApplication *)self;
  }
  // The private property is not available in all XCTest versions
  if ([self respondsToSelector:NSSelectorFromString(@"application")]) {
    id application = [self valueForKey:@"application"];
    if ([application isKindOfClass:XCUIApplication.class]) {
      return application;
    }
  }
  return FBSession.activeSession.currentApplication;
}

+ (nullable id<XCUIElementSnapshot>)am_snapshotWithHash:(NSString *)snapshotHash inTree:(AMSnapshotTree *)tree
{
  if (nil == snapshotHash) {
    return nil;
  }
  NSArray<id<XCUIElementSnapshot>> *all = [@[tree.root] arrayByAddingObjectsFromArray:[tree descendantsOf:tree.root]];
  for (id<XCUIElementSnapshot> snapshot in all) {
    if ([[AMSnapshotUtils hashWithSnapshot:snapshot] isEqualToString:snapshotHash]) {
      return snapshot;
    }
  }
  return nil;
}

+ (NSArray<id<XCUIElementSnapshot>> *)am_snapshotsMatchingChainItems:(NSArray<FBClassChainItem *> *)chainItems
                                                     contextSnapshot:(id<XCUIElementSnapshot>)contextSnapshot
                                                        rootSnapshot:(id<XCUIElementSnapshot>)rootSnapshot
                                         shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  return [self am_snapshotsMatchingChainItems:chainItems
                              contextSnapshot:contextSnapshot
                                         tree:[[AMSnapshotTree alloc] initWithRoot:rootSnapshot]
                  shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch];
}

// Matches come in document order, whatever the axes inside the chain are
+ (NSArray<id<XCUIElementSnapshot>> *)am_snapshotsMatchingChainItems:(NSArray<FBClassChainItem *> *)chainItems
                                                     contextSnapshot:(id<XCUIElementSnapshot>)contextSnapshot
                                                                tree:(AMSnapshotTree *)tree
                                         shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  NSArray<id<XCUIElementSnapshot>> *currentRoots = @[contextSnapshot];
  for (NSUInteger i = 0; i < chainItems.count; i++) {
    FBClassChainItem *chainItem = chainItems[i];
    NSArray<id<XCUIElementSnapshot>> *candidates = [self am_snapshotsMatchingItem:chainItem inRoots:currentRoots tree:tree];
    if (i + 1 == chainItems.count) {
      // Positions of axis items count along the axis, the matches are put in document order afterwards
      NSArray<id<XCUIElementSnapshot>> *matches = [tree inDocumentOrder:[self am_snapshotsWithItem:chainItem candidates:candidates]];
      return shouldReturnAfterFirstMatch && matches.count > 1 ? @[matches.firstObject] : matches;
    }
    if (nil != chainItem.position) {
      // An explicit position narrows the matches down to a single element, which becomes the root of the next step
      NSArray<id<XCUIElementSnapshot>> *selected = [self am_snapshotsWithItem:chainItem candidates:candidates];
      if (0 == selected.count) {
        return @[];
      }
      currentRoots = @[selected.firstObject];
    } else {
      // Matches of an axis step follow each other per root element, the next step needs them in document order
      currentRoots = AMIsAxisItem(chainItem) ? [tree inDocumentOrder:candidates] : candidates;
    }
  }
  return @[];
}

+ (NSArray<id<XCUIElementSnapshot>> *)am_snapshotsMatchingItem:(FBClassChainItem *)item
                                                       inRoots:(NSArray<id<XCUIElementSnapshot>> *)roots
                                                          tree:(AMSnapshotTree *)tree
{
  NSMutableArray<id<XCUIElementSnapshot>> *typeMatches = [NSMutableArray array];
  for (id<XCUIElementSnapshot> root in roots) {
    NSArray<id<XCUIElementSnapshot>> *pool;
    if (AMIsAxisItem(item)) {
      pool = [self am_axisSnapshotsOfRoot:root axis:item.axis tree:tree];
    } else if (item.isDescendant) {
      pool = [tree descendantsOf:root];
    } else {
      pool = [tree childrenOf:root];
    }
    for (id<XCUIElementSnapshot> candidate in pool) {
      if (item.type == XCUIElementTypeAny || candidate.elementType == item.type) {
        [typeMatches addObject:candidate];
      }
    }
  }
  if (roots.count > 1) {
    // Overlapping roots can yield the same snapshot twice, which would skew positions
    NSMutableArray<id<XCUIElementSnapshot>> *deduped = [NSMutableArray arrayWithCapacity:typeMatches.count];
    NSHashTable<id<XCUIElementSnapshot>> *seen = [NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality];
    for (id<XCUIElementSnapshot> match in typeMatches) {
      if (![seen containsObject:match]) {
        [seen addObject:match];
        [deduped addObject:match];
      }
    }
    typeMatches = deduped;
    if (FBClassChainAxisFollowingSibling == item.axis || FBClassChainAxisSibling == item.axis) {
      // Positions of these axes count in document order of all the candidates
      typeMatches = [[tree inDocumentOrder:typeMatches] mutableCopy];
    }
  }
  for (FBAbstractPredicateItem *predicateItem in item.predicates) {
    if ([predicateItem isKindOfClass:FBSelfPredicateItem.class]) {
      typeMatches = [[typeMatches filteredArrayUsingPredicate:predicateItem.value] mutableCopy];
    } else if ([predicateItem isKindOfClass:FBDescendantPredicateItem.class]) {
      NSMutableArray<id<XCUIElementSnapshot>> *containing = [NSMutableArray array];
      for (id<XCUIElementSnapshot> candidate in typeMatches) {
        for (id<XCUIElementSnapshot> descendant in [tree descendantsOf:candidate]) {
          if ([predicateItem.value evaluateWithObject:descendant]) {
            [containing addObject:candidate];
            break;
          }
        }
      }
      typeMatches = containing;
    }
  }
  return typeMatches.copy;
}

// The snapshots on the axis in the order positions count along it
+ (NSArray<id<XCUIElementSnapshot>> *)am_axisSnapshotsOfRoot:(id<XCUIElementSnapshot>)root
                                                        axis:(FBClassChainAxis)axis
                                                        tree:(AMSnapshotTree *)tree
{
  id<XCUIElementSnapshot> parent = [tree parentOf:root];
  if (nil == parent) {
    return @[];
  }
  switch (axis) {
    case FBClassChainAxisParent:
      return @[parent];
    case FBClassChainAxisAncestor: {
      NSMutableArray<id<XCUIElementSnapshot>> *ancestors = [NSMutableArray array];
      for (id<XCUIElementSnapshot> ancestor = parent; nil != ancestor; ancestor = [tree parentOf:ancestor]) {
        [ancestors addObject:ancestor];
      }
      return ancestors.copy;
    }
    case FBClassChainAxisFollowingSibling:
    case FBClassChainAxisPrecedingSibling:
    case FBClassChainAxisSibling: {
      NSArray<id<XCUIElementSnapshot>> *siblings = [tree childrenOf:parent];
      NSUInteger index = [siblings indexOfObjectIdenticalTo:root];
      if (NSNotFound == index) {
        return @[];
      }
      NSRange range = NSMakeRange(0, siblings.count);
      if (FBClassChainAxisFollowingSibling == axis) {
        range = NSMakeRange(index + 1, siblings.count - index - 1);
      } else if (FBClassChainAxisPrecedingSibling == axis) {
        range = NSMakeRange(0, index);
      }
      NSMutableArray<id<XCUIElementSnapshot>> *result = [NSMutableArray array];
      for (NSUInteger i = range.location; i < NSMaxRange(range); i++) {
        if (i != index) {
          [result addObject:siblings[i]];
        }
      }
      return FBClassChainAxisPrecedingSibling == axis
        ? result.reverseObjectEnumerator.allObjects
        : result.copy;
    }
    case FBClassChainAxisChild:
    case FBClassChainAxisDescendant:
      return @[];
  }
}

+ (NSArray<id<XCUIElementSnapshot>> *)am_snapshotsWithItem:(FBClassChainItem *)item
                                                candidates:(NSArray<id<XCUIElementSnapshot>> *)candidates
{
  NSInteger position = item.position.integerValue;
  if (0 == position) {
    return candidates;
  }
  if (candidates.count < (NSUInteger)ABS(position)) {
    return @[];
  }
  return position > 0
    ? @[candidates[position - 1]]
    : @[candidates[candidates.count + position]];
}

@end
