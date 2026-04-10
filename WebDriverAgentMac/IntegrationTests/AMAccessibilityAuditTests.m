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
#import "FBExceptions.h"
#import "XCUIApplication+AMAccessibilityAudit.h"

@interface AMAccessibilityAuditTests : AMIntegrationTestCase
@end

@implementation AMAccessibilityAuditTests

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
  });
}

- (void)testAccessibilityAuditWithAllType
{
  SEL selector = NSSelectorFromString(@"performAccessibilityAuditWithAuditTypes:issueHandler:error:");
  if (![self.testedApplication respondsToSelector:selector]) {
    XCTSkip(@"Accessibility audit API is unavailable in this XCTest runtime");
    return;
  }

  NSError *error;
  NSArray<NSDictionary<NSString *, id> *> *result = [self.testedApplication
      am_performAccessibilityAuditWithAuditTypeNames:nil
                                               error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(result);
}

- (void)testAccessibilityAuditWithUnknownTypeThrows
{
  XCTAssertThrowsSpecificNamed(
      [self.testedApplication am_performAccessibilityAuditWithAuditTypeNames:@[ @"UnknownAuditType" ]
                                                                        error:nil],
      NSException,
      FBInvalidArgumentException
  );
}

@end
