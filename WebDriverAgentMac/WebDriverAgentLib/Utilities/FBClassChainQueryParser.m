/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <errno.h>

#import "FBClassChainQueryParser.h"
#import "FBErrorBuilder.h"
#import "FBElementTypeTransformer.h"
#import "FBExceptions.h"
#import "NSPredicate+FBFormat.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FBRawGroupKind) {
  FBRawGroupKindPosition,
  FBRawGroupKindSelfPredicate,
  FBRawGroupKindDescendantPredicate,
};

/*! A bracket group of a step as written in the query: `[1]`, `` [`...`] `` or `[$...$]` */
@interface FBRawGroup : NSObject

@property (nonatomic) FBRawGroupKind kind;
/*! The position digits, or the predicate text with doubled markers collapsed */
@property (nonatomic, copy) NSString *text;

@end

/*! A step that passed the syntax check, but is not resolved yet */
@interface FBRawStep : NSObject

@property (nonatomic) FBClassChainAxis axis;
/*! YES if the step is preceded by more than one descendant marker */
@property (nonatomic) BOOL hasDuplicatedMarker;
/*! nil stands for the star and for the parent axis */
@property (nonatomic, nullable, copy) NSString *className;
@property (nonatomic, readonly) NSMutableArray<FBRawGroup *> *groups;

@end

/*! Single pass syntax check of a class chain query, no tokens are created */
@interface FBClassChainScanner : NSObject

/*! Index of the character the scan has failed on */
@property (nonatomic, readonly) NSUInteger failureIndex;

- (instancetype)initWithQuery:(NSString *)query;
- (nullable NSArray<FBRawStep *> *)scan;

@end

NS_ASSUME_NONNULL_END


@implementation FBRawGroup
@end

@implementation FBRawStep

- (instancetype)init
{
  self = [super init];
  if (self) {
    _groups = [NSMutableArray array];
  }
  return self;
}

@end


static NSString *const DESCENDANT_MARKER = @"**/";

static BOOL FBIsPositionCharacter(unichar character)
{
  return '-' == character || (character >= '0' && character <= '9');
}

@implementation FBClassChainScanner {
  NSString *_query;
  NSUInteger _pos;
}

- (instancetype)initWithQuery:(NSString *)query
{
  self = [super init];
  if (self) {
    _query = query;
    _pos = 0;
    _failureIndex = 0;
  }
  return self;
}

- (BOOL)hasMore
{
  return _pos < _query.length;
}

- (unichar)current
{
  return [_query characterAtIndex:_pos];
}

- (BOOL)isCurrent:(unichar)character
{
  return [self hasMore] && [self current] == character;
}

- (BOOL)isNext:(unichar)character
{
  return _pos + 1 < _query.length && [_query characterAtIndex:_pos + 1] == character;
}

- (BOOL)fail
{
  // Failures past the end of the query are reported at its last character
  _failureIndex = MIN(_pos, _query.length - 1);
  return NO;
}

- (BOOL)consumeDescendantMarker
{
  NSUInteger markerLength = DESCENDANT_MARKER.length;
  if (_pos + markerLength > _query.length
      || NSOrderedSame != [_query compare:DESCENDANT_MARKER options:NSLiteralSearch range:NSMakeRange(_pos, markerLength)]) {
    return NO;
  }
  _pos += markerLength;
  return YES;
}

- (BOOL)scanTypeIntoStep:(FBRawStep *)step
{
  NSCharacterSet *letters = NSCharacterSet.letterCharacterSet;
  if ([self isCurrent:'*']) {
    if ([self isNext:'*']) {
      // Only the complete descendant marker may start with two stars
      ++_pos;
      return [self fail];
    }
    ++_pos;
    step.className = nil;
  } else if ([self hasMore] && [letters characterIsMember:[self current]]) {
    NSUInteger start = _pos;
    while ([self hasMore] && [letters characterIsMember:[self current]]) {
      ++_pos;
    }
    step.className = [_query substringWithRange:NSMakeRange(start, _pos - start)];
  } else {
    return [self fail];
  }
  if ([self hasMore] && ![self isCurrent:'/'] && ![self isCurrent:'[']) {
    return [self fail];
  }
  return YES;
}

