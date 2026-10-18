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

#import "AMWindowUtils.h"

#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>

#import "AMGeometryUtils.h"
#import "AMScreenUtils.h"
#import "AMSnapshotUtils.h"
#import "AMXCTAccessibility.h"
#import "XCUIApplication+AMHelpers.h"
#import "XCUIElementQuery+AMHelpers.h"

NSString *const AMWindowErrorDomain = @"AMWindowErrorDomain";
NSString *const AMWindowStateNormal = @"normal";
NSString *const AMWindowStateMinimized = @"minimized";
NSString *const AMWindowStateMaximized = @"maximized";
NSString *const AMWindowStateFullscreen = @"fullscreen";

static const NSTimeInterval AM_WINDOW_STATE_TIMEOUT = 3.0;
static NSString *const AM_GEOMETRY_ACCESS_DENIED_MESSAGE = @"Changing the window geometry requires the Accessibility API. "
  @"Grant the Accessibility permission to the WebDriverAgentRunner app and restart it";
static NSString *const AM_MINIMIZE_BUTTON_ID = @"_XCUI:MinimizeWindow";
static NSString *const AM_FULLSCREEN_BUTTON_ID = @"_XCUI:FullScreenWindow";
static NSString *const AM_DOCK_BUNDLE_ID = @"com.apple.dock";
static NSString *const AM_MINIMIZED_DOCK_ITEM_SUBROLE = @"AXMinimizedWindowDockItem";

static NSString *const AM_KEY_TITLE = @"title";
static NSString *const AM_KEY_RECT = @"rect";
static NSString *const AM_KEY_MAIN = @"main";
static NSString *const AM_KEY_FOCUSED = @"focused";
static NSString *const AM_KEY_MINIMIZED = @"minimized";
static NSString *const AM_KEY_FULLSCREEN = @"fullscreen";

static BOOL gUsesUnprivilegedRoutes = YES;

static void AMAssignError(NSError **error, NSError *value)
{
  if (NULL != error) {
    *error = value;
  }
}

// The display with the biggest intersection with the rect. Falls back to the main one
static AMScreenProperties *_Nullable AMDisplayForRect(CGRect rect)
{
  AMScreenProperties *result = nil;
  CGFloat maxArea = 0;
  for (AMScreenProperties *screen in AMListScreens()) {
    CGRect intersection = CGRectIntersection(screen.bounds, rect);
    CGFloat area = CGRectIsNull(intersection) ? 0 : intersection.size.width * intersection.size.height;
    if (area > maxArea) {
      maxArea = area;
      result = screen;
    }
  }
  if (nil == result) {
    for (AMScreenProperties *screen in AMListScreens()) {
      if (screen.isMain) {
        return screen;
      }
    }
  }
  return result;
}

static id _Nullable AMCopyAXAttribute(AXUIElementRef element, CFStringRef name)
{
  CFTypeRef value = NULL;
  if (kAXErrorSuccess != AXUIElementCopyAttributeValue(element, name, &value) || NULL == value) {
    return nil;
  }
  return CFBridgingRelease(value);
}

static NSNumber *_Nullable AMAXBool(AXUIElementRef element, CFStringRef name)
{
  id value = AMCopyAXAttribute(element, name);
  return [value isKindOfClass:NSNumber.class] ? value : nil;
}

static BOOL AMAXSetBool(AXUIElementRef element, CFStringRef name, BOOL value)
{
  return kAXErrorSuccess == AXUIElementSetAttributeValue(element, name, value ? kCFBooleanTrue : kCFBooleanFalse);
}

static BOOL AMAXIsSettable(AXUIElementRef element, CFStringRef name)
{
  Boolean settable = false;
  return kAXErrorSuccess == AXUIElementIsAttributeSettable(element, name, &settable) && settable;
}

static BOOL AMAXSetGeometry(AXUIElementRef element, CFStringRef name, AXValueType type, const void *geometry)
{
  AXValueRef value = AXValueCreate(type, geometry);
  if (NULL == value) {
    return NO;
  }
  AXError err = AXUIElementSetAttributeValue(element, name, value);
  CFRelease(value);
  return kAXErrorSuccess == err;
}

