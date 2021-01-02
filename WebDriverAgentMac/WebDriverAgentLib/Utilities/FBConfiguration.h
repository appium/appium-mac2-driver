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

+ (instancetype)sharedConfiguration;

/*! Whether to enable remote query evaluation */
@property BOOL remoteQueryEvaluation;

/*! Sets attribute key path analysis, which will cause XCTest on Xcode 9.x to ignore some elements */
@property BOOL attributeKeyPathAnalysis;

/*! Enables XCTest automated screenshots taking */
@property BOOL automaticScreenshots;

/**
 The range of ports that the HTTP Server should attempt to bind on launch
 */
@property (readonly) NSRange bindingPortRange;

/**
 * What interface the server is listening on.
 * nil causes the server to listen on all available interfaces like en1, wifi etc.
 *
 * The interface may be specified by name (e.g. "en1" or "lo0") or by IP address (e.g. "192.168.4.34").
 * You may also use the special strings "localhost" or "loopback" to specify that
 * the socket only accepts connections from the local machine.
 */
@property (readonly, nullable) NSString *serverInterface;

/**
 YES if verbose logging is enabled. NO otherwise.
 */
@property (readonly) BOOL verboseLoggingEnabled;

/**
 * Whether to bound the lookup results by index.
 * By default this is disabled and bounding by accessibility is used.
 * Read https://stackoverflow.com/questions/49307513/meaning-of-allelementsboundbyaccessibilityelement
 * for more details on these two bounding methods.
 */
@property BOOL boundElementsByIndex;

/**
 * Extract switch value from arguments
 *
 * @param arguments Array of strings with the command-line arguments, e.g. @[@"--port", @"12345"].
 * @param key Switch to look up value for, e.g. @"--port".
 *
 * @return Switch value or nil if the switch is not present in arguments.
 */
+ (NSString* _Nullable)valueFromArguments:(NSArray<NSString *> *)arguments forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
