/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCTestSuite+AMPatcher.h"

#import <objc/runtime.h>

static void (*originalHandleIssue)(id, SEL, id);

static void swizzledHandleIssue(id self, SEL _cmd, id issue)
{
  [issue setValue:@(NO) forKey:@"_shouldInterruptTest"];
  originalHandleIssue(self, _cmd, issue);
}

@implementation XCTestSuite (AMPatcher)

+ (void)load
{
  SEL originalHandleIssueSelector = NSSelectorFromString(@"handleIssue:");
  if (nil == originalHandleIssueSelector) return;
  Method originalHandleIssueMethod = class_getInstanceMethod(self.class, originalHandleIssueSelector);
  if (nil == originalHandleIssueMethod) return;
  originalHandleIssue = (void (*)(id, SEL, id)) method_setImplementation(originalHandleIssueMethod, (IMP)swizzledHandleIssue);
}

@end
