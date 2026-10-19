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

#import "AMXCTAccessibility.h"

#import <objc/message.h>

#import "FBLogger.h"

static NSString *const AM_ACCESSIBILITY_INTERFACE_KEY = @"accessibilityInterface";

typedef id (*AMFetchAttributesFn)(id, SEL, id, id, NSError **);
typedef BOOL (*AMPerformActionFn)(id, SEL, id, id, id, NSError **);

@implementation AMXCTAccessibility

+ (nullable id)accessibilityInterface
{
  @try {
    id interface = [XCUIDevice.sharedDevice valueForKey:AM_ACCESSIBILITY_INTERFACE_KEY];
    return [interface respondsToSelector:NSSelectorFromString(@"attributesForElement:attributes:error:")]
      && [interface respondsToSelector:NSSelectorFromString(@"performAction:onElement:value:error:")]
      ? interface
      : nil;
  } @catch (NSException *e) {
    return nil;
  }
}

+ (BOOL)isAvailable
{
  return nil != [self accessibilityInterface]
    && nil != NSClassFromString(@"XCUIAccessibilityAction");
}

+ (nullable id)accessibilityElementWithSnapshot:(nullable id)snapshot
{
  if (nil == snapshot) {
    return nil;
  }
  @try {
    return [snapshot valueForKey:@"_accessibilityElement"];
  } @catch (NSException *e) {
    return nil;
  }
}

+ (nullable id)accessibilityElementWithApplication:(XCUIApplication *)application
{
  @try {
    return [application valueForKey:@"accessibilityElement"];
  } @catch (NSException *e) {
    return nil;
  }
}

+ (nullable NSDictionary<NSString *, id> *)attributes:(NSArray<NSString *> *)names ofElement:(id)element
{
  id interface = [self accessibilityInterface];
  if (nil == interface || nil == element) {
    return nil;
  }
  @try {
    NSError *error = nil;
    id result = ((AMFetchAttributesFn)objc_msgSend)(interface,
                                                    NSSelectorFromString(@"attributesForElement:attributes:error:"),
                                                    element, names, &error);
    return [result isKindOfClass:NSDictionary.class] ? result : nil;
  } @catch (NSException *e) {
    [FBLogger logFmt:@"Cannot fetch the accessibility attributes %@. Original error: %@", names, e.reason];
    return nil;
  }
}

+ (BOOL)pressElement:(id)element error:(NSError **)error
{
  id interface = [self accessibilityInterface];
  Class actionClass = NSClassFromString(@"XCUIAccessibilityAction");
  if (nil == interface || nil == actionClass || nil == element) {
    return NO;
  }
  @try {
    id action = ((id (*)(id, SEL, id))objc_msgSend)([actionClass alloc],
                                                     NSSelectorFromString(@"initWithActionName:"),
                                                     @"AXPress");
    return ((AMPerformActionFn)objc_msgSend)(interface,
                                             NSSelectorFromString(@"performAction:onElement:value:error:"),
                                             action, element, nil, error);
  } @catch (NSException *e) {
    [FBLogger logFmt:@"Cannot press the accessibility element. Original error: %@", e.reason];
    return NO;
  }
}

@end