static BOOL AMAXReadRect(AXUIElementRef element, CGRect *rect)
{
  CGPoint origin = CGPointZero;
  CGSize size = CGSizeZero;
  id position = AMCopyAXAttribute(element, kAXPositionAttribute);
  id dimensions = AMCopyAXAttribute(element, kAXSizeAttribute);
  if (nil == position || nil == dimensions
      || !AXValueGetValue((__bridge AXValueRef)position, kAXValueTypeCGPoint, &origin)
      || !AXValueGetValue((__bridge AXValueRef)dimensions, kAXValueTypeCGSize, &size)) {
    return NO;
  }
  *rect = CGRectMake(origin.x, origin.y, size.width, size.height);
  return YES;
}

static BOOL AMWaitUntil(BOOL (^condition)(void))
{
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:AM_WINDOW_STATE_TIMEOUT];
  while (!condition()) {
    if ([deadline timeIntervalSinceNow] <= 0) {
      return NO;
    }
    [NSThread sleepForTimeInterval:0.1];
  }
  return YES;
}

static CGPoint AMPointFromAXDict(NSDictionary *dict)
{
  return CGPointMake([dict[@"X"] doubleValue], [dict[@"Y"] doubleValue]);
}

static CGSize AMSizeFromAXDict(NSDictionary *dict)
{
  return CGSizeMake([dict[@"Width"] doubleValue], [dict[@"Height"] doubleValue]);
}

/**
 Identifies a window by its XCTest accessibility element. Minimized windows have no
 XCUIElement, because they are not a part of the element hierarchy.
 */
@interface AMWindowHandle : NSObject
@property (nonatomic, nullable) XCUIElement *element;
@property (nonatomic, nullable) id accessibilityElement;
@property (nonatomic, copy, nullable) NSString *fallbackTitle;
@property (nonatomic) CGRect fallbackFrame;

/** Takes the ownership of the AX element. Used if XCTest accessibility elements are not available */
- (void)adoptAXElement:(AXUIElementRef CF_RELEASES_ARGUMENT)ref;
/** The AX element is owned by the handle. NULL if the Accessibility permission is not granted */
- (nullable AXUIElementRef)axElement;
@end

@implementation AMWindowHandle {
  AXUIElementRef _axElement;
}

- (void)adoptAXElement:(AXUIElementRef CF_RELEASES_ARGUMENT)ref
{
  if (NULL != _axElement) {
    CFRelease(_axElement);
  }
  _axElement = ref;
}

- (nullable AXUIElementRef)axElement
{
  if (NULL == _axElement && nil != self.accessibilityElement) {
    _axElement = [AMSnapshotUtils createAXElementWithAccessibilityElement:self.accessibilityElement];
  }
  return _axElement;
}

- (void)dealloc
{
  if (NULL != _axElement) {
    CFRelease(_axElement);
  }
}

@end

/**
 Reads the window attributes (title, rect, main, focused, minimized, fullscreen). XCTest accessibility
 is used first, because it does not need the Accessibility permission. Returns nil if the window cannot be read.
 */
static NSDictionary<NSString *, id> *_Nullable AMReadWindow(AMWindowHandle *handle)
{
  NSMutableDictionary<NSString *, id> *result = [NSMutableDictionary dictionary];
  if (gUsesUnprivilegedRoutes && nil != handle.accessibilityElement) {
    NSDictionary *attrs = [AMXCTAccessibility attributes:@[@"AXTitle", @"AXPosition", @"AXSize", @"AXMinimized",
                                                           @"AXFullScreen", @"AXMain", @"AXFocused"]
                                               ofElement:handle.accessibilityElement];
    if (attrs.count > 0) {
      if ([attrs[@"AXTitle"] isKindOfClass:NSString.class]) {
        result[AM_KEY_TITLE] = attrs[@"AXTitle"];
      }
      if ([attrs[@"AXPosition"] isKindOfClass:NSDictionary.class] && [attrs[@"AXSize"] isKindOfClass:NSDictionary.class]) {
        CGPoint origin = AMPointFromAXDict(attrs[@"AXPosition"]);
        CGSize size = AMSizeFromAXDict(attrs[@"AXSize"]);
        result[AM_KEY_RECT] = [NSValue valueWithRect:CGRectMake(origin.x, origin.y, size.width, size.height)];
      }
      NSDictionary *keys = @{AM_KEY_MINIMIZED: @"AXMinimized", AM_KEY_FULLSCREEN: @"AXFullScreen",
                             AM_KEY_MAIN: @"AXMain", AM_KEY_FOCUSED: @"AXFocused"};
      for (NSString *key in keys) {
        if ([attrs[keys[key]] isKindOfClass:NSNumber.class]) {
          result[key] = attrs[keys[key]];
        }
      }
      return result.copy;
    }
  }
  AXUIElementRef ref = [handle axElement];
  if (NULL == ref) {
    return nil;
  }
  id title = AMCopyAXAttribute(ref, kAXTitleAttribute);
  if ([title isKindOfClass:NSString.class]) {
    result[AM_KEY_TITLE] = title;
  }
  CGRect rect;
  if (AMAXReadRect(ref, &rect)) {
    result[AM_KEY_RECT] = [NSValue valueWithRect:rect];
  }
  NSDictionary *keys = @{AM_KEY_MINIMIZED: (__bridge NSString *)kAXMinimizedAttribute, AM_KEY_FULLSCREEN: @"AXFullScreen",
                         AM_KEY_MAIN: (__bridge NSString *)kAXMainAttribute, AM_KEY_FOCUSED: (__bridge NSString *)kAXFocusedAttribute};
  for (NSString *key in keys) {
    NSNumber *value = AMAXBool(ref, (__bridge CFStringRef)keys[key]);
    if (nil != value) {
      result[key] = value;
    }
  }
  return result.copy;
}

