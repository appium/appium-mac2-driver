/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class FBSession;

NS_ASSUME_NONNULL_BEGIN

/**
 Class that represents WebDriverAgent command request
 */
@interface FBRouteRequest : NSObject

/*! Request's URL */
@property (nonatomic, strong, readonly) NSURL *URL;

/*! Parameters sent with that request */
@property (nonatomic, copy, readonly) NSDictionary *parameters;

/*! Arguments sent with that request */
@property (nonatomic, copy, readonly) NSDictionary *arguments;

/*! Session associated with that request */
@property (nonatomic, strong, readonly) FBSession *session;

/**
 Convenience constructor for request
 */
+ (instancetype)routeRequestWithURL:(NSURL *)URL parameters:(NSDictionary *)parameters arguments:(NSDictionary *)arguments;

/**
 Retrieves request JSON body argument with the given name

 @param name the argument name
 @returns the argument value
 @throws FBInvalidArgumentException if the argument is not provided
 */
- (id)requireArgumentWithName:(NSString *)name;

/**
 Retrieves request JSON body argument with the given name and converts its value to double

 @param name the argument name
 @returns the argument value as double number
 @throws FBInvalidArgumentException if the argument is not provided
 */
- (double)requireDoubleArgumentWithName:(NSString *)name;

/**
 Retrieves request JSON body argument with the given name and converts its value to a dictionary

 @param name the argument name
 @returns the argument value as dictionary
 @throws FBInvalidArgumentException if the argument is not provided or is not of dictionary type
 */
- (NSDictionary *)requireDictionaryArgumentWithName:(NSString *)name;

/**
 Retrieves request JSON body argument with the given name and converts its value to a string

 @param name the argument name
 @returns the argument value as string
 @throws FBInvalidArgumentException if the argument is not provided or is not of string type
 */
- (NSString *)requireStringArgumentWithName:(NSString *)name;

/**
 Retrieves :uuid parameter value from the request URL

 @returns :uuid parameter value
 */
- (NSString *)elementUuid;

@end

NS_ASSUME_NONNULL_END
