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

#import "XCUIElementQuery+AMHelpers.h"

#import "FBSession.h"

@implementation XCUIElementQuery (AMHelpers)

- (XCUIElement *)am_firstMatch
{
  return self.am_allMatches.firstObject;
}

- (NSArray<XCUIElement *> *)am_allMatches
{
  return FBSession.activeSession.boundElementsByIndex
    ? self.allElementsBoundByIndex
    : self.allElementsBoundByAccessibilityElement;
}

- (id<XCUIElementSnapshot>)am_uniqueSnapshotWithError:(NSError **)error
{
  SEL selector = NSSelectorFromString(@"uniqueMatchingSnapshotWithError:");
  NSMethodSignature *signature = [self methodSignatureForSelector:selector];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  invocation.target = self;
  invocation.selector = selector;

  [invocation setArgument:&error atIndex:2]; // index 0 = self, 1 = _cmd, 2 = first real argument

  [invocation invoke];

  __unsafe_unretained id returnValue = nil;
  [invocation getReturnValue:&returnValue];
  return returnValue;
}

@end
