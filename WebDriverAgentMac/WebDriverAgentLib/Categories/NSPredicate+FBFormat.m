/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "NSPredicate+FBFormat.h"

#import "NSExpression+FBFormat.h"
#import "XCUIElement+AMAttributes.h"

@implementation NSPredicate (FBFormat)

+ (instancetype)fb_predicateWithPredicate:(NSPredicate *)original comparisonModifier:(NSPredicate *(^)(NSComparisonPredicate *))comparisonModifier
{
  if ([original isKindOfClass:NSCompoundPredicate.class]) {
    NSCompoundPredicate *compPred = (NSCompoundPredicate *)original;
    NSMutableArray *predicates = [NSMutableArray array];
    for (NSPredicate *predicate in [compPred subpredicates]) {
      NSPredicate *newPredicate = [self.class fb_predicateWithPredicate:predicate comparisonModifier:comparisonModifier];
      if (nil != newPredicate) {
        [predicates addObject:newPredicate];
      }
    }
    return [[NSCompoundPredicate alloc] initWithType:compPred.compoundPredicateType
                                       subpredicates:predicates];
  }
  if ([original isKindOfClass:NSComparisonPredicate.class]) {
    return comparisonModifier((NSComparisonPredicate *)original);
  }
  return original;
}

/**
 Whether the given expression is a key path referencing one of the am_* predicate
 attributes (AM_IDENTIFIER_ATTRIBUTE_NAME and friends, see XCUIElement+AMAttributes),
 either directly (`amRect`) or through a nested key path into its resolved value
 (`amRect.x`).

 @return The referenced am_* attribute name, or nil if it isn't one
 */
+ (nullable NSString *)fb_amAttributeNameForExpression:(NSExpression *)expression
{
  if (NSKeyPathExpressionType != expression.expressionType) {
    return nil;
  }
  NSString *keyPath = expression.keyPath;
  NSUInteger dotPos = [keyPath rangeOfString:@"."].location;
  NSString *attributeName = NSNotFound == dotPos ? keyPath : [keyPath substringToIndex:dotPos];
  return [[XCUIElement am_predicateAttributeNames] containsObject:attributeName] ? attributeName : nil;
}

/**
 Rebuilds a comparison predicate that references an am_* attribute on one side into a
 block predicate that resolves that attribute directly off the snapshot node being
 matched and compares it with the same operator/options as the original. Block
 predicates are evaluated per-node by matchingPredicate:/containingPredicate: (this is
 how the accessibility id DOM fallback already resolves elements), unlike plain
 comparison predicates whose key path resolution WebKit content does not reliably
 observe. A nested key path into the attribute's resolved value (e.g. `amRect.x`) is
 resolved with a plain valueForKeyPath: lookup after the attribute value itself is
 resolved.

 @param cp the original comparison predicate, known to reference an am_* attribute
 @param amAttributeName the am_* attribute name referenced
 @param amAttributeOnLeft whether it is the left or the right expression
 @return an equivalent block-based predicate
 */
+ (NSPredicate *)fb_amAttributePredicateForComparison:(NSComparisonPredicate *)cp
                                       amAttributeName:(NSString *)amAttributeName
                                      amAttributeOnLeft:(BOOL)amAttributeOnLeft
{
  NSExpression *amAttributeExpression = amAttributeOnLeft ? cp.leftExpression : cp.rightExpression;
  NSExpression *otherExpression = amAttributeOnLeft ? cp.rightExpression : cp.leftExpression;
  NSString *amKeyPath = amAttributeExpression.keyPath;
  NSUInteger dotPos = [amKeyPath rangeOfString:@"."].location;
  NSString *amValueKeyPathSuffix = NSNotFound == dotPos ? nil : [amKeyPath substringFromIndex:(dotPos + 1)];
  NSComparisonPredicateModifier modifier = cp.comparisonPredicateModifier;
  NSPredicateOperatorType operatorType = cp.predicateOperatorType;
  NSComparisonPredicateOptions options = cp.options;
  return [NSPredicate predicateWithBlock:^BOOL(id snapshot, NSDictionary *bindings) {
    id amValue = [XCUIElement am_valueForPredicateAttributeName:amAttributeName target:snapshot];
    if (amValueKeyPathSuffix.length > 0) {
      amValue = [amValue valueForKeyPath:amValueKeyPathSuffix];
    }
    amValue = amValue ?: @"";
    NSMutableDictionary *context = bindings ? [bindings mutableCopy] : [NSMutableDictionary dictionary];
    id otherValue = [otherExpression expressionValueWithObject:snapshot context:context];
    NSExpression *amExpression = [NSExpression expressionForConstantValue:amValue];
    NSExpression *otherConstantExpression = [NSExpression expressionForConstantValue:otherValue];
    NSComparisonPredicate *rewritten = amAttributeOnLeft
      ? [NSComparisonPredicate predicateWithLeftExpression:amExpression
                                            rightExpression:otherConstantExpression
                                                   modifier:modifier
                                                       type:operatorType
                                                    options:options]
      : [NSComparisonPredicate predicateWithLeftExpression:otherConstantExpression
                                            rightExpression:amExpression
                                                   modifier:modifier
                                                       type:operatorType
                                                    options:options];
    return [rewritten evaluateWithObject:nil];
  }];
}

+ (instancetype)fb_formatSearchPredicate:(NSPredicate *)input
{
  return [self.class fb_predicateWithPredicate:input comparisonModifier:^NSPredicate *(NSComparisonPredicate *cp) {
    NSString *leftAmAttribute = [self.class fb_amAttributeNameForExpression:cp.leftExpression];
    NSString *rightAmAttribute = [self.class fb_amAttributeNameForExpression:cp.rightExpression];
    if (nil != leftAmAttribute || nil != rightAmAttribute) {
      return [self.class fb_amAttributePredicateForComparison:cp
                                                amAttributeName:leftAmAttribute ?: rightAmAttribute
                                              amAttributeOnLeft:nil != leftAmAttribute];
    }
    NSExpression *left = [NSExpression fb_wdExpressionWithExpression:[cp leftExpression]];
    NSExpression *right = [NSExpression fb_wdExpressionWithExpression:[cp rightExpression]];
    return [NSComparisonPredicate predicateWithLeftExpression:left
                                              rightExpression:right
                                                     modifier:cp.comparisonPredicateModifier
                                                         type:cp.predicateOperatorType
                                                      options:cp.options];
  }];
}

@end