- (BOOL)scanPredicateWithMarker:(unichar)marker intoStep:(FBRawStep *)step
{
  _pos += 2; // '[' and the marker
  NSMutableString *text = [NSMutableString string];
  NSUInteger chunkStart = _pos;
  while (YES) {
    if (![self hasMore]) {
      return [self fail];
    }
    if ([self current] != marker) {
      ++_pos;
      continue;
    }
    // A doubled marker stands for the marker itself
    BOOL isEscaped = [self isNext:marker];
    [text appendString:[_query substringWithRange:NSMakeRange(chunkStart, _pos - chunkStart + (isEscaped ? 1 : 0))]];
    if (!isEscaped) {
      ++_pos;
      break;
    }
    _pos += 2;
    chunkStart = _pos;
  }
  if (0 == text.length || ![self isCurrent:']']) {
    return [self fail];
  }
  ++_pos;
  FBRawGroup *group = [FBRawGroup new];
  group.kind = '`' == marker ? FBRawGroupKindSelfPredicate : FBRawGroupKindDescendantPredicate;
  group.text = text.copy;
  [step.groups addObject:group];
  return YES;
}

- (BOOL)scanPositionIntoStep:(FBRawStep *)step
{
  ++_pos; // '['
  NSUInteger start = _pos;
  while ([self hasMore] && FBIsPositionCharacter([self current])) {
    ++_pos;
  }
  NSUInteger end = _pos;
  if (![self isCurrent:']']) {
    return [self fail];
  }
  ++_pos;
  FBRawGroup *group = [FBRawGroup new];
  group.kind = FBRawGroupKindPosition;
  group.text = [_query substringWithRange:NSMakeRange(start, end - start)];
  [step.groups addObject:group];
  return YES;
}

- (BOOL)scanGroupIntoStep:(FBRawStep *)step
{
  BOOL allowsPosition = FBClassChainAxisParent != step.axis;
  if ([self isNext:'`']) {
    return [self scanPredicateWithMarker:'`' intoStep:step];
  }
  if ([self isNext:'$']) {
    return [self scanPredicateWithMarker:'$' intoStep:step];
  }
  if (allowsPosition && _pos + 1 < _query.length && FBIsPositionCharacter([_query characterAtIndex:_pos + 1])) {
    return [self scanPositionIntoStep:step];
  }
  ++_pos;
  return [self fail];
}

// The axis marker comes first in a step. Axes are relative to the previous element,
// so they cannot follow the descendant marker.
- (BOOL)scanAxisIntoStep:(FBRawStep *)step afterDescendantMarker:(BOOL)isAfterMarker
{
  if (![self hasMore]) {
    return YES;
  }
  FBClassChainAxis axis;
  switch ([self current]) {
    case '.':
      axis = FBClassChainAxisParent;
      break;
    case '^':
      axis = FBClassChainAxisAncestor;
      break;
    case '>':
      axis = FBClassChainAxisFollowingSibling;
      break;
    case '<':
      axis = FBClassChainAxisPrecedingSibling;
      break;
    case '~':
      axis = FBClassChainAxisSibling;
      break;
    default:
      return YES;
  }
  if (isAfterMarker || (FBClassChainAxisParent == axis && ![self isNext:'.'])) {
    return [self fail];
  }
  step.axis = axis;
  _pos += FBClassChainAxisParent == axis ? 2 : 1;
  return YES;
}

