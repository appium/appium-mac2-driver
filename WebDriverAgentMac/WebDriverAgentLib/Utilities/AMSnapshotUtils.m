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

#import "AMSnapshotUtils.h"

#import <ApplicationServices/ApplicationServices.h>
#import <dlfcn.h>

// Private HIServices API: reconstitute an AXUIElementRef from an XCTest remote
// token. The symbol is absent from the link stubs and is exported with a leading
// underscore on current macOS, so resolve it dynamically rather than link it.
typedef AXUIElementRef (*AMCreateWithRemoteTokenFn)(CFDataRef);

static AMCreateWithRemoteTokenFn AMRemoteTokenFn(void)
{
  static AMCreateWithRemoteTokenFn fn = NULL;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    fn = (AMCreateWithRemoteTokenFn)dlsym(RTLD_DEFAULT, "_AXUIElementCreateWithRemoteToken");
    if (NULL == fn) {
      fn = (AMCreateWithRemoteTokenFn)dlsym(RTLD_DEFAULT, "AXUIElementCreateWithRemoteToken");
    }
  });
  return fn;
}

@implementation AMSnapshotUtils

+ (NSString *)hashWithSnapshot:(id)snapshot
{
  NSData *token = [[snapshot valueForKey:@"_accessibilityElement"] valueForKey:@"_token"];
  return [token base64EncodedStringWithOptions:0];
}

+ (BOOL)isAccessibilityTrusted
{
  return AXIsProcessTrusted();
}

+ (NSString *)domIdentifierWithSnapshot:(id)snapshot
{
  if (nil == snapshot || !AXIsProcessTrusted()) {
    return nil;
  }
  AMCreateWithRemoteTokenFn createRef = AMRemoteTokenFn();
  if (NULL == createRef) {
    return nil;
  }

  @try {
    NSData *token = [[snapshot valueForKey:@"_accessibilityElement"] valueForKey:@"_token"];
    if (![token isKindOfClass:NSData.class]) {
      return nil;
    }
    AXUIElementRef ref = createRef((__bridge CFDataRef)token);
    if (NULL == ref) {
      return nil;
    }
    CFTypeRef value = NULL;
    AXError err = AXUIElementCopyAttributeValue(ref, CFSTR("AXDOMIdentifier"), &value);
    CFRelease(ref);
    // Native (non-web) elements report kAXErrorAttributeUnsupported here.
    if (kAXErrorSuccess != err || NULL == value) {
      return nil;
    }
    NSString *result = [(__bridge id)value isKindOfClass:NSString.class]
      ? [(__bridge NSString *)value copy]
      : nil;
    CFRelease(value);
    return result.length > 0 ? result : nil;
  } @catch (NSException *e) {
    // The private KVC path (_accessibilityElement._token) is the only reason a
    // catch is needed; a throw here means that internal structure changed, which
    // is worth surfacing rather than swallowing silently.
    NSLog(@"AMSnapshotUtils: AXDOMIdentifier resolution failed: %@", e.reason);
    return nil;
  }
}

@end
