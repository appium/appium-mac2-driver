/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AMWindowCommands.h"

#import <ApplicationServices/ApplicationServices.h>

#import "AMScreenUtils.h"
#import "AMGeometryUtils.h"
#import "AMSnapshotUtils.h"
#import "FBElementCache.h"
#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "XCUIElement+FBFind.h"
#import "XCUIElementQuery+AMHelpers.h"

static const NSTimeInterval AM_WINDOW_STATE_TIMEOUT = 2.0;
static NSString *const AM_STATE_NORMAL = @"normal";
static NSString *const AM_STATE_MINIMIZED = @"minimized";
static NSString *const AM_STATE_MAXIMIZED = @"maximized";
static NSString *const AM_STATE_FULLSCREEN = @"fullscreen";


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

@implementation AMWindowCommands

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute POST:@"/window/maximize"] respondWithTarget:self action:@selector(handleMaximizeWindow:)],
    [[FBRoute POST:@"/window/fullscreen"] respondWithTarget:self action:@selector(handleFullscreenWindow:)],
    [[FBRoute POST:@"/window/minimize"] respondWithTarget:self action:@selector(handleMinimizeWindow:)],
    [[FBRoute GET:@"/wda/windows"] respondWithTarget:self action:@selector(handleListWindows:)],
    [[FBRoute POST:@"/wda/window/adjust"] respondWithTarget:self action:@selector(handleAdjustWindow:)],
  ];
}

#pragma mark - Commands

+ (id<FBResponsePayload>)handleMaximizeWindow:(FBRouteRequest *)request
{
  return [self performClickWithButtonId:@"_XCUI:FullScreenWindow"
                                request:request
                           errorMessage:[NSString stringWithFormat:@"%@ window cannot be maximized because the corresponding button is not available", request.session.currentApplication.description]];
}

+ (id<FBResponsePayload>)handleFullscreenWindow:(FBRouteRequest *)request
{
  return [self performClickWithButtonId:@"_XCUI:FullScreenWindow"
                                request:request
                           errorMessage:[NSString stringWithFormat:@"%@ window cannot be put into fullscreen mode because the corresponding button is not available", request.session.currentApplication.description]];
}

+ (id<FBResponsePayload>)handleMinimizeWindow:(FBRouteRequest *)request
{
  return [self performClickWithButtonId:@"_XCUI:MinimizeWindow"
                                request:request
                           errorMessage:[NSString stringWithFormat:@"%@ window cannot be minimized because the corresponding button is not available", request.session.currentApplication.description]];
}

+ (id<FBResponsePayload>)handleListWindows:(FBRouteRequest *)request
{
  NSMutableArray *result = [NSMutableArray array];
  for (XCUIElement *window in [request.session.currentApplication.windows am_allMatches]) {
    [result addObject:[self describeWindow:window cache:request.session.elementCache]];
  }
  return FBResponseWithObject(result.copy);
}

+ (id<FBResponsePayload>)handleAdjustWindow:(FBRouteRequest *)request
{
  NSMutableDictionary<NSString *, NSNumber *> *rect = [NSMutableDictionary dictionary];
  for (NSString *key in @[@"x", @"y", @"width", @"height"]) {
    id value = request.arguments[key];
    if (nil == value || [value isKindOfClass:NSNull.class]) {
      continue;
    }
    if (![value isKindOfClass:NSNumber.class]
        || (([key hasPrefix:@"w"] || [key hasPrefix:@"h"]) && [value doubleValue] <= 0)) {
      return [self invalidArgumentResponse:@"'%@' must be a valid number, got '%@'", key, value];
    }
    rect[key] = value;
  }
  NSNumber *displayId = request.arguments[@"displayId"];
  if ([displayId isKindOfClass:NSNull.class]) {
    displayId = nil;
  }
  NSString *state = request.arguments[@"state"];
  if ([state isKindOfClass:NSNull.class]) {
    state = nil;
  }
  if (nil != state && ![@[AM_STATE_NORMAL, AM_STATE_MINIMIZED, AM_STATE_MAXIMIZED, AM_STATE_FULLSCREEN] containsObject:state]) {
    return [self invalidArgumentResponse:@"'state' must be one of: %@, %@, %@, %@. Got '%@'",
            AM_STATE_NORMAL, AM_STATE_MINIMIZED, AM_STATE_MAXIMIZED, AM_STATE_FULLSCREEN, state];
  }
  if (nil == state && 0 == rect.count && nil == displayId) {
    return [self invalidArgumentResponse:@"At least one of 'state', 'x', 'y', 'width', 'height' or 'displayId' must be provided"];
  }
  BOOL isGeometryFree = [state isEqualToString:AM_STATE_MINIMIZED] || [state isEqualToString:AM_STATE_FULLSCREEN];
  if ((isGeometryFree && (rect.count > 0 || nil != displayId))
      || ([state isEqualToString:AM_STATE_MAXIMIZED] && rect.count > 0)) {
    return [self invalidArgumentResponse:@"The '%@' state cannot be combined with the explicit window geometry", state];
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
      return [self invalidArgumentResponse:@"The display '%@' is unknown. Available identifiers: %@",
              displayId, [available componentsJoinedByString:@","]];
    }
  }
  XCUIElement *window = nil;
  NSString *windowId = request.arguments[@"windowId"];
  if ([windowId isKindOfClass:NSString.class]) {
    window = [request.session.elementCache elementForUUID:windowId];
    if (XCUIElementTypeWindow != window.elementType) {
      return [self invalidArgumentResponse:@"The element '%@' is not a window", windowId];
    }
  } else {
    window = [self mainWindowOfApplication:request.session.currentApplication];
  }
  if (nil == window) {
    return FBResponseWithStatus([FBCommandStatus noSuchWindowErrorWithMessage:@"The application has no windows" traceback:nil]);
  }
  FBElementCache *cache = request.session.elementCache;
  // A minimized window may disappear from the hierarchy, so it is described upfront
  NSMutableDictionary *info = [[self describeWindow:window cache:cache] mutableCopy];
  NSString *describedWindowId = info[@"windowId"];
  NSError *error = nil;
  if (![self adjustWindow:window state:state rect:rect display:targetDisplay error:&error]) {
    return FBResponseWithStatus([FBCommandStatus unknownErrorWithMessage:error.localizedDescription traceback:nil]);
  }
  if ([state isEqualToString:AM_STATE_MINIMIZED]) {
    info[@"isMinimized"] = @YES;
    return FBResponseWithObject(info.copy);
  }
  info = [[self describeWindow:window cache:cache] mutableCopy];
  info[@"windowId"] = describedWindowId;
  return FBResponseWithObject(info.copy);
}

