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
#import "XCUIElement+FBTyping.h"

@interface FBElementCommands ()
@end

@implementation FBElementCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/window/size"] respondWithTarget:self action:@selector(handleGetWindowSize:)],
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

    [[FBRoute POST:@"/wda/element/:uuid/clickDragAndHold"] respondWithTarget:self action:@selector(handleClickDragAndHold:)],
    [[FBRoute POST:@"/wda/clickDragAndHold"] respondWithTarget:self action:@selector(handleClickDragAndHoldCoordinate:)],

    [[FBRoute POST:@"/wda/element/:uuid/touchAndHold"] respondWithTarget:self action:@selector(handleTouchAndHold:)],
    [[FBRoute POST:@"/wda/touchAndHold"] respondWithTarget:self action:@selector(handleTouchAndHoldCoordinate:)],

    [[FBRoute POST:@"/wda/keys"] respondWithTarget:self action:@selector(handleKeys:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleGetEnabled:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  return FBResponseWithObject(@(element.enabled));
}

+ (id<FBResponsePayload>)handleGetRect:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  return FBResponseWithObject(AMCGRectToDict(element.frame));
}

+ (id<FBResponsePayload>)handleGetAttribute:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  NSString *attributeName = request.parameters[@"name"];
  NSString *wdAttributeName = [FBElementUtils wdAttributeNameForAttributeName:attributeName];
  if ([wdAttributeName isEqualToString:FBStringify(XCUIElement, frame)]) {
    return FBResponseWithObject(AMCGRectToDict(element.frame));
  } else if ([wdAttributeName isEqualToString:FBStringify(XCUIElement, elementType)]) {
    return FBResponseWithObject([NSString stringWithFormat:@"%lu", element.elementType]);
  } else if ([wdAttributeName isEqualToString:FBStringify(XCUIElement, placeholderValue)]) {
    return FBResponseWithObject(element.placeholderValue);
  } else if ([wdAttributeName isEqualToString:FBStringify(XCUIElement, verticalSizeClass)]) {
    return FBResponseWithObject([NSString stringWithFormat:@"%lu", element.verticalSizeClass]);
  } else if ([wdAttributeName isEqualToString:FBStringify(XCUIElement, horizontalSizeClass)]) {
    return FBResponseWithObject([NSString stringWithFormat:@"%lu", element.horizontalSizeClass]);
  } else if ([wdAttributeName isEqualToString:@"enabled"]) {
    return FBResponseWithObject(element.enabled ? @"true" : @"false");
  } else if ([wdAttributeName isEqualToString:@"selected"]) {
    return FBResponseWithObject(element.selected ? @"true" : @"false");
  } else if ([wdAttributeName isEqualToString:FBStringify(XCUIElement, label)]) {
    return FBResponseWithObject(element.label);
  } else if ([wdAttributeName isEqualToString:FBStringify(XCUIElement, title)]) {
    return FBResponseWithObject(element.title);
  } else if ([wdAttributeName isEqualToString:FBStringify(XCUIElement, value)]) {
    return FBResponseWithObject([FBElementUtils stringValueWithValue:element.value]);
  } else if ([wdAttributeName isEqualToString:FBStringify(XCUIElement, identifier)]) {
    return FBResponseWithObject(element.identifier);
  }
  // This should not happen
  NSString *description = [NSString stringWithFormat:@"The attribute '%@' is unknown", attributeName];
  @throw [NSException exceptionWithName:FBElementAttributeUnknownException
                                 reason:description
                               userInfo:@{}];
}

+ (id<FBResponsePayload>)handleGetText:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  id value = element.value;
  return FBResponseWithObject(nil == value ? element.label : [FBElementUtils stringValueWithValue:value]);
}

+ (id<FBResponsePayload>)handleGetDisplayed:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  return FBResponseWithObject(@(element.exists));
}

+ (id<FBResponsePayload>)handleGetName:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  return FBResponseWithObject([FBElementTypeTransformer stringWithElementType:element.elementType]);
}

+ (id<FBResponsePayload>)handleGetSelected:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  return FBResponseWithObject(@(element.selected));
}

