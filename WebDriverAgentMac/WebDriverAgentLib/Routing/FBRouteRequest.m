/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBRouteRequest-Private.h"

#import "FBExceptions.h"

@implementation FBRouteRequest

+ (instancetype)routeRequestWithURL:(NSURL *)URL parameters:(NSDictionary *)parameters arguments:(NSDictionary *)arguments
{
  FBRouteRequest *request = [self.class new];
  request.URL = URL;
  request.parameters = parameters;
  request.arguments = arguments;
  return request;
}

- (NSString *)description
{
  return [NSString stringWithFormat:
    @"Request URL %@ | Params %@ | Arguments %@",
    self.URL,
    self.parameters,
    self.arguments
  ];
}

- (id)requireArgumentWithName:(NSString *)name
{
  id value = self.arguments[name];
  if (nil == value) {
    NSString *reason = [NSString stringWithFormat:@"'%@' argument must be provided", name];
    @throw [NSException exceptionWithName:FBInvalidArgumentException
                                   reason:reason
                                 userInfo:@{}];
  }
  return value;
}

- (double)requireDoubleArgumentWithName:(NSString *)name
{
  id value = [self requireArgumentWithName:name];
  return [value doubleValue];
}

- (NSDictionary *)requireDictionaryArgumentWithName:(NSString *)name
{
  id value = [self requireArgumentWithName:name];
  if (![value isKindOfClass:NSDictionary.class]) {
    NSString *reason = [NSString stringWithFormat:@"'%@' argument must be of dictionary type", name];
    @throw [NSException exceptionWithName:FBInvalidArgumentException
                                   reason:reason
                                 userInfo:@{}];
  }
  return (NSDictionary *)value;
}

- (NSString *)requireStringArgumentWithName:(NSString *)name
{
  id value = [self requireArgumentWithName:name];
  if (![value isKindOfClass:NSString.class]) {
    NSString *reason = [NSString stringWithFormat:@"'%@' argument must be of string type", name];
    @throw [NSException exceptionWithName:FBInvalidArgumentException
                                   reason:reason
                                 userInfo:@{}];
  }
  return (NSString *)value;
}

- (NSString *)elementUuid
{
  return (NSString *)self.parameters[@"uuid"];
}

@end