static BOOL AMWindowFlag(AMWindowHandle *handle, NSString *key)
{
  return [AMReadWindow(handle)[key] boolValue];
}

static BOOL AMWaitForWindowFlag(AMWindowHandle *handle, NSString *key, BOOL expected)
{
  return AMWaitUntil(^BOOL{ return AMWindowFlag(handle, key) == expected; });
}

@implementation AMWindowUtils

+ (BOOL)usesUnprivilegedRoutes
{
  return gUsesUnprivilegedRoutes;
}

+ (void)setUsesUnprivilegedRoutes:(BOOL)value
{
  gUsesUnprivilegedRoutes = value;
}

+ (NSArray<XCUIElement *> *)windowsOfApplication:(XCUIApplication *)application
{
  return [application.windows am_allMatches];
}

+ (nullable AMWindowHandle *)handleWithWindow:(XCUIElement *)window
{
  id<XCUIElementSnapshot> snapshot = [window snapshotWithError:nil];
  if (nil == snapshot) {
    return nil;
  }
  AMWindowHandle *handle = [AMWindowHandle new];
  handle.element = window;
  handle.accessibilityElement = [AMXCTAccessibility accessibilityElementWithSnapshot:snapshot];
  handle.fallbackTitle = snapshot.title;
  handle.fallbackFrame = snapshot.frame;
  if (nil == handle.accessibilityElement) {
    // XCTest accessibility elements are not available, so AX has to be used
    [handle adoptAXElement:[AMSnapshotUtils createAXElementWithSnapshot:snapshot]];
  }
  return handle;
}

+ (nullable XCUIElement *)mainWindowOfApplication:(XCUIApplication *)application
{
  NSArray<XCUIElement *> *windows = [self windowsOfApplication:application];
  XCUIElement *focused = nil;
  for (XCUIElement *window in windows) {
    AMWindowHandle *handle = [self handleWithWindow:window];
    NSDictionary *attrs = nil == handle ? nil : AMReadWindow(handle);
    if (nil == attrs) {
      break;
    }
    if ([attrs[AM_KEY_MAIN] boolValue]) {
      return window;
    }
    if ([attrs[AM_KEY_FOCUSED] boolValue] && nil == focused) {
      focused = window;
    }
  }
  return focused ?: windows.firstObject;
}

+ (nullable NSDictionary<NSString *, id> *)infoForWindow:(XCUIElement *)window
{
  AMWindowHandle *handle = [self handleWithWindow:window];
  return nil == handle ? nil : [self infoForHandle:handle];
}

