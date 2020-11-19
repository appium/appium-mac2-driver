/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBFindElementCommands.h"

#import "FBConfiguration.h"
#import "FBElementCache.h"
#import "FBExceptions.h"
#import "FBMacros.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "XCUIApplication+AMActiveElement.h"
#import "XCUIElement+FBClassChain.h"
#import "XCUIElement+FBFind.h"

static id<FBResponsePayload> FBNoSuchElementErrorResponseForRequest(FBRouteRequest *request)
{
  return FBResponseWithStatus([FBCommandStatus noSuchElementErrorWithMessage:[NSString stringWithFormat:@"unable to find an element using '%@', value '%@'", request.arguments[@"using"], request.arguments[@"value"]]
                                                                   traceback:[NSString stringWithFormat:@"%@", NSThread.callStackSymbols]]);
}

@implementation FBFindElementCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute POST:@"/element"] respondWithTarget:self action:@selector(handleFindElement:)],
    [[FBRoute POST:@"/elements"] respondWithTarget:self action:@selector(handleFindElements:)],
    [[FBRoute POST:@"/element/:uuid/element"] respondWithTarget:self action:@selector(handleFindSubElement:)],
    [[FBRoute POST:@"/element/:uuid/elements"] respondWithTarget:self action:@selector(handleFindSubElements:)],
    [[FBRoute GET:@"/element/active"] respondWithTarget:self action:@selector(handleGetActiveElement:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleFindElement:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  XCUIElement *element = [self.class elementUsing:request.arguments[@"using"]
                                        withValue:request.arguments[@"value"]
                                            under:session.currentApplication];
  return nil == element
    ? FBNoSuchElementErrorResponseForRequest(request)
    : FBResponseWithCachedElement(element, request.session.elementCache);
}

+ (id<FBResponsePayload>)handleFindElements:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  NSArray *elements = [self.class elementsUsing:request.arguments[@"using"]
                                      withValue:request.arguments[@"value"]
                                          under:session.currentApplication
                    shouldReturnAfterFirstMatch:NO];
  return FBResponseWithCachedElements(elements, request.session.elementCache);
}

+ (id<FBResponsePayload>)handleFindSubElement:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  XCUIElement *foundElement = [self.class elementUsing:request.arguments[@"using"]
                                             withValue:request.arguments[@"value"]
                                                 under:element];
  return nil == foundElement
    ? FBNoSuchElementErrorResponseForRequest(request)
    : FBResponseWithCachedElement(foundElement, request.session.elementCache);
}

+ (id<FBResponsePayload>)handleFindSubElements:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:(NSString *)request.parameters[@"uuid"]];
  NSArray *foundElements = [self.class elementsUsing:request.arguments[@"using"]
                                           withValue:request.arguments[@"value"]
                                               under:element
                         shouldReturnAfterFirstMatch:NO];
  return FBResponseWithCachedElements(foundElements, request.session.elementCache);
}

+ (id<FBResponsePayload>)handleGetActiveElement:(FBRouteRequest *)request
{
  XCUIElement *element = request.session.currentApplication.am_activeElement;
  return nil == element
    ? FBNoSuchElementErrorResponseForRequest(request)
    : FBResponseWithCachedElement(element, request.session.elementCache);
}

#pragma mark - Helpers

+ (XCUIElement *)elementUsing:(NSString *)usingText withValue:(NSString *)value under:(XCUIElement *)element
{
  return [[self elementsUsing:usingText
                    withValue:value
                        under:element
  shouldReturnAfterFirstMatch:YES] firstObject];
}

+ (NSArray *)elementsUsing:(NSString *)usingText
                 withValue:(NSString *)value
                     under:(XCUIElement *)element
shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  if ([usingText isEqualToString:@"class name"]) {
    return [element fb_descendantsMatchingClassName:value
                        shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch];
  } else if ([usingText isEqualToString:@"class chain"]) {
    return [element fb_descendantsMatchingClassChain:value
                         shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch];
  } else if ([usingText isEqualToString:@"xpath"]) {
    return [element fb_descendantsMatchingXPathQuery:value
                         shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch];
  } else if ([usingText isEqualToString:@"predicate string"]) {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:value];
    return [element fb_descendantsMatchingPredicate:predicate
                        shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch];
  } else if ([usingText isEqualToString:@"name"]
             || [usingText isEqualToString:@"id"]
             || [usingText isEqualToString:@"accessibility id"]) {
    return [element fb_descendantsMatchingIdentifier:value
                         shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch];
  } else {
    @throw [NSException exceptionWithName:FBElementAttributeUnknownException
                                   reason:[NSString stringWithFormat:@"Invalid locator requested: %@", usingText]
                                 userInfo:nil];
  }
}

@end

