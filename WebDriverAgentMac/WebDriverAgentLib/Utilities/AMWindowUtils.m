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
#import "XCUIApplication+AMHelpers.h"
#import "XCUIElementQuery+AMHelpers.h"

NSString *const AMWindowErrorDomain = @"AMWindowErrorDomain";
NSString *const AMWindowStateNormal = @"normal";
NSString *const AMWindowStateMinimized = @"minimized";
NSString *const AMWindowStateMaximized = @"maximized";
NSString *const AMWindowStateFullscreen = @"fullscreen";

static const NSTimeInterval AM_WINDOW_STATE_TIMEOUT = 2.0;
static NSString *const AM_ACCESS_DENIED_MESSAGE = @"Cannot access the window through the Accessibility API. "
  @"Grant the Accessibility permission to the WebDriverAgentRunner app and restart it";

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

static BOOL AMAXWaitForBool(AXUIElementRef element, CFStringRef name, BOOL expected)
{
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:AM_WINDOW_STATE_TIMEOUT];
  while ([AMAXBool(element, name) boolValue] != expected) {
    if ([deadline timeIntervalSinceNow] <= 0) {
      return NO;
    }
    [NSThread sleepForTimeInterval:0.1];
  }
  return YES;
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

@implementation AMWindowUtils

+ (NSArray<XCUIElement *> *)windowsOfApplication:(XCUIApplication *)application
{
  return [application.windows am_allMatches];
}

+ (nullable XCUIElement *)mainWindowOfApplication:(XCUIApplication *)application
{
  NSArray<XCUIElement *> *windows = [self windowsOfApplication:application];
  XCUIElement *focused = nil;
  for (XCUIElement *window in windows) {
    AXUIElementRef ref = [self createAXWindow:window];
    if (NULL == ref) {
      break;
    }
    NSNumber *isMain = AMAXBool(ref, kAXMainAttribute);
    NSNumber *isFocused = AMAXBool(ref, kAXFocusedAttribute);
    CFRelease(ref);
    if (isMain.boolValue) {
      return window;
    }
    if (isFocused.boolValue && nil == focused) {
      focused = window;
    }
  }
  return focused ?: windows.firstObject;
}



+ (nullable NSDictionary<NSString *, id> *)infoForWindow:(XCUIElement *)window
{
  id<XCUIElementSnapshot> snapshot = [window snapshotWithError:nil];
  if (nil == snapshot) {
    return nil;
  }
  AXUIElementRef ref = [AMSnapshotUtils createAXElementWithSnapshot:snapshot];
  NSDictionary *info = [self infoWithAXWindow:ref title:snapshot.title frame:snapshot.frame];
  if (NULL != ref) {
    CFRelease(ref);
  }
  return info;
}

// The values from the fallbacks are used if the AX element is not available
+ (NSDictionary<NSString *, id> *)infoWithAXWindow:(nullable AXUIElementRef)ref
                                             title:(nullable NSString *)title
                                             frame:(CGRect)frame
{
  NSMutableDictionary<NSString *, id> *info = [NSMutableDictionary dictionary];
  // Traits need the Accessibility permission; they are null without it
  NSNumber *null = (NSNumber *)NSNull.null;
  NSDictionary *traits = @{@"isMain": null, @"isFocused": null, @"isMinimized": null,
                           @"isFullscreen": null, @"isMovable": null, @"isResizable": null};
  if (NULL != ref) {
    CGRect axRect;
    if (AMAXReadRect(ref, &axRect)) {
      frame = axRect;
    }
    id axTitle = AMCopyAXAttribute(ref, kAXTitleAttribute);
    title = [axTitle isKindOfClass:NSString.class] ? axTitle : title;
    traits = @{
      @"isMain": AMAXBool(ref, kAXMainAttribute) ?: null,
      @"isFocused": AMAXBool(ref, kAXFocusedAttribute) ?: null,
      @"isMinimized": AMAXBool(ref, kAXMinimizedAttribute) ?: null,
      @"isFullscreen": AMAXBool(ref, CFSTR("AXFullScreen")) ?: null,
      @"isMovable": @(AMAXIsSettable(ref, kAXPositionAttribute)),
      @"isResizable": @(AMAXIsSettable(ref, kAXSizeAttribute)),
    };
  }
  info[@"title"] = title ?: @"";
  [info addEntriesFromDictionary:traits];
  info[@"rect"] = AMCGRectToDict(frame);
  AMScreenProperties *display = AMDisplayForRect(frame);
  info[@"displayId"] = nil == display ? NSNull.null : @(display.identifier);
  return info.copy;
}

