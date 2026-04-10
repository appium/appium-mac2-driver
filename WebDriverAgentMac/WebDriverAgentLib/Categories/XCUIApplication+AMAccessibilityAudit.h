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

NS_ASSUME_NONNULL_BEGIN

@interface XCUIApplication (AMAccessibilityAudit)

/**
 Wrapper around XCTest's -performAccessibilityAuditWithAuditTypes:issueHandler:error:.

 @param auditTypeNames Names from https://developer.apple.com/documentation/xcuiautomation/xcuiaccessibilityaudittype?language=objc
 Pass nil or an empty array to use XCUIAccessibilityAuditTypeAll.
 @param error Populated when the API is unavailable or the audit fails.
 @return An array of issue dictionaries, or nil on failure.
 @throws NSException with name FBInvalidArgumentException if an audit type name is unknown.
 */
- (nullable NSArray<NSDictionary<NSString *, id> *> *)am_performAccessibilityAuditWithAuditTypeNames:
    (nullable NSArray<NSString *> *)auditTypeNames
                                                                                              error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