- (nullable NSArray<FBRawStep *> *)scan
{
  NSMutableArray<FBRawStep *> *steps = [NSMutableArray array];
  BOOL isDescendant = [self consumeDescendantMarker];
  while (YES) {
    FBRawStep *step = [FBRawStep new];
    step.axis = isDescendant ? FBClassChainAxisDescendant : FBClassChainAxisChild;
    while ([self consumeDescendantMarker]) {
      step.hasDuplicatedMarker = YES;
    }
    if (![self scanAxisIntoStep:step afterDescendantMarker:isDescendant]) {
      return nil;
    }
    if (FBClassChainAxisParent == step.axis) {
      // The parent has no type, only the end of the step may follow
      if ([self hasMore] && ![self isCurrent:'/'] && ![self isCurrent:'[']) {
        [self fail];
        return nil;
      }
    } else if (![self scanTypeIntoStep:step]) {
      return nil;
    }
    while ([self isCurrent:'[']) {
      if (![self scanGroupIntoStep:step]) {
        return nil;
      }
    }
    [steps addObject:step];
    if (![self hasMore]) {
      return steps.copy;
    }
    if (![self isCurrent:'/']) {
      [self fail];
      return nil;
    }
    ++_pos;
    isDescendant = [self consumeDescendantMarker];
  }
}

@end


@implementation FBClassChainItem

- (instancetype)initWithType:(XCUIElementType)type position:(NSNumber *)position predicates:(NSArray<FBAbstractPredicateItem *> *)predicates isDescendant:(BOOL)isDescendant
{
  return [self initWithType:type
                   position:position
                 predicates:predicates
                       axis:isDescendant ? FBClassChainAxisDescendant : FBClassChainAxisChild];
}

- (instancetype)initWithType:(XCUIElementType)type position:(NSNumber *)position predicates:(NSArray<FBAbstractPredicateItem *> *)predicates axis:(FBClassChainAxis)axis
{
  self = [super init];
  if (self) {
    _type = type;
    _position = position;
    _predicates = predicates;
    _axis = axis;
  }
  return self;
}

- (BOOL)isDescendant
{
  return FBClassChainAxisDescendant == self.axis;
}

@end


@implementation FBClassChain

- (instancetype)initWithElements:(NSArray<FBClassChainItem *> *)elements
{
  self = [super init];
  if (self) {
    _elements = elements;
  }
  return self;
}

@end


@implementation FBClassChainQueryParser

// A non-zero int written as an optional minus followed by ASCII digits, nil if it is something else
+ (nullable NSNumber *)positionWithString:(NSString *)string
{
  NSUInteger digitsStart = [string hasPrefix:@"-"] ? 1 : 0;
  if (string.length == digitsStart) {
    return nil;
  }
  for (NSUInteger i = digitsStart; i < string.length; ++i) {
    unichar character = [string characterAtIndex:i];
    if (character < '0' || character > '9') {
      return nil;
    }
  }
  errno = 0;
  long long value = strtoll(string.UTF8String, NULL, 10);
  if (ERANGE == errno || 0 == value || value < -INT_MAX || value > INT_MAX) {
    return nil;
  }
  return @(value);
}

+ (NSError *)tokenizationErrorWithIndex:(NSUInteger)index originalQuery:(NSString *)originalQuery
{
  NSString *description = [NSString stringWithFormat:@"Cannot parse class chain query '%@'. Unexpected character detected at position %@:\n%@ <----", originalQuery, @(index + 1), [originalQuery substringToIndex:index + 1]];
  return [[FBErrorBuilder.builder withDescription:description] build];
}

+ (NSError *)compilationErrorWithQuery:(NSString *)originalQuery description:(NSString *)description
{
  NSString *fullDescription = [NSString stringWithFormat:@"Cannot parse class chain query '%@'. %@", originalQuery, description];
  return [[FBErrorBuilder.builder withDescription:fullDescription] build];
}