+ (NSDictionary<NSString *, id> *)infoForHandle:(AMWindowHandle *)handle
{
  NSDictionary *attrs = AMReadWindow(handle);
  NSString *title = attrs[AM_KEY_TITLE] ?: handle.fallbackTitle;
  CGRect frame = nil != attrs[AM_KEY_RECT] ? [attrs[AM_KEY_RECT] rectValue] : handle.fallbackFrame;
  NSNumber *null = (NSNumber *)NSNull.null;
  // Whether the window is movable/resizable can only be asked through the Accessibility API
  AXUIElementRef ref = [handle axElement];
  NSMutableDictionary<NSString *, id> *info = [NSMutableDictionary dictionaryWithDictionary:@{
    @"title": title ?: @"",
    @"isMain": attrs[AM_KEY_MAIN] ?: null,
    @"isFocused": attrs[AM_KEY_FOCUSED] ?: null,
    @"isMinimized": attrs[AM_KEY_MINIMIZED] ?: null,
    @"isFullscreen": attrs[AM_KEY_FULLSCREEN] ?: null,
    @"isMovable": NULL == ref ? null : @(AMAXIsSettable(ref, kAXPositionAttribute)),
    @"isResizable": NULL == ref ? null : @(AMAXIsSettable(ref, kAXSizeAttribute)),
    @"rect": AMCGRectToDict(frame),
  }];
  AMScreenProperties *display = AMDisplayForRect(frame);
  info[@"displayId"] = nil == display ? NSNull.null : @(display.identifier);
  return info.copy;
}

+ (nullable NSDictionary<NSString *, id> *)adjustWindow:(XCUIElement *)window
                                          inApplication:(XCUIApplication *)application
                                          withArguments:(NSDictionary<NSString *, id> *)arguments
                                                  error:(NSError **)error
{
  NSString *state = nil;
  NSDictionary<NSString *, NSNumber *> *rect = nil;
  AMScreenProperties *display = nil;
  if (![self parseArguments:arguments state:&state rect:&rect display:&display error:error]) {
    return nil;
  }
  id<XCUIElementSnapshot> snapshot = [window snapshotWithError:nil];
  if (nil == snapshot) {
    AMAssignError(error, [self windowErrorWithCode:AMWindowErrorNotFound
                                            format:@"The window is not available anymore. It might have been closed or minimized"]);
    return nil;
  }
  if (XCUIElementTypeWindow != snapshot.elementType) {
    AMAssignError(error, [self windowErrorWithCode:AMWindowErrorInvalidArgument format:@"The element is not a window"]);
    return nil;
  }
  AMWindowHandle *handle = [self handleWithWindow:window];
  return [self adjustHandle:handle application:application state:state rect:rect display:display error:error];
}

+ (nullable NSDictionary<NSString *, id> *)adjustMinimizedWindowOfApplication:(XCUIApplication *)application
                                                                withArguments:(NSDictionary<NSString *, id> *)arguments
                                                                        error:(NSError **)error
{
  NSString *state = nil;
  NSDictionary<NSString *, NSNumber *> *rect = nil;
  AMScreenProperties *display = nil;
  if (![self parseArguments:arguments state:&state rect:&rect display:&display error:error]) {
    return nil;
  }
  AMWindowHandle *handle = [self minimizedWindowsOfApplication:application].firstObject;
  if (nil == handle) {
    AMAssignError(error, [self windowErrorWithCode:AMWindowErrorNotFound format:@"The application has no minimized windows"]);
    return nil;
  }
  return [self adjustHandle:handle application:application state:state rect:rect display:display error:error];
}

+ (NSUInteger)minimizedWindowsCountOfApplication:(XCUIApplication *)application
{
  return [self minimizedWindowsOfApplication:application].count;
}

#pragma mark - Private

+ (NSError *)windowErrorWithCode:(AMWindowErrorCode)code format:(NSString *)format, ... NS_FORMAT_FUNCTION(2,3)
{
  va_list args;
  va_start(args, format);
  NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);
  return [NSError errorWithDomain:AMWindowErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: message}];
}

