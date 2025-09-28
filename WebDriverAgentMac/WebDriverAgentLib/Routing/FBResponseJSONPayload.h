/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <WebDriverAgentLib/FBResponsePayload.h>
#import <WebDriverAgentLib/FBHTTPStatusCodes.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Class that represents WebDriverAgent JSON response
 */
@interface FBResponseJSONPayload : NSObject <FBResponsePayload>

/**
 Initializer for JSON respond that converts given 'dictionary' to JSON
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary
                    httpStatusCode:(HTTPStatusCode)httpStatusCode;

@end

NS_ASSUME_NONNULL_END
