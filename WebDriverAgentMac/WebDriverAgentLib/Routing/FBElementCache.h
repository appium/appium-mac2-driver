/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class XCUIElement;

NS_ASSUME_NONNULL_BEGIN

@interface FBElementCache : NSObject

/**
 Stores the element in cache

 @param element element to store
 @return element's uuid or nil in case the element uid cannnot be extracted
 */
- (NSUUID *)storeElement:(XCUIElement *)element;

/**
 Returns cached element

 @param uuidStr uuid of the element to fetch
 @return element
 @throws FBStaleElementException if the found element is not present in DOM anymore
 @throws FBInvalidArgumentException if uuid is nil
 */
- (XCUIElement *)elementForUUID:(NSString *)uuidStr;

/**
 Verifies presence of an element in cache

 @param uuidStr uuid of the element to check
 @return Either YES or NO
 */
- (BOOL)hasElementWithUUID:(NSString *)uuidStr;

/**
 Deletes all previously cached objects
 */
- (void)reset;

@end

NS_ASSUME_NONNULL_END