// Validates the arguments and extracts the geometry, the state and the target display
+ (BOOL)parseArguments:(NSDictionary<NSString *, id> *)arguments
                 state:(NSString * _Nullable *)outState
                  rect:(NSDictionary<NSString *, NSNumber *> * _Nullable *)outRect
               display:(AMScreenProperties * _Nullable *)outDisplay
                 error:(NSError **)error
{
  NSMutableDictionary<NSString *, NSNumber *> *rect = [NSMutableDictionary dictionary];
  for (NSString *key in @[@"x", @"y", @"width", @"height"]) {
    id value = arguments[key];
    if (nil == value || [value isKindOfClass:NSNull.class]) {
      continue;
    }
    if (![value isKindOfClass:NSNumber.class]
        || (([key hasPrefix:@"w"] || [key hasPrefix:@"h"]) && [value doubleValue] <= 0)) {
      AMAssignError(error, [self windowErrorWithCode:AMWindowErrorInvalidArgument
                                  format:@"'%@' must be a valid number, got '%@'", key, value]);
      return NO;
    }
    rect[key] = value;
  }
  id rawDisplayId = arguments[@"displayId"];
  if (nil != rawDisplayId && ![rawDisplayId isKindOfClass:NSNull.class] && ![rawDisplayId isKindOfClass:NSNumber.class]) {
    AMAssignError(error, [self windowErrorWithCode:AMWindowErrorInvalidArgument
                                format:@"'displayId' must be a number, got '%@'", rawDisplayId]);
    return NO;
  }
  NSNumber *displayId = [rawDisplayId isKindOfClass:NSNumber.class] ? rawDisplayId : nil;
  NSString *state = arguments[@"state"];
  if ([state isKindOfClass:NSNull.class]) {
    state = nil;
  }
  NSArray<NSString *> *states = @[AMWindowStateNormal, AMWindowStateMinimized, AMWindowStateMaximized, AMWindowStateFullscreen];
  if (nil != state && ![states containsObject:state]) {
    AMAssignError(error, [self windowErrorWithCode:AMWindowErrorInvalidArgument
                                format:@"'state' must be one of: %@. Got '%@'", [states componentsJoinedByString:@", "], state]);
    return NO;
  }
  if (nil == state && 0 == rect.count && nil == displayId) {
    AMAssignError(error, [self windowErrorWithCode:AMWindowErrorInvalidArgument
                                format:@"At least one of 'state', 'x', 'y', 'width', 'height' or 'displayId' must be provided"]);
    return NO;
  }
  BOOL isGeometryFree = [state isEqualToString:AMWindowStateMinimized] || [state isEqualToString:AMWindowStateFullscreen];
  if ((isGeometryFree && (rect.count > 0 || nil != displayId))
      || ([state isEqualToString:AMWindowStateMaximized] && rect.count > 0)) {
    AMAssignError(error, [self windowErrorWithCode:AMWindowErrorInvalidArgument
                                format:@"The '%@' state cannot be combined with the explicit window geometry", state]);
    return NO;
  }
  AMScreenProperties *targetDisplay = nil;
  if (nil != displayId) {
    NSMutableArray<NSNumber *> *available = [NSMutableArray array];
    for (AMScreenProperties *screen in AMListScreens()) {
      [available addObject:@(screen.identifier)];
      if (screen.identifier == displayId.longLongValue) {
        targetDisplay = screen;
      }
    }
    if (nil == targetDisplay) {
      AMAssignError(error, [self windowErrorWithCode:AMWindowErrorInvalidArgument
                                  format:@"The display '%@' is unknown. Available identifiers: %@",
                displayId, [available componentsJoinedByString:@","]]);
      return NO;
    }
  }
  *outState = state;
  *outRect = rect.copy;
  *outDisplay = targetDisplay;
  return YES;
}

// Minimized windows are not in the XCUIElement hierarchy, but the accessibility application keeps them
+ (NSArray<AMWindowHandle *> *)minimizedWindowsOfApplication:(XCUIApplication *)application
{
  NSMutableArray<AMWindowHandle *> *result = [NSMutableArray array];
  if (gUsesUnprivilegedRoutes) {
    id appElement = [AMXCTAccessibility accessibilityElementWithApplication:application];
    NSArray *windows = [AMXCTAccessibility attributes:@[@"AXWindows"] ofElement:appElement][@"AXWindows"];
    if ([windows isKindOfClass:NSArray.class]) {
      for (id element in windows) {
        AMWindowHandle *handle = [AMWindowHandle new];
        handle.accessibilityElement = element;
        if (AMWindowFlag(handle, AM_KEY_MINIMIZED)) {
          [result addObject:handle];
        }
      }
      return result.copy;
    }
  }
  if (!AMSnapshotUtils.isAccessibilityTrusted) {
    return @[];
  }
  NSRunningApplication *runningApp = [NSRunningApplication runningApplicationsWithBundleIdentifier:application.am_bundleID].firstObject;
  if (nil == runningApp) {
    return @[];
  }
  AXUIElementRef appRef = AXUIElementCreateApplication(runningApp.processIdentifier);
  id windows = AMCopyAXAttribute(appRef, kAXWindowsAttribute);
  CFRelease(appRef);
  for (id window in [windows isKindOfClass:NSArray.class] ? windows : @[]) {
    AMWindowHandle *handle = [AMWindowHandle new];
    [handle adoptAXElement:(AXUIElementRef)CFRetain((__bridge CFTypeRef)window)];
    if (AMWindowFlag(handle, AM_KEY_MINIMIZED)) {
      [result addObject:handle];
    }
  }
  return result.copy;
}