+ (id<FBResponsePayload>)handleSetValue:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  id value = request.arguments[@"value"] ?: request.arguments[@"text"];
  if (!value) {
    return FBResponseWithStatus([FBCommandStatus invalidArgumentErrorWithMessage:@"Neither 'value' nor 'text' parameter is provided"
                                                                       traceback:nil]);
  }
  NSString *textToType = [value isKindOfClass:NSArray.class]
    ? [value componentsJoinedByString:@""]
    : value;
  XCUIElementType elementType = element.elementType;
  if (elementType == XCUIElementTypeSlider) {
    CGFloat sliderValue = textToType.floatValue;
    if (sliderValue < 0.0 || sliderValue > 1.0 ) {
      return FBResponseWithStatus([FBCommandStatus invalidArgumentErrorWithMessage:@"Value of slider should be in 0..1 range"
                                                                         traceback:nil]);
    }
    [element adjustToNormalizedSliderPosition:sliderValue];
    return FBResponseWithOK();
  }
  NSError *error = nil;
  if (![element fb_typeText:textToType
                shouldClear:NO
                      error:&error]) {
    return FBResponseWithStatus([FBCommandStatus invalidElementStateErrorWithMessage:error.description
                                                                           traceback:nil]);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleScroll:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  CGFloat deltaX = (CGFloat)[request.arguments[@"deltaX"] doubleValue];
  CGFloat deltaY = (CGFloat)[request.arguments[@"deltaY"] doubleValue];
  [element scrollByDeltaX:deltaX deltaY:deltaY];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleScrollCoordinate:(FBRouteRequest *)request
{
  XCUIApplication *app = request.session.currentApplication;
  CGFloat x = (CGFloat)[request.arguments[@"x"] doubleValue];
  CGFloat y = (CGFloat)[request.arguments[@"y"] doubleValue];
  CGFloat deltaX = (CGFloat)[request.arguments[@"deltaX"] doubleValue];
  CGFloat deltaY = (CGFloat)[request.arguments[@"deltaY"] doubleValue];
  XCUICoordinate *coordinate = [self.class gestureCoordinateWithCoordinate:CGPointMake(x, y)
                                                                   element:app];
  [coordinate scrollByDeltaX:deltaX deltaY:deltaY];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleRightClick:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  id x = request.arguments[@"x"];
  id y = request.arguments[@"y"];
  if (x != nil && y != nil) {
    CGPoint point = CGPointMake((CGFloat)[x doubleValue], (CGFloat)[y doubleValue]);
    XCUICoordinate *coordinate = [self.class gestureCoordinateWithCoordinate:point
                                                                     element:element];
    [coordinate rightClick];
  } else {
    [element rightClick];
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleRightClickCoordinate:(FBRouteRequest *)request
{
  XCUIApplication *app = request.session.currentApplication;
  CGFloat x = (CGFloat)[request.arguments[@"x"] doubleValue];
  CGFloat y = (CGFloat)[request.arguments[@"y"] doubleValue];
  XCUICoordinate *coordinate = [self.class gestureCoordinateWithCoordinate:CGPointMake(x, y)
                                                                   element:app];
  [coordinate rightClick];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleHover:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  id x = request.arguments[@"x"];
  id y = request.arguments[@"y"];
  if (x != nil && y != nil) {
    CGPoint point = CGPointMake((CGFloat)[x doubleValue], (CGFloat)[y doubleValue]);
    XCUICoordinate *coordinate = [self.class gestureCoordinateWithCoordinate:point
                                                                     element:element];
    [coordinate hover];
  } else {
    [element hover];
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleHoverCoordinate:(FBRouteRequest *)request
{
  XCUIApplication *app = request.session.currentApplication;
  CGFloat x = (CGFloat)[request.arguments[@"x"] doubleValue];
  CGFloat y = (CGFloat)[request.arguments[@"y"] doubleValue];
  XCUICoordinate *coordinate = [self.class gestureCoordinateWithCoordinate:CGPointMake(x, y)
                                                                   element:app];
  [coordinate hover];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleClear:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  NSError *error;
  if (![element fb_clearTextWithError:&error]) {
    return FBResponseWithStatus([FBCommandStatus invalidElementStateErrorWithMessage:error.description traceback:nil]);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleDoubleClick:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  [element doubleClick];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleDoubleClickCoordinate:(FBRouteRequest *)request
{
  CGPoint doubleTapPoint = CGPointMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue]);
  XCUICoordinate *doubleTapCoordinate = [self.class gestureCoordinateWithCoordinate:doubleTapPoint
                                                                            element:request.session.currentApplication];
  [doubleTapCoordinate doubleClick];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleTouchAndHold:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  [element pressForDuration:[request.arguments[@"duration"] doubleValue]];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleTouchAndHoldCoordinate:(FBRouteRequest *)request
{
  CGPoint touchPoint = CGPointMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue]);
  XCUICoordinate *pressCoordinate = [self.class gestureCoordinateWithCoordinate:touchPoint
                                                                        element:request.session.currentApplication];
  [pressCoordinate pressForDuration:[request.arguments[@"duration"] doubleValue]];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleClickAndDrag:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *srcElement = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  NSTimeInterval duration = [request.arguments[@"duration"] doubleValue];
  XCUIElement *dstElement = [elementCache elementForUUID:(NSString *)FBExtractElement(request.arguments[@"dest"])];
  [srcElement clickForDuration:duration thenDragToElement:dstElement];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleClickAndDragCoordinate:(FBRouteRequest *)request
{
  XCUIApplication *app = request.session.currentApplication;
  CGFloat startX = (CGFloat)[request.arguments[@"startX"] doubleValue];
  CGFloat startY = (CGFloat)[request.arguments[@"startY"] doubleValue];
  CGFloat endX = (CGFloat)[request.arguments[@"endX"] doubleValue];
  CGFloat endY = (CGFloat)[request.arguments[@"endY"] doubleValue];
  NSTimeInterval duration = [request.arguments[@"duration"] doubleValue];
  XCUICoordinate *start = [self.class gestureCoordinateWithCoordinate:CGPointMake(startX, startY)
                                                              element:app];
  XCUICoordinate *end = [self.class gestureCoordinateWithCoordinate:CGPointMake(endX, endY)
                                                            element:app];
  [start clickForDuration:duration thenDragToCoordinate:end];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleClickDragAndHold:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *srcElement = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  NSTimeInterval duration = [request.arguments[@"duration"] doubleValue];
  NSTimeInterval holdDuration = [request.arguments[@"holdDuration"] doubleValue];
  XCUIElement *dstElement = [elementCache elementForUUID:(NSString *)FBExtractElement(request.arguments[@"dest"])];
  id velocityObj = request.arguments[@"velocity"];
  CGFloat velocity = XCUIGestureVelocityDefault;
  if (nil != velocityObj) {
    velocity = (CGFloat)[velocityObj doubleValue];
  }
  [srcElement clickForDuration:duration
             thenDragToElement:dstElement
                  withVelocity:velocity
           thenHoldForDuration:holdDuration];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleClickDragAndHoldCoordinate:(FBRouteRequest *)request
{
  XCUIApplication *app = request.session.currentApplication;
  CGFloat startX = (CGFloat)[request.arguments[@"startX"] doubleValue];
  CGFloat startY = (CGFloat)[request.arguments[@"startY"] doubleValue];
  CGFloat endX = (CGFloat)[request.arguments[@"endX"] doubleValue];
  CGFloat endY = (CGFloat)[request.arguments[@"endY"] doubleValue];
  NSTimeInterval duration = [request.arguments[@"duration"] doubleValue];
  NSTimeInterval holdDuration = [request.arguments[@"holdDuration"] doubleValue];
  id velocityObj = request.arguments[@"velocity"];
  CGFloat velocity = XCUIGestureVelocityDefault;
  if (nil != velocityObj) {
    velocity = (CGFloat)[velocityObj doubleValue];
  }
  XCUICoordinate *start = [self.class gestureCoordinateWithCoordinate:CGPointMake(startX, startY)
                                                              element:app];
  XCUICoordinate *end = [self.class gestureCoordinateWithCoordinate:CGPointMake(endX, endY)
                                                            element:app];
  [start clickForDuration:duration
             thenDragToCoordinate:end
             withVelocity:velocity
      thenHoldForDuration:holdDuration];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleDragCoordinate:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  CGPoint startPoint = CGPointMake((CGFloat)[request.arguments[@"fromX"] doubleValue], (CGFloat)[request.arguments[@"fromY"] doubleValue]);
  CGPoint endPoint = CGPointMake((CGFloat)[request.arguments[@"toX"] doubleValue], (CGFloat)[request.arguments[@"toY"] doubleValue]);
  NSTimeInterval duration = [request.arguments[@"duration"] doubleValue];
  XCUICoordinate *endCoordinate = [self.class gestureCoordinateWithCoordinate:endPoint
                                                                      element:session.currentApplication];
  XCUICoordinate *startCoordinate = [self.class gestureCoordinateWithCoordinate:startPoint
                                                                        element:session.currentApplication];
  [startCoordinate pressForDuration:duration thenDragToCoordinate:endCoordinate];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleDrag:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  FBElementCache *elementCache = session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  CGRect frame = element.frame;
  CGPoint startPoint = CGPointMake((CGFloat)(frame.origin.x + [request.arguments[@"fromX"] doubleValue]), (CGFloat)(frame.origin.y + [request.arguments[@"fromY"] doubleValue]));
  CGPoint endPoint = CGPointMake((CGFloat)(frame.origin.x + [request.arguments[@"toX"] doubleValue]), (CGFloat)(frame.origin.y + [request.arguments[@"toY"] doubleValue]));
  NSTimeInterval duration = [request.arguments[@"duration"] doubleValue];
  XCUICoordinate *endCoordinate = [self.class gestureCoordinateWithCoordinate:endPoint
                                                                      element:session.currentApplication];
  XCUICoordinate *startCoordinate = [self.class gestureCoordinateWithCoordinate:startPoint
                                                                        element:session.currentApplication];
  [startCoordinate pressForDuration:duration thenDragToCoordinate:endCoordinate];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleClick:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  id x = request.arguments[@"x"];
  id y = request.arguments[@"y"];
  if (nil != x && nil != y) {
    CGPoint tapPoint = CGPointMake((CGFloat)[x doubleValue], (CGFloat)[y doubleValue]);
    XCUICoordinate *tapCoordinate = [self.class gestureCoordinateWithCoordinate:tapPoint
                                                                        element:element];
    [tapCoordinate click];
  } else {
    [element click];
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleClickCoordinate:(FBRouteRequest *)request
{
  CGPoint tapPoint = CGPointMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue]);
  XCUICoordinate *tapCoordinate = [self.class gestureCoordinateWithCoordinate:tapPoint
                                                                      element:request.session.currentApplication];
  [tapCoordinate click];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleKeys:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  NSString *textToType = [request.arguments[@"value"] componentsJoinedByString:@""];
  [session.currentApplication typeText:textToType];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleGetWindowSize:(FBRouteRequest *)request
{
  NSDictionary *rect = AMCGRectToDict(request.session.currentApplication.frame);
  return FBResponseWithObject(@{
    @"width": rect[@"width"],
    @"height": rect[@"height"],
  });
}

+ (id<FBResponsePayload>)handleElementScreenshot:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  NSData *screenshotData = [[element screenshot] PNGRepresentation];
  if (nil == screenshotData) {
    NSString *message = [NSString stringWithFormat:@"Cannot capture the screenshot of '%@'", element.description];
    return FBResponseWithStatus([FBCommandStatus unableToCaptureScreenErrorWithMessage:message
                                                                             traceback:nil]);
  }
  NSString *screenshot = [screenshotData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  return FBResponseWithObject(screenshot);
}


#pragma mark - Helpers

/**
 Returns gesture coordinate based on the specified element.

 @param coordinate absolute coordinates based on the element
 @param element the element in the current application under test
 @return translated gesture coordinates ready to be passed to XCUICoordinate methods
 */
+ (XCUICoordinate *)gestureCoordinateWithCoordinate:(CGPoint)coordinate element:(XCUIElement *)element
{
  return [element coordinateWithNormalizedOffset:CGVectorMake(coordinate.x, coordinate.y)];
}

@end
