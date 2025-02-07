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

#import "AMScreenUtils.h"

@implementation AMScreenProperties

- (instancetype)initWithIdentifier:(long long)identifier
                            isMain:(BOOL)isMain
{
  if ((self = [super init])) {
    _identifier = identifier;
    _isMain = isMain;
  }
  return self;
}

@end

NSArray<AMScreenProperties *> *AMListScreens(void) {
  NSMutableArray<AMScreenProperties *> *result = [NSMutableArray new];
  for (XCUIScreen *screen in XCUIScreen.screens) {
    AMScreenProperties *info = [[AMScreenProperties alloc] initWithIdentifier:AMFetchScreenId(screen)
                                                                       isMain:AMIsMainScreen(screen)];
    [result addObject:info];
  }
  return result.copy;
}

long long AMFetchScreenId(XCUIScreen *screen) {
  return [[screen valueForKey:@"_displayID"] longLongValue];
}

BOOL AMIsMainScreen(XCUIScreen *screen) {
  return [[screen valueForKey:@"_isMainScreen"] boolValue];
}