// The XCUIElement of the window, which is not available while the window is minimized
+ (nullable XCUIElement *)elementOfHandle:(AMWindowHandle *)handle application:(XCUIApplication *)application
{
  if (nil != handle.element && nil != [handle.element snapshotWithError:nil]) {
    return handle.element;
  }
  if (nil == handle.accessibilityElement) {
    return nil;
  }
  for (XCUIElement *window in [self windowsOfApplication:application]) {
    id element = [AMXCTAccessibility accessibilityElementWithSnapshot:[window snapshotWithError:nil]];
    if ([element isEqual:handle.accessibilityElement]) {
      handle.element = window;
      return window;
    }
  }
  return nil;
}

// Presses the button of the window without moving the mouse
+ (BOOL)pressButton:(NSString *)identifier ofHandle:(AMWindowHandle *)handle application:(XCUIApplication *)application
{
  XCUIElement *window = [self elementOfHandle:handle application:application];
  XCUIElement *button = [[window descendantsMatchingType:XCUIElementTypeButton] matchingIdentifier:identifier].firstMatch;
  id element = nil == window || !button.exists
    ? nil
    : [AMXCTAccessibility accessibilityElementWithSnapshot:[button snapshotWithError:nil]];
  return nil != element && [AMXCTAccessibility pressElement:element error:nil];
}

// Restores the window by its Dock item. It is only done if the item can be identified unambiguously
+ (BOOL)restoreHandleThroughDock:(AMWindowHandle *)handle
{
  NSString *title = AMReadWindow(handle)[AM_KEY_TITLE] ?: handle.fallbackTitle;
  if (0 == title.length) {
    return NO;
  }
  XCUIApplication *dock = [[XCUIApplication alloc] initWithBundleIdentifier:AM_DOCK_BUNDLE_ID];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title == %@", title];
  NSMutableArray<XCUIElement *> *candidates = [NSMutableArray array];
  for (XCUIElement *item in [[dock descendantsMatchingType:XCUIElementTypeDockItem] matchingPredicate:predicate].allElementsBoundByIndex) {
    id element = [AMXCTAccessibility accessibilityElementWithSnapshot:[item snapshotWithError:nil]];
    NSDictionary *attrs = [AMXCTAccessibility attributes:@[@"AXSubrole"] ofElement:element];
    if ([attrs[@"AXSubrole"] isEqual:AM_MINIMIZED_DOCK_ITEM_SUBROLE]) {
      [candidates addObject:item];
    }
  }
  if (1 != candidates.count) {
    // Another minimized window with the same title could be restored by mistake
    return NO;
  }
  [candidates.firstObject click];
  return AMWaitForWindowFlag(handle, AM_KEY_MINIMIZED, NO);
}

+ (BOOL)minimizeHandle:(AMWindowHandle *)handle application:(XCUIApplication *)application
{
  if (gUsesUnprivilegedRoutes
      && [self pressButton:AM_MINIMIZE_BUTTON_ID ofHandle:handle application:application]
      && AMWaitForWindowFlag(handle, AM_KEY_MINIMIZED, YES)) {
    return YES;
  }
  AXUIElementRef ref = [handle axElement];
  return NULL != ref
    && AMAXSetBool(ref, kAXMinimizedAttribute, YES)
    && AMWaitForWindowFlag(handle, AM_KEY_MINIMIZED, YES);
}

+ (BOOL)restoreHandle:(AMWindowHandle *)handle
{
  if (gUsesUnprivilegedRoutes && [self restoreHandleThroughDock:handle]) {
    return YES;
  }
  AXUIElementRef ref = [handle axElement];
  return NULL != ref
    && AMAXSetBool(ref, kAXMinimizedAttribute, NO)
    && AMWaitForWindowFlag(handle, AM_KEY_MINIMIZED, NO);
}

+ (BOOL)enterFullscreenHandle:(AMWindowHandle *)handle application:(XCUIApplication *)application
{
  if (gUsesUnprivilegedRoutes
      && [self pressButton:AM_FULLSCREEN_BUTTON_ID ofHandle:handle application:application]
      && AMWaitForWindowFlag(handle, AM_KEY_FULLSCREEN, YES)) {
    return YES;
  }
  AXUIElementRef ref = [handle axElement];
  return NULL != ref
    && AMAXSetBool(ref, CFSTR("AXFullScreen"), YES)
    && AMWaitForWindowFlag(handle, AM_KEY_FULLSCREEN, YES);
}