// Steps are resolved in the order they are written, so the first problem wins: bad names and
// positions are errors, an invalid predicate raises an exception.
+ (nullable FBClassChain *)compiledQueryWithRawSteps:(NSArray<FBRawStep *> *)rawSteps
                                       originalQuery:(NSString *)originalQuery
                                               error:(NSError **)error
{
  NSMutableArray<FBClassChainItem *> *result = [NSMutableArray arrayWithCapacity:rawSteps.count];
  for (FBRawStep *rawStep in rawSteps) {
    if (rawStep.hasDuplicatedMarker) {
      if (error) {
        NSString *description = [NSString stringWithFormat:@"Unexpected token '%@'. Descendant markers cannot be duplicated.", DESCENDANT_MARKER];
        *error = [self.class compilationErrorWithQuery:originalQuery description:description];
      }
      return nil;
    }
    XCUIElementType type = XCUIElementTypeAny;
    if (nil != rawStep.className) {
      @try {
        type = [FBElementTypeTransformer elementTypeWithTypeName:rawStep.className];
      } @catch (NSException *e) {
        if ([e.name isEqualToString:FBInvalidArgumentException]) {
          if (error) {
            NSString *description = [NSString stringWithFormat:@"'%@' class name is unknown to WDA", rawStep.className];
            *error = [self.class compilationErrorWithQuery:originalQuery description:description];
          }
          return nil;
        }
        @throw e;
      }
    }
    NSNumber *position = nil;
    NSMutableArray<FBAbstractPredicateItem *> *predicates = [NSMutableArray array];
    for (FBRawGroup *group in rawStep.groups) {
      if (FBRawGroupKindPosition == group.kind) {
        if (nil != position) {
          if (error) {
            NSString *description = [NSString stringWithFormat:@"Position value '%@' is expected to be set only once.", group.text];
            *error = [self.class compilationErrorWithQuery:originalQuery description:description];
          }
          return nil;
        }
        NSNumber *value = [self.class positionWithString:group.text];
        if (nil == value) {
          if (error) {
            NSString *description = [NSString stringWithFormat:@"Position value '%@' is expected to be a valid integer number not equal to zero.", group.text];
            *error = [self.class compilationErrorWithQuery:originalQuery description:description];
          }
          return nil;
        }
        position = value;
      } else {
        if (nil != position) {
          if (error) {
            NSString *description = [NSString stringWithFormat:@"Predicate value '%@' must be set before position value.", group.text];
            *error = [self.class compilationErrorWithQuery:originalQuery description:description];
          }
          return nil;
        }
        NSPredicate *rawPredicate = nil;
        @try {
          rawPredicate = [NSPredicate predicateWithFormat:group.text argumentArray:@[]];
        } @catch (NSException *e) {
          // Foundation raises different exception names depending on the failure and OS version
          @throw [NSException exceptionWithName:NSInvalidArgumentException reason:e.reason userInfo:e.userInfo];
        }
        NSPredicate *value = [NSPredicate fb_formatSearchPredicate:rawPredicate];
        [predicates addObject:FBRawGroupKindSelfPredicate == group.kind
         ? [[FBSelfPredicateItem alloc] initWithValue:value]
         : [[FBDescendantPredicateItem alloc] initWithValue:value]];
      }
    }
    [result addObject:[[FBClassChainItem alloc] initWithType:type
                                                    position:position
                                                  predicates:predicates.copy
                                                        axis:rawStep.axis]];
  }
  return [[FBClassChain alloc] initWithElements:result.copy];
}

+ (FBClassChain *)parseQuery:(NSString*)classChainQuery error:(NSError **)error
{
  if (0 == classChainQuery.length) {
    if (error) {
      *error = [self.class compilationErrorWithQuery:classChainQuery ?: @"" description:@"The query must not be empty."];
    }
    return nil;
  }
  FBClassChainScanner *scanner = [[FBClassChainScanner alloc] initWithQuery:classChainQuery];
  NSArray<FBRawStep *> *rawSteps = [scanner scan];
  if (nil == rawSteps) {
    if (error) {
      *error = [self.class tokenizationErrorWithIndex:scanner.failureIndex originalQuery:classChainQuery];
    }
    return nil;
  }
  return [self.class compiledQueryWithRawSteps:rawSteps originalQuery:classChainQuery error:error];
}

@end


@implementation FBAbstractPredicateItem

- (instancetype)initWithValue:(NSPredicate *)value
{
  self = [super init];
  if (self) {
    _value = value;
  }
  return self;
}

@end

@implementation FBSelfPredicateItem

@end

@implementation FBDescendantPredicateItem

@end
