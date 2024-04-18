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
#import "AMXCUIDeviceWrapper.h"


@interface AMDeviceTests : AMIntegrationTestCase
@end

@implementation AMDeviceTests

- (void)testDeepLinkCouldBeOpened
{
  if (!AMXCUIDeviceWrapper.sharedDevice.supportsOpenUrl) {
    return;
  }

  NSError *error;
  XCTAssertTrue([AMXCUIDeviceWrapper.sharedDevice openUrl:[NSURL URLWithString:@"https://apple.com"] 
                                                    error:&error]);
  XCTAssertNil(error);
}

@end