+ (BOOL)focusHandle:(AMWindowHandle *)handle application:(XCUIApplication *)application
{
  [application activate];
  if (AMWaitForWindowFlag(handle, AM_KEY_FOCUSED, YES)) {
    return YES;
  }
  AXUIElementRef ref = [handle axElement];
  if (NULL == ref) {
    return NO;
  }
  AXUIElementPerformAction(ref, kAXRaiseAction);
  return AMWaitForWindowFlag(handle, AM_KEY_FOCUSED, YES);
}

+ (BOOL)leaveFullscreenHandle:(AMWindowHandle *)handle application:(XCUIApplication *)application
{
  if (gUsesUnprivilegedRoutes) {
    // The window buttons are hidden in the fullscreen mode, so the standard shortcut is used.
    // It toggles the focused window, so the shortcut is skipped if the target cannot be focused
    if ([self focusHandle:handle application:application]) {
      [application typeKey:@"f" modifierFlags:XCUIKeyModifierControl | XCUIKeyModifierCommand];
      if (AMWaitForWindowFlag(handle, AM_KEY_FULLSCREEN, NO)) {
        return YES;
      }
    }
  }
  AXUIElementRef ref = [handle axElement];
  return NULL != ref
    && AMAXSetBool(ref, CFSTR("AXFullScreen"), NO)
    && AMWaitForWindowFlag(handle, AM_KEY_FULLSCREEN, NO);
}

// Applies the change and describes the result
+ (nullable NSDictionary<NSString *, id> *)adjustHandle:(AMWindowHandle *)handle
                                            application:(XCUIApplication *)application
                                                  state:(nullable NSString *)state
                                                   rect:(NSDictionary<NSString *, NSNumber *> *)rect
                                                display:(nullable AMScreenProperties *)targetDisplay
                                                  error:(NSError **)error
{
  NSDictionary *attrs = AMReadWindow(handle);
  if (nil == attrs) {
    AMAssignError(error, [self windowErrorWithCode:AMWindowErrorFailure
                                            format:@"Cannot read the window state. The XCTest accessibility interface is not available. "
                          @"Grant the Accessibility permission to the WebDriverAgentRunner app and restart it"]);
    return nil;
  }

  BOOL wantsMinimized = [state isEqualToString:AMWindowStateMinimized];
  BOOL isMinimized = [attrs[AM_KEY_MINIMIZED] boolValue];
  if (isMinimized && wantsMinimized) {
    return [self infoForHandle:handle];
  }
  // Every other change needs a regular window
  if (isMinimized && ![self restoreHandle:handle]) {
    AMAssignError(error, [self windowErrorWithCode:AMWindowErrorFailure
                                            format:@"The minimized window cannot be restored. Make sure there are no other minimized windows "
                          @"with the same title or grant the Accessibility permission to the WebDriverAgentRunner app"]);
    return nil;
  }
  BOOL isFullscreen = [AMReadWindow(handle)[AM_KEY_FULLSCREEN] boolValue];
  BOOL wantsFullscreen = [state isEqualToString:AMWindowStateFullscreen];
  if (isFullscreen && !wantsFullscreen && ![self leaveFullscreenHandle:handle application:application]) {
    AMAssignError(error, [self windowErrorWithCode:AMWindowErrorFailure
                                            format:@"The window did not leave the fullscreen mode in %.0f seconds", AM_WINDOW_STATE_TIMEOUT]);
    return nil;
  }
  if (wantsMinimized) {
    if (![self minimizeHandle:handle application:application]) {
      AMAssignError(error, [self windowErrorWithCode:AMWindowErrorFailure format:@"The window cannot be minimized"]);
      return nil;
    }
    return [self infoForHandle:handle];
  }
  if (wantsFullscreen) {
    if (!isFullscreen && ![self enterFullscreenHandle:handle application:application]) {
      AMAssignError(error, [self windowErrorWithCode:AMWindowErrorFailure format:@"The window cannot be put into the fullscreen mode"]);
      return nil;
    }
    return [self infoForHandle:handle];
  }

  if ([state isEqualToString:AMWindowStateMaximized] || rect.count > 0 || nil != targetDisplay) {
    AXUIElementRef ref = [handle axElement];
    if (NULL == ref) {
      AMAssignError(error, [self windowErrorWithCode:AMWindowErrorFailure format:@"%@", AM_GEOMETRY_ACCESS_DENIED_MESSAGE]);
      return nil;
    }
    if (![self applyGeometryToAXWindow:ref state:state rect:rect display:targetDisplay error:error]) {
      return nil;
    }
  }
  return [self infoForHandle:handle];
}

