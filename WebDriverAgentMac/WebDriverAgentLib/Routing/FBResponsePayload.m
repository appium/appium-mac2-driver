/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBResponsePayload.h"

#import "FBElementCache.h"
#import "FBResponseJSONPayload.h"
#import "FBSession.h"
#import "FBConfiguration.h"
#import "FBMacros.h"
#import "FBProtocolHelpers.h"

id<FBResponsePayload> FBResponseWithOK()
{
  return FBResponseWithStatus(FBCommandStatus.ok);
}

id<FBResponsePayload> FBResponseWithObject(id object)
{
  return FBResponseWithStatus([FBCommandStatus okWithValue:object]);
}

id<FBResponsePayload> FBResponseWithCachedElement(XCUIElement *element, FBElementCache *elementCache)
{
  NSString *elementId = [elementCache storeElement:element];
  return FBResponseWithStatus([FBCommandStatus okWithValue:FBInsertElement(@{}, elementId)]);
}

id<FBResponsePayload> FBResponseWithCachedElements(NSArray<XCUIElement *> *elements, FBElementCache *elementCache)
{
  NSMutableArray *elementsResponse = [NSMutableArray array];
  for (XCUIElement *element in elements) {
    NSString *elementId = [elementCache storeElement:element];
    [elementsResponse addObject:FBInsertElement(@{}, elementId)];
  }
  return FBResponseWithStatus([FBCommandStatus okWithValue:elementsResponse]);
}

id<FBResponsePayload> FBResponseWithUnknownError(NSError *error)
{
  return FBResponseWithStatus([FBCommandStatus unknownErrorWithMessage:error.description traceback:nil]);
}

id<FBResponsePayload> FBResponseWithUnknownErrorFormat(NSString *format, ...)
{
  va_list argList;
  va_start(argList, format);
  NSString *errorMessage = [[NSString alloc] initWithFormat:format arguments:argList];
  id<FBResponsePayload> payload = FBResponseWithStatus([FBCommandStatus unknownErrorWithMessage:errorMessage traceback:nil]);
  va_end(argList);
  return payload;
}

id<FBResponsePayload> FBResponseWithStatus(FBCommandStatus *status)
{
  NSMutableDictionary* response = [NSMutableDictionary dictionary];
  response[@"sessionId"] = [FBSession activeSession].identifier ?: NSNull.null;
  if (nil == status.error) {
    response[@"value"] = status.value ?: NSNull.null;
  } else {
    NSMutableDictionary* value = [NSMutableDictionary dictionary];
    value[@"error"] = status.error;
    value[@"message"] = status.message ?: @"";
    value[@"traceback"] = status.traceback ?: @"";
    response[@"value"] = value.copy;
  }

  return [[FBResponseJSONPayload alloc] initWithDictionary:response.copy
                                            httpStatusCode:status.statusCode];
}
