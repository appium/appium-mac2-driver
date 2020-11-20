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

#import "AMIntegrationTestCase.h"

#import "FBConfiguration.h"

@interface AMIntegrationTestCase ()
@property (nonatomic, strong) XCUIApplication *testedApplication;
@end

@implementation AMIntegrationTestCase

- (void)setUp
{
  [super setUp];
  FBConfiguration.sharedConfiguration.attributeKeyPathAnalysis = NO;
  FBConfiguration.sharedConfiguration.automaticScreenshots = NO;
  self.continueAfterFailure = NO;
  self.testedApplication = [XCUIApplication new];
}

- (void)tearDown
{
  [super tearDown];
}

- (void)launchApplication
{
  [self.testedApplication launch];
}

- (void)switchToButtonsTab
{
  [self.testedApplication.radioButtons[@"Buttons"].firstMatch click];
}

- (void)switchToEditsTab
{
  [self.testedApplication.radioButtons[@"Edits"].firstMatch click];
}

@end
