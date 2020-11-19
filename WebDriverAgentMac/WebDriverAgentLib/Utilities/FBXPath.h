/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBXPath : NSObject

/**
 Returns an array of descendants matching given xpath query
 
 @param root the root element to execute XPath query for
 @param xpathQuery requested xpath query
 @param firstMatch whether to only resulve the first matched element (if YES) or all of them
 @return an array of descendants matching the given xpath query or an empty array if no matches were found
 @throws NSException if there is an unexpected internal error during xml parsing
 */
+ (NSArray<XCUIElement *> *)matchesWithRootElement:(XCUIElement *)root
                                          forQuery:(NSString *)xpathQuery
                             includeOnlyFirstMatch:(BOOL)firstMatch;

/**
 Gets XML representation of an element with all its descendants. This method generates the same
 representation, which is used for XPath search
 
 @param root the root element
 @return valid XML document as string or nil in case of failure
 */
+ (nullable NSString *)xmlStringWithRootElement:(XCUIElement *)root;

@end

NS_ASSUME_NONNULL_END
