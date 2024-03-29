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

#import <WebDriverAgentLib/WebDriverAgentLib.h>

@interface UITestingUITests : FBFailureProofTestCase <FBWebServerDelegate>
@end

@implementation UITestingUITests

+ (void)setUp
{
  FBConfiguration.sharedConfiguration.attributeKeyPathAnalysis = NO;
  FBConfiguration.sharedConfiguration.automaticScreenshots =
    [NSProcessInfo.processInfo.environment[@"ENABLE_AUTOMATIC_SCREENSHOTS"] boolValue];
  FBConfiguration.sharedConfiguration.automaticScreenRecordings =
    [NSProcessInfo.processInfo.environment[@"ENABLE_AUTOMATIC_SCREEN_RECORDINGS"] boolValue];
  [super setUp];
}

- (void)setUp
{
  [super setUp];
}

/**
 Never ending test used to start WebDriverAgent
 */
- (void)testRunner
{
#ifdef MAC_OS_VERSION_11_3
  XCTExpectFailureWithOptions(@"Ignore all failures", XCTExpectedFailureOptions.nonStrictOptions);
#endif
  FBWebServer *webServer = [[FBWebServer alloc] init];
  webServer.delegate = self;
  [webServer startServing];
}

#pragma mark - FBWebServerDelegate

- (void)webServerDidRequestShutdown:(FBWebServer *)webServer
{
  [webServer stopServing];
}

@end
