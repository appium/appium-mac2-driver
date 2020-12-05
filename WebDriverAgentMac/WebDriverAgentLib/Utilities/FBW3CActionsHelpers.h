/**
* Copyright (c) 2015-present, Facebook, Inc.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

#import <XCTest/XCTest.h>

extern NSUInteger const AM_LEFT_BUTTON_CODE;
extern NSUInteger const AM_RIGHT_BUTTON_CODE;

NS_ASSUME_NONNULL_BEGIN

/**
 * Extracts value property for a key action
 *
 * @param actionItem Action item dictionary
 * @param error Contains the acttual error in case of failure
 * @returns Either the extracted value or nil in case of failure
 */
NSString *_Nullable FBRequireValue(NSDictionary<NSString *, id> *actionItem, NSError **error);

/**
 * Extracts duration property for an action
 *
 * @param actionItem Action item dictionary
 * @param defaultValue The default duration value if it is not present. If nil then the error will be set
 * @param error Contains the acttual error in case of failure
 * @returns Either the extracted value or nil in case of failure
 */
NSNumber *_Nullable FBOptDuration(NSDictionary<NSString *, id> *actionItem, NSNumber *_Nullable defaultValue, NSError **error);

/**
 * Checks whether the given key action value is a W3C meta modifier
 * @param value key action value
 * @returns YES if the value is a meta modifier
 */
BOOL FBIsMetaModifier(NSString *value);

/**
 * Maps W3C meta modifier to XCTest compatible-one
 *
 * @param value key action value
 * @param reverse whether to reverse the modifier value, so it cancels the previusly set one
 * @returns the mapped modifier value or 0 in case of failure
 */
NSUInteger FBToMetaModifier(NSString *value, BOOL reverse);

/**
 * Maps W3C button code to a XCTest compatible-one
 *
 * @param w3cButtonCode W3C button code
 * @returns The corresponding XCTest button code or the LEFT button code if nothing matched
 */
NSUInteger AMToXCTestButtonCode(NSUInteger w3cButtonCode);

NS_ASSUME_NONNULL_END