+ (BOOL)applyGeometryToAXWindow:(AXUIElementRef)ref
                          state:(nullable NSString *)state
                           rect:(NSDictionary<NSString *, NSNumber *> *)rect
                        display:(nullable AMScreenProperties *)targetDisplay
                          error:(NSError **)error
{
  CGRect current;
  if (!AMAXReadRect(ref, &current)) {
    AMAssignError(error, [self windowErrorWithCode:AMWindowErrorFailure format:@"Cannot read the current window rect"]);
    return NO;
  }
  if ([state isEqualToString:AMWindowStateMaximized]) {
    // Fills the visible area of the display, which is also deterministic when repeated
    AMScreenProperties *display = targetDisplay ?: AMDisplayForRect(current);
    if (nil == display) {
      AMAssignError(error, [self windowErrorWithCode:AMWindowErrorFailure format:@"Cannot determine the display to maximize the window on"]);
      return NO;
    }
    CGRect visible = display.visibleBounds;
    return [self applyRect:@{@"x": @(visible.origin.x), @"y": @(visible.origin.y),
                             @"width": @(visible.size.width), @"height": @(visible.size.height)}
                   current:current ref:ref display:nil error:error];
  }
  return [self applyRect:rect current:current ref:ref display:targetDisplay error:error];
}

// Coordinates are global unless a display is given
+ (BOOL)applyRect:(NSDictionary<NSString *, NSNumber *> *)rect
          current:(CGRect)current
              ref:(AXUIElementRef)ref
          display:(nullable AMScreenProperties *)targetDisplay
            error:(NSError **)error
{
  CGSize size = CGSizeMake(nil != rect[@"width"] ? rect[@"width"].doubleValue : current.size.width,
                           nil != rect[@"height"] ? rect[@"height"].doubleValue : current.size.height);
  CGPoint origin = current.origin;
  if (nil != targetDisplay) {
    CGRect bounds = targetDisplay.bounds;
    AMScreenProperties *sourceDisplay = AMDisplayForRect(current);
    CGPoint sourceOrigin = nil == sourceDisplay ? CGPointZero : sourceDisplay.bounds.origin;
    // x/y are relative to the target display; the relative position is kept if they are omitted
    origin.x = bounds.origin.x + (nil != rect[@"x"] ? rect[@"x"].doubleValue : current.origin.x - sourceOrigin.x);
    origin.y = bounds.origin.y + (nil != rect[@"y"] ? rect[@"y"].doubleValue : current.origin.y - sourceOrigin.y);
    // Keep the window within the display
    origin.x = MAX(bounds.origin.x, MIN(origin.x, CGRectGetMaxX(bounds) - size.width));
    origin.y = MAX(bounds.origin.y, MIN(origin.y, CGRectGetMaxY(bounds) - size.height));
  } else {
    origin.x = nil != rect[@"x"] ? rect[@"x"].doubleValue : origin.x;
    origin.y = nil != rect[@"y"] ? rect[@"y"].doubleValue : origin.y;
  }

  BOOL moves = !CGPointEqualToPoint(origin, current.origin);
  BOOL resizes = !CGSizeEqualToSize(size, current.size);
  if (moves && !AMAXSetGeometry(ref, kAXPositionAttribute, kAXValueTypeCGPoint, &origin)) {
    AMAssignError(error, [self windowErrorWithCode:AMWindowErrorFailure format:@"The window cannot be moved"]);
    return NO;
  }
  if (resizes && !AMAXSetGeometry(ref, kAXSizeAttribute, kAXValueTypeCGSize, &size)) {
    AMAssignError(error, [self windowErrorWithCode:AMWindowErrorFailure format:@"The window cannot be resized"]);
    return NO;
  }
  // The size may have been adjusted for the new display, which can shift the window
  if (moves && resizes) {
    AMAXSetGeometry(ref, kAXPositionAttribute, kAXValueTypeCGPoint, &origin);
  }
  return YES;
}

@end