+ (nullable NSDictionary<NSString *, id> *)adjustWindow:(XCUIElement *)window
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
  AXUIElementRef ref = [AMSnapshotUtils createAXElementWithSnapshot:snapshot];
  NSDictionary *result = [self adjustAXWindow:ref
                                        state:state rect:rect display:display
                                        title:snapshot.title frame:snapshot.frame
                                        error:error];
  if (NULL != ref) {
    CFRelease(ref);
  }
  return result;
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
  if (!AMSnapshotUtils.isAccessibilityTrusted) {
    AMAssignError(error, [self windowErrorWithCode:AMWindowErrorFailure format:@"%@", AM_ACCESS_DENIED_MESSAGE]);
    return nil;
  }
  NSArray *windows = [self minimizedAXWindowsOfApplication:application];
  if (0 == windows.count) {
    AMAssignError(error, [self windowErrorWithCode:AMWindowErrorNotFound format:@"The application has no minimized windows"]);
    return nil;
  }
  return [self adjustAXWindow:(__bridge AXUIElementRef)windows.firstObject
                        state:state rect:rect display:display
                        title:nil frame:CGRectZero
                        error:error];
}

+ (NSUInteger)minimizedWindowsCountOfApplication:(XCUIApplication *)application
{
  return [self minimizedAXWindowsOfApplication:application].count;
}

#pragma mark - Private

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
  NSNumber *displayId = arguments[@"displayId"];
  if ([displayId isKindOfClass:NSNull.class]) {
    displayId = nil;
  }
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

// Applies the change and describes the result. The title and the frame are used if AX does not provide them
+ (nullable NSDictionary<NSString *, id> *)adjustAXWindow:(nullable AXUIElementRef)ref
                                                    state:(nullable NSString *)state
                                                     rect:(NSDictionary<NSString *, NSNumber *> *)rect
                                                  display:(nullable AMScreenProperties *)display
                                                    title:(nullable NSString *)title
                                                    frame:(CGRect)frame
                                                    error:(NSError **)error
{
  if (NULL == ref) {
    AMAssignError(error, [self windowErrorWithCode:AMWindowErrorFailure format:@"%@", AM_ACCESS_DENIED_MESSAGE]);
    return nil;
  }
  if (![self adjustAXWindow:ref state:state rect:rect display:display error:error]) {
    return nil;
  }
  return [self infoWithAXWindow:ref title:title frame:frame];
}

// Minimized windows are not in the XCUIElement hierarchy, but the AX application keeps them
+ (NSArray *)minimizedAXWindowsOfApplication:(XCUIApplication *)application
{
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
  NSMutableArray *result = [NSMutableArray array];
  for (id window in [windows isKindOfClass:NSArray.class] ? windows : @[]) {
    if ([AMAXBool((__bridge AXUIElementRef)window, kAXMinimizedAttribute) boolValue]) {
      [result addObject:window];
    }
  }
  return result.copy;
}

+ (NSError *)windowErrorWithCode:(AMWindowErrorCode)code format:(NSString *)format, ... NS_FORMAT_FUNCTION(2,3)
{
  va_list args;
  va_start(args, format);
  NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);
  return [NSError errorWithDomain:AMWindowErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: message}];
}

// Creates an AX element for the window. The caller must CFRelease it
+ (nullable AXUIElementRef)createAXWindow:(XCUIElement *)window CF_RETURNS_RETAINED
{
  return [AMSnapshotUtils createAXElementWithSnapshot:[window snapshotWithError:nil]];
}

+ (BOOL)adjustAXWindow:(AXUIElementRef)ref
                 state:(nullable NSString *)state
                  rect:(NSDictionary<NSString *, NSNumber *> *)rect
               display:(nullable AMScreenProperties *)targetDisplay
                 error:(NSError **)error
{
  if ([state isEqualToString:AMWindowStateMinimized]) {
    if (!(AMAXSetBool(ref, kAXMinimizedAttribute, YES) && AMAXWaitForBool(ref, kAXMinimizedAttribute, YES))) {
      AMAssignError(error, [self windowErrorWithCode:AMWindowErrorFailure format:@"The window cannot be minimized"]);
      return NO;
    }
    return YES;
  }

  // Every other change needs a regular window
  if ([AMAXBool(ref, kAXMinimizedAttribute) boolValue]) {
    AMAXSetBool(ref, kAXMinimizedAttribute, NO);
    AMAXWaitForBool(ref, kAXMinimizedAttribute, NO);
  }
  if ([AMAXBool(ref, CFSTR("AXFullScreen")) boolValue] && ![state isEqualToString:AMWindowStateFullscreen]) {
    AMAXSetBool(ref, CFSTR("AXFullScreen"), NO);
    if (!AMAXWaitForBool(ref, CFSTR("AXFullScreen"), NO)) {
      AMAssignError(error, [self windowErrorWithCode:AMWindowErrorFailure format:@"The window did not leave the fullscreen mode in %.0f seconds", AM_WINDOW_STATE_TIMEOUT]);
      return NO;
    }
  }

  if ([state isEqualToString:AMWindowStateFullscreen]) {
    if (![AMAXBool(ref, CFSTR("AXFullScreen")) boolValue]
        && !(AMAXSetBool(ref, CFSTR("AXFullScreen"), YES) && AMAXWaitForBool(ref, CFSTR("AXFullScreen"), YES))) {
      AMAssignError(error, [self windowErrorWithCode:AMWindowErrorFailure format:@"The window cannot be put into the fullscreen mode"]);
      return NO;
    }
    return YES;
  }

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
  if (rect.count > 0 || nil != targetDisplay) {
    return [self applyRect:rect current:current ref:ref display:targetDisplay error:error];
  }
  return YES;
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
