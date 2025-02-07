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

@interface FBScreenRecordingPromise : NSObject

/** Unique identiifier of the video recording, also used as the default file name */
@property (nonatomic, readonly) NSUUID *identifier;
/** Native screen recording promise */
@property (nonatomic, readonly) id nativePromise;

/**
 Creates a wrapper object for a native screen recording promise.
 The actual screen recording file is stored as
 $HOME/Library/Daemon Containers/<testmanagerd_id>Data/Attachments/<recording_id>
 although this path is not is not accessible directly from within the XCTest container,
 and must be accessed from elsewhere.

 @param promise Native promise object to be wrapped
 */
- (instancetype)initWithNativePromise:(id)promise;

@end

NS_ASSUME_NONNULL_END
