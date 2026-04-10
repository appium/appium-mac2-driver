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

#import "XCUIApplication+AMAccessibilityAudit.h"

#import "FBErrorBuilder.h"
#import "FBExceptions.h"

static id _Nullable AMAExtractIssueProperty(id issue, NSString *propertyName) {
  SEL selector = NSSelectorFromString(propertyName);
  NSMethodSignature *methodSignature = [issue methodSignatureForSelector:selector];
  if (nil == methodSignature) {
    return nil;
  }
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
  [invocation setSelector:selector];
  [invocation invokeWithTarget:issue];
  id __unsafe_unretained result;
  [invocation getReturnValue:&result];
  return result;
}

static NSDictionary<NSString *, NSNumber *> *AMAuditTypeNamesToValues(void) {
  static dispatch_once_t onceToken;
  static NSDictionary *result;
  dispatch_once(&onceToken, ^{
    // https://developer.apple.com/documentation/xcuiautomation/xcuiaccessibilityaudittype?language=objc
    result = @{
      @"XCUIAccessibilityAuditTypeAction": @(1UL << 32),
      @"XCUIAccessibilityAuditTypeAll": @(~0UL),
      @"XCUIAccessibilityAuditTypeContrast": @(1UL << 0),
      @"XCUIAccessibilityAuditTypeDynamicType": @(1UL << 16),
      @"XCUIAccessibilityAuditTypeElementDetection": @(1UL << 1),
      @"XCUIAccessibilityAuditTypeHitRegion": @(1UL << 2),
      @"XCUIAccessibilityAuditTypeParentChild": @(1UL << 33),
      @"XCUIAccessibilityAuditTypeSufficientElementDescription": @(1UL << 3),
      @"XCUIAccessibilityAuditTypeTextClipped": @(1UL << 17),
      @"XCUIAccessibilityAuditTypeTrait": @(1UL << 18),
    };
  });
  return result;
}

static NSDictionary<NSNumber *, NSString *> *AMAuditTypeValuesToNames(void) {
  static dispatch_once_t onceToken;
  static NSDictionary *result;
  dispatch_once(&onceToken, ^{
    NSMutableDictionary *inverted = [NSMutableDictionary new];
    [AMAuditTypeNamesToValues() enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSNumber *value, BOOL *stop) {
      inverted[value] = key;
    }];
    result = inverted.copy;
  });
  return result;
}

@implementation XCUIApplication (AMAccessibilityAudit)

- (nullable NSArray<NSDictionary<NSString *, id> *> *)am_performAccessibilityAuditWithAuditTypeNames:
    (nullable NSArray<NSString *> *)auditTypeNames
                                                                                              error:(NSError **)error
{
  SEL selector = NSSelectorFromString(@"performAccessibilityAuditWithAuditTypes:issueHandler:error:");
  if (![self respondsToSelector:selector]) {
    [[[FBErrorBuilder builder]
      withDescription:@"Accessibility audit is only supported since Xcode 15"]
     buildError:error];
    return nil;
  }

  NSMutableSet<NSString *> *typesSet = [NSMutableSet set];
  if (nil == auditTypeNames || 0 == auditTypeNames.count) {
    [typesSet addObject:@"XCUIAccessibilityAuditTypeAll"];
  } else {
    [typesSet addObjectsFromArray:auditTypeNames];
  }

  uint64_t auditTypesValue = 0;
  NSDictionary<NSString *, NSNumber *> *namesMap = AMAuditTypeNamesToValues();
  for (NSString *value in typesSet) {
    NSNumber *typeValue = namesMap[value];
    if (nil == typeValue) {
      NSString *reason = [NSString stringWithFormat:
                          @"Audit type value '%@' is not known. Only the following audit types are supported: %@",
                          value, namesMap.allKeys];
      @throw [NSException exceptionWithName:FBInvalidArgumentException reason:reason userInfo:@{}];
    }
    auditTypesValue |= [typeValue unsignedLongLongValue];
  }

  NSMutableArray<NSDictionary *> *resultArray = [NSMutableArray array];
  NSMethodSignature *methodSignature = [self methodSignatureForSelector:selector];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
  [invocation setSelector:selector];
  [invocation setArgument:&auditTypesValue atIndex:2];
  BOOL (^issueHandler)(id) = ^BOOL(id issue) {
    NSString *auditType = @"";
    NSNumber *auditTypeValue = [issue valueForKey:@"auditType"];
    if (nil != auditTypeValue) {
      auditType = AMAuditTypeValuesToNames()[auditTypeValue] ?: [auditTypeValue stringValue];
    }
    id extractedElement = AMAExtractIssueProperty(issue, @"element");
    [resultArray addObject:@{
      @"detailedDescription": AMAExtractIssueProperty(issue, @"detailedDescription") ?: @"",
      @"compactDescription": AMAExtractIssueProperty(issue, @"compactDescription") ?: @"",
      @"auditType": auditType,
      @"element": [extractedElement description] ?: @"",
      @"elementDescription": [extractedElement debugDescription] ?: @"",
    }];
    return YES;
  };
  [invocation setArgument:&issueHandler atIndex:3];
  [invocation setArgument:&error atIndex:4];
  [invocation invokeWithTarget:self];
  BOOL isSuccessful;
  [invocation getReturnValue:&isSuccessful];
  return isSuccessful ? resultArray.copy : nil;
}

@end
