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
#import "FBSession.h"
#import "FBTestMacros.h"
#import "XCUIApplication+AMHelpers.h"

@interface AMSessionTests : AMIntegrationTestCase
@property (nonatomic) FBSession *session;
@end


static NSString *const SETTINGS_BUNDLE_ID = @"com.apple.systempreferences";

@implementation AMSessionTests

- (void)setUp
{
  [super setUp];
  [self launchApplication];
  self.session = [FBSession initWithApplication:self.testedApplication];
}

- (void)tearDown
{
  [self.session kill];
  [super tearDown];
}

- (void)testSettingsAppCanBeOpenedInScopeOfTheCurrentSession
{
  [self.session launchApplicationWithBundleId:SETTINGS_BUNDLE_ID
                                    arguments:nil
                                  environment:nil];
  XCTAssertEqualObjects(SETTINGS_BUNDLE_ID, self.session.currentApplication.am_bundleID);
  XCTAssertEqual([self.session applicationStateWithBundleId:SETTINGS_BUNDLE_ID],
                 XCUIApplicationStateRunningForeground);
  [self.session activateApplicationWithBundleId:self.testedApplication.am_bundleID];
  XCTAssertEqualObjects(self.testedApplication.am_bundleID, self.session.currentApplication.am_bundleID);
  XCTAssertEqual([self.session applicationStateWithBundleId:self.testedApplication.am_bundleID],
                 XCUIApplicationStateRunningForeground);
}

- (void)testSettingsAppCanBeReopenedInScopeOfTheCurrentSession
{
  [self.session launchApplicationWithBundleId:SETTINGS_BUNDLE_ID
                                    arguments:nil
                                  environment:nil];
  FBAssertWaitTillBecomesTrue([SETTINGS_BUNDLE_ID isEqualToString:self.session.currentApplication.am_bundleID]);
  XCTAssertTrue([self.session terminateApplicationWithBundleId:SETTINGS_BUNDLE_ID]);
  XCUIApplication *app = self.session.currentApplication;
  FBAssertWaitTillBecomesTrue([FINDER_BUNDLE_ID isEqualToString:app.am_bundleID]);
  [self.session launchApplicationWithBundleId:SETTINGS_BUNDLE_ID
                                    arguments:nil
                                  environment:nil];
  XCTAssertEqualObjects(SETTINGS_BUNDLE_ID, self.session.currentApplication.am_bundleID);
}

- (void)testMainAppCanBeReactivatedInScopeOfTheCurrentSession
{
  [self.session launchApplicationWithBundleId:SETTINGS_BUNDLE_ID
                                    arguments:nil
                                  environment:nil];
  XCTAssertEqualObjects(SETTINGS_BUNDLE_ID, self.session.currentApplication.am_bundleID);
  [self.session activateApplicationWithBundleId:self.testedApplication.am_bundleID];
  XCTAssertEqualObjects(self.testedApplication.am_bundleID, self.session.currentApplication.am_bundleID);
}

- (void)testMainAppCanBeRestartedInScopeOfTheCurrentSession
{
  NSString *testedAppBundleId = self.testedApplication.am_bundleID;
  XCTAssertTrue([self.session terminateApplicationWithBundleId:testedAppBundleId]);
  XCTAssertEqualObjects(FINDER_BUNDLE_ID, self.session.currentApplication.am_bundleID);
  [self.session launchApplicationWithBundleId:testedAppBundleId
                                    arguments:nil
                                  environment:nil];
  XCTAssertEqualObjects(testedAppBundleId, self.session.currentApplication.am_bundleID);
}

@end
