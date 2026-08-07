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

#import "FBConfiguration.h"
#import "FBLogger.h"
#import "XCUIElementQuery+AMHelpers.h"

static NSString *const AM_DOM_IDENTIFIER_ATTRIBUTE = @"AXDOMIdentifier";

/**
 Creates an AXUIElementRef from an accessibility element's remote token. This entry
 point is not exported in the public link stubs, so it is resolved dynamically. The
 underscore-prefixed name is the one actually present in the framework.
 */
typedef AXUIElementRef _Nullable (*AMCreateWithRemoteTokenFn)(CFDataRef);

static AMCreateWithRemoteTokenFn AMRemoteTokenFn(void)
{
  static AMCreateWithRemoteTokenFn fn = NULL;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    fn = (AMCreateWithRemoteTokenFn)(dlsym(RTLD_DEFAULT, "_AXUIElementCreateWithRemoteToken")
                                     ?: dlsym(RTLD_DEFAULT, "AXUIElementCreateWithRemoteToken"));
  });
  return fn;
}

/**
 Whether this process may use the public Accessibility API. XCUITest itself does not
 need it, so an untrusted runner keeps automating native content normally while every
 AXDOMIdentifier read fails with kAXErrorAPIDisabled. Guarding the read turns a failing
 syscall per element into a cached boolean. TCC trust is fixed at process start, so the
 answer cannot change under us.
 */
static BOOL AMIsAccessibilityTrusted(void)
{
  static BOOL isTrusted = NO;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    isTrusted = AXIsProcessTrusted();
    if (!isTrusted) {
      [FBLogger log:@"This process is not trusted for the Accessibility API, so WebKit DOM "
       @"identifiers cannot be resolved. Grant Accessibility permission to the "
       @"WebDriverAgentRunner app and restart it to enable useDomIdAsAccessibilityId."];
    }
  });
  return isTrusted;
}

@interface AMSnapshotUtils ()

/**
 Reads the non-standard AXDOMIdentifier attribute, where WebKit publishes a web
 node's HTML `id`. Returns nil for native elements, which report
 kAXErrorAttributeUnsupported for it.
 */
+ (nullable NSString *)domIdentifierWithSnapshot:(nullable id)snapshot;

@end

@implementation AMSnapshotUtils

+ (NSString *)hashWithSnapshot:(id)snapshot
{
  NSData *token = [[snapshot valueForKey:@"_accessibilityElement"] valueForKey:@"_token"];
  return [token base64EncodedStringWithOptions:0];
}

+ (nullable NSString *)wdIdentifierWithSnapshot:(nullable id<XCUIElementSnapshot>)snapshot
{
  NSString *identifier = snapshot.identifier;
  if (identifier.length > 0
      || !FBConfiguration.sharedConfiguration.useDomIdAsAccessibilityId) {
    return identifier;
  }
  return [self domIdentifierWithSnapshot:snapshot] ?: identifier;
}

+ (NSArray<XCUIElement *> *)elementsWithHashes:(NSSet<NSString *> *)hashes
                                   rootElement:(XCUIElement *)rootElement
                                  rootSnapshot:(id<XCUIElementSnapshot>)rootSnapshot
                         includeOnlyFirstMatch:(BOOL)firstMatch
{
  if (0 == hashes.count) {
    return @[];
  }

  NSMutableArray<XCUIElement *> *matchingElements = [NSMutableArray array];
  if ([hashes containsObject:[self hashWithSnapshot:rootSnapshot]]) {
    [matchingElements addObject:rootElement];
    if (firstMatch) {
      return matchingElements.copy;
    }
  }
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id snapshot, NSDictionary *bindings) {
    return [hashes containsObject:[self hashWithSnapshot:snapshot]];
  }];
  [matchingElements addObjectsFromArray:[[rootElement descendantsMatchingType:XCUIElementTypeAny]
                                         matchingPredicate:predicate].am_allMatches];
  return firstMatch && matchingElements.count > 0
    ? @[matchingElements.firstObject]
    : matchingElements.copy;
}

+ (nullable NSString *)domIdentifierWithSnapshot:(nullable id)snapshot
{
  if (nil == snapshot || !AMIsAccessibilityTrusted()) {
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
    AXError err = AXUIElementCopyAttributeValue(ref,
                                                (__bridge CFStringRef)AM_DOM_IDENTIFIER_ATTRIBUTE,
                                                &value);
    CFRelease(ref);
    if (kAXErrorSuccess != err || NULL == value) {
      return nil;
    }
    NSString *result = [(__bridge id)value isKindOfClass:NSString.class]
      ? [(__bridge NSString *)value copy]
      : nil;
    CFRelease(value);
    return result.length > 0 ? result : nil;
  } @catch (NSException *e) {
    // Only the private _accessibilityElement._token key path may throw here
    [FBLogger logFmt:@"Cannot retrieve the DOM identifier of a snapshot. Original error: %@", e.reason];
    return nil;
  }
}

@end
