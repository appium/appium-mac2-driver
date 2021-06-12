/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBElementCommands.h"

#import "AMGeometryUtils.h"
#import "AMKeyboardUtils.h"
#import "FBConfiguration.h"
#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBRunLoopSpinner.h"
#import "FBElementCache.h"
#import "FBElementUtils.h"
#import "FBErrorBuilder.h"
#import "FBExceptions.h"
#import "FBLogger.h"
#import "FBSession.h"
#import "FBElementUtils.h"
#import "FBMacros.h"
#import "FBProtocolHelpers.h"
#import "FBRuntimeUtils.h"
#import "NSPredicate+FBFormat.h"
#import "FBElementTypeTransformer.h"
#import "XCUIApplication+AMHelpers.h"
#import "XCUIElement+AMAttributes.h"
#import "XCUIElement+AMCoordinates.h"
#import "XCUIElement+AMEditable.h"
#import "XCUIElement+AMSwipe.h"
#import "XCUICoordinate+AMSwipe.h"

@interface FBElementCommands ()
@end

@implementation FBElementCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/window/size"] respondWithTarget:self action:@selector(handleGetWindowSize:)],
    [[FBRoute GET:@"/window/rect"] respondWithTarget:self action:@selector(handleGetWindowRect:)],
    [[FBRoute GET:@"/element/:uuid/enabled"] respondWithTarget:self action:@selector(handleGetEnabled:)],
    [[FBRoute GET:@"/element/:uuid/rect"] respondWithTarget:self action:@selector(handleGetRect:)],
    [[FBRoute GET:@"/element/:uuid/attribute/:name"] respondWithTarget:self action:@selector(handleGetAttribute:)],
    [[FBRoute GET:@"/element/:uuid/text"] respondWithTarget:self action:@selector(handleGetText:)],
    [[FBRoute GET:@"/element/:uuid/displayed"] respondWithTarget:self action:@selector(handleGetDisplayed:)],
    [[FBRoute GET:@"/element/:uuid/selected"] respondWithTarget:self action:@selector(handleGetSelected:)],
    [[FBRoute GET:@"/element/:uuid/name"] respondWithTarget:self action:@selector(handleGetName:)],
    [[FBRoute POST:@"/element/:uuid/value"] respondWithTarget:self action:@selector(handleSetValue:)],
    [[FBRoute POST:@"/element/:uuid/clear"] respondWithTarget:self action:@selector(handleClear:)],
    // W3C element screenshot
    [[FBRoute GET:@"/element/:uuid/screenshot"] respondWithTarget:self action:@selector(handleElementScreenshot:)],
    // JSONWP element screenshot
    [[FBRoute GET:@"/screenshot/:uuid"] respondWithTarget:self action:@selector(handleElementScreenshot:)],

    [[FBRoute POST:@"/element/:uuid/click"] respondWithTarget:self action:@selector(handleClick:)],
    [[FBRoute POST:@"/wda/click"] respondWithTarget:self action:@selector(handleClickCoordinate:)],

    [[FBRoute POST:@"/wda/element/:uuid/scroll"] respondWithTarget:self action:@selector(handleScroll:)],
    [[FBRoute POST:@"/wda/scroll"] respondWithTarget:self action:@selector(handleScrollCoordinate:)],

    [[FBRoute POST:@"/wda/element/:uuid/rightClick"] respondWithTarget:self action:@selector(handleRightClick:)],
    [[FBRoute POST:@"/wda/rightClick"] respondWithTarget:self action:@selector(handleRightClickCoordinate:)],

    [[FBRoute POST:@"/wda/element/:uuid/hover"] respondWithTarget:self action:@selector(handleHover:)],
    [[FBRoute POST:@"/wda/hover"] respondWithTarget:self action:@selector(handleHoverCoordinate:)],

    [[FBRoute POST:@"/wda/element/:uuid/doubleClick"] respondWithTarget:self action:@selector(handleDoubleClick:)],
    [[FBRoute POST:@"/wda/doubleClick"] respondWithTarget:self action:@selector(handleDoubleClickCoordinate:)],

    [[FBRoute POST:@"/wda/element/:uuid/clickAndDrag"] respondWithTarget:self action:@selector(handleClickAndDrag:)],
    [[FBRoute POST:@"/wda/clickAndDrag"] respondWithTarget:self action:@selector(handleClickAndDragCoordinate:)],

    [[FBRoute POST:@"/wda/element/:uuid/clickAndDragAndHold"] respondWithTarget:self action:@selector(handleClickAndDragAndHold:)],
    [[FBRoute POST:@"/wda/clickAndDragAndHold"] respondWithTarget:self action:@selector(handleClickAndDragAndHoldCoordinate:)],

    [[FBRoute POST:@"/wda/element/:uuid/swipe"] respondWithTarget:self action:@selector(handleSwipe:)],
    [[FBRoute POST:@"/wda/swipe"] respondWithTarget:self action:@selector(handleSwipeCoordinate:)],

    [[FBRoute POST:@"/wda/element/:uuid/keys"] respondWithTarget:self action:@selector(handleKeys:)],
    [[FBRoute POST:@"/wda/keys"] respondWithTarget:self action:@selector(handleKeys:)],

    // Touch Bar
    [[FBRoute POST:@"/wda/element/:uuid/tap"] respondWithTarget:self action:@selector(handleTap:)],
    [[FBRoute POST:@"/wda/tap"] respondWithTarget:self action:@selector(handleTapCoordinate:)],

    [[FBRoute POST:@"/wda/element/:uuid/doubleTap"] respondWithTarget:self action:@selector(handleDoubleTap:)],
    [[FBRoute POST:@"/wda/doubleTap"] respondWithTarget:self action:@selector(handleDoubleTapCoordinate:)],

    [[FBRoute POST:@"/wda/element/:uuid/press"] respondWithTarget:self action:@selector(handlePress:)],
    [[FBRoute POST:@"/wda/press"] respondWithTarget:self action:@selector(handlePressCoordinate:)],

    [[FBRoute POST:@"/wda/element/:uuid/pressAndDrag"] respondWithTarget:self action:@selector(handlePressAndDrag:)],
    [[FBRoute POST:@"/wda/pressAndDrag"] respondWithTarget:self action:@selector(handlePressAndDragCoordinate:)],

    [[FBRoute POST:@"/wda/element/:uuid/pressAndDragAndHold"] respondWithTarget:self action:@selector(handlePressAndDragAndHold:)],
    [[FBRoute POST:@"/wda/pressAndDragAndHold"] respondWithTarget:self action:@selector(handlePressAndDragAndHold:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleGetEnabled:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  return FBResponseWithObject(@(element.enabled));
}

+ (id<FBResponsePayload>)handleGetRect:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  return FBResponseWithObject(element.am_rect);
}

