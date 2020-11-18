/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Accessors for Global Constants.
 */
@interface FBConfiguration : NSObject

/*! Disables remote query evaluation making Xcode 9.x tests behave same as Xcode 8.x test */
+ (void)disableRemoteQueryEvaluation;

/*! Disables attribute key path analysis, which will cause XCTest on Xcode 9.x to ignore some elements */
+ (void)disableAttributeKeyPathAnalysis;

/*! Disables XCTest from automated screenshots taking */
+ (void)disableScreenshots;

/**
 * Extract switch value from arguments
 *
 * @param arguments Array of strings with the command-line arguments, e.g. @[@"--port", @"12345"].
 * @param key Switch to look up value for, e.g. @"--port".
 *
 * @return Switch value or nil if the switch is not present in arguments.
 */
+ (NSString* _Nullable)valueFromArguments: (NSArray<NSString *> *)arguments forKey: (NSString*)key;

/**
 The range of ports that the HTTP Server should attempt to bind on launch
 */
+ (NSRange)bindingPortRange;

/**
 YES if verbose logging is enabled. NO otherwise.
 */
+ (BOOL)verboseLoggingEnabled;

/**
 * Whether to use fast search result matching while searching for elements.
 * By default this is disabled due to https://github.com/appium/appium/issues/10101
 * but it still makes sense to enable it for views containing large counts of elements
 *
 * @param enabled Either YES or NO
 */
+ (void)setUseFirstMatch:(BOOL)enabled;
+ (BOOL)useFirstMatch;

/**
 * Whether to bound the lookup results by index.
 * By default this is disabled and bounding by accessibility is used.
 * Read https://stackoverflow.com/questions/49307513/meaning-of-allelementsboundbyaccessibilityelement
 * for more details on these two bounding methods.
 *
 * @param enabled Either YES or NO
 */
+ (void)setBoundElementsByIndex:(BOOL)enabled;
+ (BOOL)boundElementsByIndex;

/**
 Enforces the page hierarchy to include non modal elements,
 like Contacts. By default such elements are not present there.
 See https://github.com/appium/appium/issues/13227

 @param isEnabled Set to YES in order to enable non modal elements inclusion.
 Setting this value to YES will have no effect if the current iOS SDK does not support such feature.
 */
+ (void)setIncludeNonModalElements:(BOOL)isEnabled;
+ (BOOL)includeNonModalElements;

@end

NS_ASSUME_NONNULL_END