#pragma mark - Helpers

+ (id<FBResponsePayload>)invalidArgumentResponse:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
  va_list args;
  va_start(args, format);
  NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);
  return FBResponseWithStatus([FBCommandStatus invalidArgumentErrorWithMessage:message traceback:nil]);
}

+ (NSError *)windowErrorWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
  va_list args;
  va_start(args, format);
  NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);
  return [NSError errorWithDomain:@"AMWindowCommands" code:1 userInfo:@{NSLocalizedDescriptionKey: message}];
}

// Creates an AX element for the window. The caller must CFRelease it
+ (nullable AXUIElementRef)createAXWindow:(XCUIElement *)window CF_RETURNS_RETAINED
{
  return [AMSnapshotUtils createAXElementWithSnapshot:[window snapshotWithError:nil]];
}

// The window flagged as main, then the focused one, then the first one
+ (nullable XCUIElement *)mainWindowOfApplication:(XCUIApplication *)application
{
  NSArray<XCUIElement *> *windows = [application.windows am_allMatches];
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

+ (NSDictionary<NSString *, id> *)describeWindow:(XCUIElement *)window cache:(FBElementCache *)cache
{
  NSMutableDictionary<NSString *, id> *info = [NSMutableDictionary dictionary];
  CGRect rect = window.frame;
  info[@"title"] = window.title ?: @"";
  // Traits need the Accessibility permission; they are null without it
  NSNumber *null = (NSNumber *)NSNull.null;
  NSDictionary *traits = @{@"isMain": null, @"isFocused": null, @"isMinimized": null,
                           @"isFullscreen": null, @"isMovable": null, @"isResizable": null};
  AXUIElementRef ref = [self createAXWindow:window];
  if (NULL != ref) {
    CGRect axRect;
    if (AMAXReadRect(ref, &axRect)) {
      rect = axRect;
    }
    traits = @{
      @"isMain": AMAXBool(ref, kAXMainAttribute) ?: null,
      @"isFocused": AMAXBool(ref, kAXFocusedAttribute) ?: null,
      @"isMinimized": AMAXBool(ref, kAXMinimizedAttribute) ?: null,
      @"isFullscreen": AMAXBool(ref, CFSTR("AXFullScreen")) ?: null,
      @"isMovable": @(AMAXIsSettable(ref, kAXPositionAttribute)),
      @"isResizable": @(AMAXIsSettable(ref, kAXSizeAttribute)),
    };
    CFRelease(ref);
  }
  [info addEntriesFromDictionary:traits];
  info[@"rect"] = AMCGRectToDict(rect);
  AMScreenProperties *display = AMDisplayForRect(rect);
  info[@"displayId"] = nil == display ? NSNull.null : @(display.identifier);
  info[@"windowId"] = [cache storeElement:window];
  return info.copy;
}

+ (BOOL)adjustWindow:(XCUIElement *)window
               state:(nullable NSString *)state
                rect:(NSDictionary<NSString *, NSNumber *> *)rect
             display:(nullable AMScreenProperties *)targetDisplay
               error:(NSError **)error
{
  AXUIElementRef ref = [self createAXWindow:window];
  if (NULL == ref) {
    *error = [self windowErrorWithFormat:@"Cannot access the window through the Accessibility API. "
              @"Grant the Accessibility permission to the WebDriverAgentRunner app and restart it"];
    return NO;
  }
  BOOL result = [self adjustAXWindow:ref state:state rect:rect display:targetDisplay error:error];
  CFRelease(ref);
  return result;
}

+ (BOOL)adjustAXWindow:(AXUIElementRef)ref
                 state:(nullable NSString *)state
                  rect:(NSDictionary<NSString *, NSNumber *> *)rect
               display:(nullable AMScreenProperties *)targetDisplay
                 error:(NSError **)error
{
  if ([state isEqualToString:AM_STATE_MINIMIZED]) {
    if (!AMAXSetBool(ref, kAXMinimizedAttribute, YES)) {
      *error = [self windowErrorWithFormat:@"The window cannot be minimized"];
      return NO;
    }
    return YES;
  }

  // Every other change needs a regular window
  if ([AMAXBool(ref, kAXMinimizedAttribute) boolValue]) {
    AMAXSetBool(ref, kAXMinimizedAttribute, NO);
    AMAXWaitForBool(ref, kAXMinimizedAttribute, NO);
  }
  if ([AMAXBool(ref, CFSTR("AXFullScreen")) boolValue] && ![state isEqualToString:AM_STATE_FULLSCREEN]) {
    AMAXSetBool(ref, CFSTR("AXFullScreen"), NO);
    if (!AMAXWaitForBool(ref, CFSTR("AXFullScreen"), NO)) {
      *error = [self windowErrorWithFormat:@"The window did not leave the fullscreen mode in %.0f seconds", AM_WINDOW_STATE_TIMEOUT];
      return NO;
    }
  }

  if ([state isEqualToString:AM_STATE_FULLSCREEN]) {
    if (![AMAXBool(ref, CFSTR("AXFullScreen")) boolValue]
        && !(AMAXSetBool(ref, CFSTR("AXFullScreen"), YES) && AMAXWaitForBool(ref, CFSTR("AXFullScreen"), YES))) {
      *error = [self windowErrorWithFormat:@"The window cannot be put into the fullscreen mode"];
      return NO;
    }
    return YES;
  }

  CGRect current;
  if (!AMAXReadRect(ref, &current)) {
    *error = [self windowErrorWithFormat:@"Cannot read the current window rect"];
    return NO;
  }
  if ([state isEqualToString:AM_STATE_MAXIMIZED]) {
    // Fills the visible area of the display, which is also deterministic when repeated
    AMScreenProperties *display = targetDisplay ?: AMDisplayForRect(current);
    if (nil == display) {
      *error = [self windowErrorWithFormat:@"Cannot determine the display to maximize the window on"];
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
  CGSize size = CGSizeMake(rect[@"width"] ? rect[@"width"].doubleValue : current.size.width,
                           rect[@"height"] ? rect[@"height"].doubleValue : current.size.height);
  CGPoint origin = current.origin;
  if (nil != targetDisplay) {
    CGRect bounds = targetDisplay.bounds;
    AMScreenProperties *sourceDisplay = AMDisplayForRect(current);
    CGPoint sourceOrigin = nil == sourceDisplay ? CGPointZero : sourceDisplay.bounds.origin;
    // x/y are relative to the target display; the relative position is kept if they are omitted
    origin.x = bounds.origin.x + (rect[@"x"] ? rect[@"x"].doubleValue : current.origin.x - sourceOrigin.x);
    origin.y = bounds.origin.y + (rect[@"y"] ? rect[@"y"].doubleValue : current.origin.y - sourceOrigin.y);
    // Keep the window within the display
    origin.x = MAX(bounds.origin.x, MIN(origin.x, CGRectGetMaxX(bounds) - size.width));
    origin.y = MAX(bounds.origin.y, MIN(origin.y, CGRectGetMaxY(bounds) - size.height));
  } else {
    origin.x = rect[@"x"] ? rect[@"x"].doubleValue : origin.x;
    origin.y = rect[@"y"] ? rect[@"y"].doubleValue : origin.y;
  }

  BOOL moves = !CGPointEqualToPoint(origin, current.origin);
  BOOL resizes = !CGSizeEqualToSize(size, current.size);
  if (moves && !AMAXSetGeometry(ref, kAXPositionAttribute, kAXValueTypeCGPoint, &origin)) {
    *error = [self windowErrorWithFormat:@"The window cannot be moved"];
    return NO;
  }
  if (resizes && !AMAXSetGeometry(ref, kAXSizeAttribute, kAXValueTypeCGSize, &size)) {
    *error = [self windowErrorWithFormat:@"The window cannot be resized"];
    return NO;
  }
  // The size may have been adjusted for the new display, which can shift the window
  if (moves && resizes) {
    AMAXSetGeometry(ref, kAXPositionAttribute, kAXValueTypeCGPoint, &origin);
  }
  return YES;
}

+ (id<FBResponsePayload>)performClickWithButtonId:(NSString *)buttonId
                                          request:(FBRouteRequest *)request
                                     errorMessage:(NSString *)errorMessage
{
  XCUIApplication *application = request.session.currentApplication;
  XCUIElement *dstButton = [application fb_descendantsMatchingIdentifier:buttonId
                                             shouldReturnAfterFirstMatch:YES].firstObject;
  if (nil == dstButton || !dstButton.hittable) {
    return FBResponseWithUnknownErrorFormat(@"%@", errorMessage);
  }
  [dstButton click];
  return FBResponseWithOK();
}

@end