+ (id<FBResponsePayload>)handleGetAttribute:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  NSString *attributeName = (NSString *)request.parameters[@"name"];
  return FBResponseWithObject([element am_wdAttributeValueWithName:attributeName]);
}

+ (id<FBResponsePayload>)handleGetText:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  return FBResponseWithObject(element.am_text);
}

+ (id<FBResponsePayload>)handleGetDisplayed:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  return FBResponseWithObject(@(element.exists));
}

+ (id<FBResponsePayload>)handleGetName:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  return FBResponseWithObject(element.identifier);
}

+ (id<FBResponsePayload>)handleGetSelected:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  return FBResponseWithObject(@(element.selected));
}

+ (id<FBResponsePayload>)handleSetValue:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  id value = request.arguments[@"value"] ?: request.arguments[@"text"];
  if (!value) {
    return FBResponseWithStatus([FBCommandStatus invalidArgumentErrorWithMessage:@"Neither 'value' nor 'text' parameter is provided"
                                                                       traceback:nil]);
  }
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    [element am_setValue:value];
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleScroll:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  id x = request.arguments[@"x"];
  id y = request.arguments[@"y"];
  CGFloat deltaX = (CGFloat)[request requireDoubleArgumentWithName:@"deltaX"];
  CGFloat deltaY = (CGFloat)[request requireDoubleArgumentWithName:@"deltaY"];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    if (nil != x && nil != y) {
      CGPoint point = CGPointMake((CGFloat)[x doubleValue], (CGFloat)[y doubleValue]);
      XCUICoordinate *coordinate = [element am_coordinateWithPoint:point];
      [coordinate scrollByDeltaX:deltaX deltaY:deltaY];
    } else {
      [element scrollByDeltaX:deltaX deltaY:deltaY];
    }
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleScrollCoordinate:(FBRouteRequest *)request
{
  XCUIApplication *app = request.session.currentApplication;
  CGFloat x = (CGFloat)[request requireDoubleArgumentWithName:@"x"];
  CGFloat y = (CGFloat)[request requireDoubleArgumentWithName:@"y"];
  CGFloat deltaX = (CGFloat)[request requireDoubleArgumentWithName:@"deltaX"];
  CGFloat deltaY = (CGFloat)[request requireDoubleArgumentWithName:@"deltaY"];
  XCUICoordinate *coordinate = [app am_coordinateWithX:x andY:y];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    [coordinate scrollByDeltaX:deltaX deltaY:deltaY];
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleRightClick:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  id x = request.arguments[@"x"];
  id y = request.arguments[@"y"];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    if (x != nil && y != nil) {
      CGPoint point = CGPointMake((CGFloat)[x doubleValue], (CGFloat)[y doubleValue]);
      XCUICoordinate *coordinate = [element am_coordinateWithPoint:point];
      [coordinate rightClick];
    } else {
      [element rightClick];
    }
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleRightClickCoordinate:(FBRouteRequest *)request
{
  XCUIApplication *app = request.session.currentApplication;
  CGFloat x = (CGFloat)[request requireDoubleArgumentWithName:@"x"];
  CGFloat y = (CGFloat)[request requireDoubleArgumentWithName:@"y"];
  XCUICoordinate *coordinate = [app am_coordinateWithX:x andY:y];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    [coordinate rightClick];
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleHover:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  id x = request.arguments[@"x"];
  id y = request.arguments[@"y"];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    if (x != nil && y != nil) {
      CGPoint point = CGPointMake((CGFloat)[x doubleValue], (CGFloat)[y doubleValue]);
      XCUICoordinate *coordinate = [element am_coordinateWithPoint:point];
      [coordinate hover];
    } else {
      [element hover];
    }
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleHoverCoordinate:(FBRouteRequest *)request
{
  XCUIApplication *app = request.session.currentApplication;
  CGFloat x = (CGFloat)[request requireDoubleArgumentWithName:@"x"];
  CGFloat y = (CGFloat)[request requireDoubleArgumentWithName:@"y"];
  XCUICoordinate *coordinate = [app am_coordinateWithX:x andY:y];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    [coordinate hover];
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleClear:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  NSError *error;
  if (![element am_clearTextWithError:&error]) {
    return FBResponseWithStatus([FBCommandStatus invalidElementStateErrorWithMessage:error.description
                                                                           traceback:nil]);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleDoubleClick:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  id x = request.arguments[@"x"];
  id y = request.arguments[@"y"];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    if (nil != x && nil != y) {
      CGPoint point = CGPointMake((CGFloat)[x doubleValue], (CGFloat)[y doubleValue]);
      XCUICoordinate *coordinate = [element am_coordinateWithPoint:point];
      [coordinate doubleClick];
    } else {
      [element doubleClick];
    }
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleDoubleClickCoordinate:(FBRouteRequest *)request
{
  CGPoint point = CGPointMake((CGFloat)[request requireDoubleArgumentWithName:@"x"],
                              (CGFloat)[request requireDoubleArgumentWithName:@"y"]);
  XCUICoordinate *doubleTapCoordinate = [request.session.currentApplication am_coordinateWithPoint:point];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    [doubleTapCoordinate doubleClick];
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleClickAndDrag:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *srcElement = [elementCache elementForUUID:request.elementUuid];
  NSTimeInterval duration = [request requireDoubleArgumentWithName:@"duration"];
  NSDictionary *dest = [request requireDictionaryArgumentWithName:@"dest"];
  XCUIElement *dstElement = [elementCache elementForUUID:(NSString *)FBExtractElement(dest)];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    [srcElement clickForDuration:duration thenDragToElement:dstElement];
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleClickAndDragCoordinate:(FBRouteRequest *)request
{
  XCUIApplication *app = request.session.currentApplication;
  CGFloat startX = (CGFloat)[request requireDoubleArgumentWithName:@"startX"];
  CGFloat startY = (CGFloat)[request requireDoubleArgumentWithName:@"startY"];
  CGFloat endX = (CGFloat)[request requireDoubleArgumentWithName:@"endX"];
  CGFloat endY = (CGFloat)[request requireDoubleArgumentWithName:@"endY"];
  NSTimeInterval duration = [request requireDoubleArgumentWithName:@"duration"];
  XCUICoordinate *start = [app am_coordinateWithX:startX andY:startY];
  XCUICoordinate *end = [app am_coordinateWithX:endX andY:endY];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    [start clickForDuration:duration thenDragToCoordinate:end];
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleClickAndDragAndHold:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *srcElement = [elementCache elementForUUID:request.elementUuid];
  NSTimeInterval duration = [request requireDoubleArgumentWithName:@"duration"];
  NSTimeInterval holdDuration = [request requireDoubleArgumentWithName:@"holdDuration"];
  NSDictionary *dest = [request requireDictionaryArgumentWithName:@"dest"];
  XCUIElement *dstElement = [elementCache elementForUUID:(NSString *)FBExtractElement(dest)];
  id velocityObj = request.arguments[@"velocity"];
  CGFloat velocity = XCUIGestureVelocityDefault;
  if (nil != velocityObj) {
    velocity = (CGFloat)[velocityObj doubleValue];
  }
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    [srcElement clickForDuration:duration
               thenDragToElement:dstElement
                    withVelocity:velocity
             thenHoldForDuration:holdDuration];
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleClickAndDragAndHoldCoordinate:(FBRouteRequest *)request
{
  XCUIApplication *app = request.session.currentApplication;
  CGFloat startX = (CGFloat)[request requireDoubleArgumentWithName:@"startX"];
  CGFloat startY = (CGFloat)[request requireDoubleArgumentWithName:@"startY"];
  CGFloat endX = (CGFloat)[request requireDoubleArgumentWithName:@"endX"];
  CGFloat endY = (CGFloat)[request requireDoubleArgumentWithName:@"endY"];
  NSTimeInterval duration = [request requireDoubleArgumentWithName:@"duration"];
  NSTimeInterval holdDuration = [request requireDoubleArgumentWithName:@"holdDuration"];
  id velocityObj = request.arguments[@"velocity"];
  CGFloat velocity = XCUIGestureVelocityDefault;
  if (nil != velocityObj) {
    velocity = (CGFloat)[velocityObj doubleValue];
  }
  XCUICoordinate *start = [app am_coordinateWithX:startX andY:startY];
  XCUICoordinate *end = [app am_coordinateWithX:endX andY:endY];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    [start clickForDuration:duration
       thenDragToCoordinate:end
               withVelocity:velocity
        thenHoldForDuration:holdDuration];
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleClick:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  id x = request.arguments[@"x"];
  id y = request.arguments[@"y"];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    if (nil != x && nil != y) {
      CGPoint tapPoint = CGPointMake((CGFloat)[x doubleValue], (CGFloat)[y doubleValue]);
      XCUICoordinate *coordinate = [element am_coordinateWithPoint:tapPoint];
      [coordinate click];
    } else {
      [element click];
    }
  }];
  return FBResponseWithOK();
}

+ (NSString *)requireDirectionWithRequest:(FBRouteRequest *)request
{
  NSString *direction = [request requireStringArgumentWithName:@"direction"];
  NSArray<NSString *> *supportedDirections = @[@"up", @"down", @"left", @"right"];
  if (![supportedDirections containsObject:direction.lowercaseString]) {
    NSString *reason = [NSString stringWithFormat: @"Unsupported swipe direction '%@'. Only the following directions are supported: %@", direction, supportedDirections];
    @throw [NSException exceptionWithName:FBInvalidArgumentException
                                   reason:reason
                                 userInfo:@{}];
  }
  return direction;
}

+ (id<FBResponsePayload>)handleSwipe:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  NSString *direction = [self.class requireDirectionWithRequest:request];
  id x = request.arguments[@"x"];
  id y = request.arguments[@"y"];
  __block id<FBResponsePayload> response = nil;
  [self.class excuteRespectingKeyModifiersWithRequest:request block:^void() {
    NSError *error;
    if (nil != x && nil != y) {
      CGPoint swipePoint = CGPointMake((CGFloat)[x doubleValue], (CGFloat)[y doubleValue]);
      XCUICoordinate *coordinate = [element am_coordinateWithPoint:swipePoint];
      if (![coordinate am_swipeWithDirection:direction.lowercaseString
                                    velocity:request.arguments[@"velocity"]
                                       error:&error]) {
        response = FBResponseWithStatus([FBCommandStatus unknownErrorWithMessage:error.description
                                                                       traceback:nil]);
      }
    } else {
      if (![element am_swipeWithDirection:direction.lowercaseString
                                 velocity:request.arguments[@"velocity"]
                                    error:&error]) {
        response = FBResponseWithStatus([FBCommandStatus unknownErrorWithMessage:error.description
                                                                       traceback:nil]);
      }
    }
  }];
  return response ?: FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleSwipeCoordinate:(FBRouteRequest *)request
{
  CGPoint point = CGPointMake((CGFloat)[request requireDoubleArgumentWithName:@"x"],
                              (CGFloat)[request requireDoubleArgumentWithName:@"y"]);
  XCUICoordinate *coordinate = [request.session.currentApplication am_coordinateWithPoint:point];
  NSString *direction = [self.class requireDirectionWithRequest:request];
  __block id<FBResponsePayload> response = nil;
  [self.class excuteRespectingKeyModifiersWithRequest:request block:^void() {
    NSError *error;
    if (![coordinate am_swipeWithDirection:direction.lowercaseString
                                  velocity:request.arguments[@"velocity"]
                                     error:&error]) {
      response = FBResponseWithStatus([FBCommandStatus unknownErrorWithMessage:error.description
                                                                     traceback:nil]);
    }
  }];
  return response ?: FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleClickCoordinate:(FBRouteRequest *)request
{
  CGPoint point = CGPointMake((CGFloat)[request requireDoubleArgumentWithName:@"x"],
                              (CGFloat)[request requireDoubleArgumentWithName:@"y"]);
  XCUICoordinate *coordinate = [request.session.currentApplication am_coordinateWithPoint:point];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    [coordinate click];
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleKeys:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  BOOL hasElement = nil != request.parameters[@"uuid"];
  XCUIElement *destination = hasElement
    ? [elementCache elementForUUID:request.elementUuid]
    : request.session.currentApplication;
  id keys = [request requireArgumentWithName:@"keys"];
  if (![keys isKindOfClass:NSArray.class]) {
    NSString *message = @"The 'keys' argument must be an array";
    return FBResponseWithStatus([FBCommandStatus invalidArgumentErrorWithMessage:message
                                                                       traceback:nil]);
  }
  for (id item in (NSArray *)keys) {
    if ([item isKindOfClass:NSString.class]) {
      NSString *keyValue = AMKeyValueForName(item) ?: item;
      [destination typeKey:keyValue modifierFlags:XCUIKeyModifierNone];
    } else if ([item isKindOfClass:NSDictionary.class]) {
      id key = [(NSDictionary *)item objectForKey:@"key"];
      if (![key isKindOfClass:NSString.class]) {
        NSString *message = [NSString stringWithFormat:@"All dictionaries of 'keys' array must have the 'key' item of type string. Got '%@' instead in the item %@", key, item];
        return FBResponseWithStatus([FBCommandStatus invalidArgumentErrorWithMessage:message
                                                                           traceback:nil]);
      }
      id modifiers = [(NSDictionary *)item objectForKey:@"modifierFlags"];
      NSUInteger modifierFlags = XCUIKeyModifierNone;
      if ([modifiers isKindOfClass:NSNumber.class]) {
        modifierFlags = [(NSNumber *)modifiers unsignedIntValue];
      }
      NSString *keyValue = AMKeyValueForName(key) ?: key;
      [destination typeKey:keyValue modifierFlags:modifierFlags];
    } else {
      NSString *message = @"All items of the 'keys' array must be either dictionaries or strings";
      return FBResponseWithStatus([FBCommandStatus invalidArgumentErrorWithMessage:message
                                                                         traceback:nil]);
    }
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleTap:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  id x = request.arguments[@"x"];
  id y = request.arguments[@"y"];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    if (nil != x && nil != y) {
      CGPoint tapPoint = CGPointMake((CGFloat)[x doubleValue], (CGFloat)[y doubleValue]);
      XCUICoordinate *coordinate = [element am_coordinateWithPoint:tapPoint];
      [coordinate tap];
    } else {
      [element tap];
    }
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleTapCoordinate:(FBRouteRequest *)request
{
  CGPoint point = CGPointMake((CGFloat)[request requireDoubleArgumentWithName:@"x"],
                              (CGFloat)[request requireDoubleArgumentWithName:@"y"]);
  XCUICoordinate *coordinate = [request.session.currentApplication.touchBars.firstMatch am_coordinateWithPoint:point];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    [coordinate tap];
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleDoubleTap:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  id x = request.arguments[@"x"];
  id y = request.arguments[@"y"];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    if (nil != x && nil != y) {
      CGPoint point = CGPointMake((CGFloat)[x doubleValue], (CGFloat)[y doubleValue]);
      XCUICoordinate *coordinate = [element am_coordinateWithPoint:point];
      [coordinate doubleTap];
    } else {
      [element doubleTap];
    }
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleDoubleTapCoordinate:(FBRouteRequest *)request
{
  CGPoint point = CGPointMake((CGFloat)[request requireDoubleArgumentWithName:@"x"],
                              (CGFloat)[request requireDoubleArgumentWithName:@"y"]);
  XCUICoordinate *doubleTapCoordinate = [request.session.currentApplication.touchBars.firstMatch am_coordinateWithPoint:point];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    [doubleTapCoordinate doubleTap];
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handlePress:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  id x = request.arguments[@"x"];
  id y = request.arguments[@"y"];
  NSTimeInterval duration = [request requireDoubleArgumentWithName:@"duration"];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    if (nil != x && nil != y) {
      CGPoint point = CGPointMake((CGFloat)[x doubleValue], (CGFloat)[y doubleValue]);
      XCUICoordinate *coordinate = [element am_coordinateWithPoint:point];
      [coordinate pressForDuration:duration];
    } else {
      [element pressForDuration:duration];
    }
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handlePressCoordinate:(FBRouteRequest *)request
{
  NSTimeInterval duration = [request requireDoubleArgumentWithName:@"duration"];
  CGPoint point = CGPointMake((CGFloat)[request requireDoubleArgumentWithName:@"x"],
                              (CGFloat)[request requireDoubleArgumentWithName:@"y"]);
  XCUICoordinate *coordinate = [request.session.currentApplication.touchBars.firstMatch am_coordinateWithPoint:point];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    [coordinate pressForDuration:duration];
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handlePressAndDrag:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *srcElement = [elementCache elementForUUID:request.elementUuid];
  NSTimeInterval duration = [request requireDoubleArgumentWithName:@"duration"];
  NSDictionary *dest = [request requireDictionaryArgumentWithName:@"dest"];
  XCUIElement *dstElement = [elementCache elementForUUID:(NSString *)FBExtractElement(dest)];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    [srcElement pressForDuration:duration thenDragToElement:dstElement];
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handlePressAndDragCoordinate:(FBRouteRequest *)request
{
  XCUIElement *touchBar = request.session.currentApplication.touchBars.firstMatch;
  CGFloat startX = (CGFloat)[request requireDoubleArgumentWithName:@"startX"];
  CGFloat startY = (CGFloat)[request requireDoubleArgumentWithName:@"startY"];
  CGFloat endX = (CGFloat)[request requireDoubleArgumentWithName:@"endX"];
  CGFloat endY = (CGFloat)[request requireDoubleArgumentWithName:@"endY"];
  NSTimeInterval duration = [request requireDoubleArgumentWithName:@"duration"];
  XCUICoordinate *start = [touchBar am_coordinateWithX:startX andY:startY];
  XCUICoordinate *end = [touchBar am_coordinateWithX:endX andY:endY];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    [start pressForDuration:duration thenDragToCoordinate:end];
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handlePressAndDragAndHold:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *srcElement = [elementCache elementForUUID:request.elementUuid];
  NSTimeInterval duration = [request requireDoubleArgumentWithName:@"duration"];
  NSTimeInterval holdDuration = [request requireDoubleArgumentWithName:@"holdDuration"];
  NSDictionary *dest = [request requireDictionaryArgumentWithName:@"dest"];
  XCUIElement *dstElement = [elementCache elementForUUID:(NSString *)FBExtractElement(dest)];
  id velocityObj = request.arguments[@"velocity"];
  CGFloat velocity = XCUIGestureVelocityDefault;
  if (nil != velocityObj) {
    velocity = (CGFloat)[velocityObj doubleValue];
  }
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    [srcElement pressForDuration:duration
               thenDragToElement:dstElement
                    withVelocity:velocity
             thenHoldForDuration:holdDuration];
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handlePressAndDragAndHoldCoordinate:(FBRouteRequest *)request
{
  XCUIElement *touchBar = request.session.currentApplication.touchBars.firstMatch;
  CGFloat startX = (CGFloat)[request requireDoubleArgumentWithName:@"startX"];
  CGFloat startY = (CGFloat)[request requireDoubleArgumentWithName:@"startY"];
  CGFloat endX = (CGFloat)[request requireDoubleArgumentWithName:@"endX"];
  CGFloat endY = (CGFloat)[request requireDoubleArgumentWithName:@"endY"];
  NSTimeInterval duration = [request requireDoubleArgumentWithName:@"duration"];
  NSTimeInterval holdDuration = [request requireDoubleArgumentWithName:@"holdDuration"];
  id velocityObj = request.arguments[@"velocity"];
  CGFloat velocity = XCUIGestureVelocityDefault;
  if (nil != velocityObj) {
    velocity = (CGFloat)[velocityObj doubleValue];
  }
  XCUICoordinate *start = [touchBar am_coordinateWithX:startX andY:startY];
  XCUICoordinate *end = [touchBar am_coordinateWithX:endX andY:endY];
  [self.class excuteRespectingKeyModifiersWithRequest:request
                                                block:^void() {
    [start pressForDuration:duration
       thenDragToCoordinate:end
               withVelocity:velocity
        thenHoldForDuration:holdDuration];
  }];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleGetWindowSize:(FBRouteRequest *)request
{
  NSDictionary *rect = AMCGRectToDict(request.session.currentApplication.am_screenRect);
  return FBResponseWithObject(@{
    @"width": rect[@"width"],
    @"height": rect[@"height"],
  });
}

+ (id<FBResponsePayload>)handleGetWindowRect:(FBRouteRequest *)request
{
  NSDictionary *rect = AMCGRectToDict(request.session.currentApplication.am_screenRect);
  return FBResponseWithObject(rect);
}

+ (id<FBResponsePayload>)handleElementScreenshot:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.elementUuid];
  NSData *screenshotData = [[element screenshot] PNGRepresentation];
  if (nil == screenshotData) {
    NSString *message = [NSString stringWithFormat:@"Cannot capture the screenshot of '%@'", element.description];
    return FBResponseWithStatus([FBCommandStatus unableToCaptureScreenErrorWithMessage:message
                                                                             traceback:nil]);
  }
  NSString *screenshot = [screenshotData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  return FBResponseWithObject(screenshot);
}

+ (void)excuteRespectingKeyModifiersWithRequest:(FBRouteRequest *)request block:(void(^)(void))block
{
  id arg = request.arguments[@"keyModifierFlags"];
  NSNumber *modifiers = [arg isKindOfClass:NSNumber.class] ? (NSNumber *)arg : nil;
  if (nil == modifiers) {
    block();
  } else {
    [XCUIElement performWithKeyModifiers:modifiers.unsignedIntValue
                                   block:block];
  }
}

@end
