/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * See the NOTICE file distributed with this work for additional
 * information regarding copyright ownership.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const AMWindowErrorDomain;

typedef NS_ENUM(NSInteger, AMWindowErrorCode) {
  /** One of the arguments is invalid */
  AMWindowErrorInvalidArgument = 1,
  /** The window could not be changed, for example because the Accessibility permission is missing */
  AMWindowErrorFailure,
  /** The window does not exist anymore or there is no such window */
  AMWindowErrorNotFound,
};

extern NSString *const AMWindowStateNormal;
extern NSString *const AMWindowStateMinimized;
extern NSString *const AMWindowStateMaximized;
extern NSString *const AMWindowStateFullscreen;

/**
 Inspects and changes application windows. Does not depend on the HTTP layer or sessions.

 Whenever possible, windows are inspected and changed through the accessibility interface of XCTest,
 which does not need the Accessibility permission: the window attributes, the minimized windows,
 minimizing, entering and leaving the fullscreen mode and restoring minimized windows.
 If this is not possible, the Accessibility API is used, which requires the process to be trusted.
 Moving and resizing windows always needs the Accessibility permission.
 */
@interface AMWindowUtils : NSObject

/**
 Whether the XCTest accessibility interface is used (YES by default). If it is turned off, only
 the Accessibility API is used. Intended for tests.
 */
@property (class, nonatomic) BOOL usesUnprivilegedRoutes;

/**
 @returns Windows of the given application
 */
+ (NSArray<XCUIElement *> *)windowsOfApplication:(XCUIApplication *)application;

/**
 @returns The window flagged as main, then the focused one, then the first one. Nil if there are no windows
 */
+ (nullable XCUIElement *)mainWindowOfApplication:(XCUIApplication *)application;

/**
 Describes the window. The result contains:
 title, rect (global coordinates), displayId (the display with the biggest part of the window)
 and the isMain, isFocused, isMinimized, isFullscreen, isMovable, isResizable traits.
 isMovable and isResizable are NSNull if the Accessibility permission is not granted,
 and all the traits are NSNull if the window cannot be read at all.

 @returns The window info or nil if the element does not exist anymore
 */
+ (nullable NSDictionary<NSString *, id> *)infoForWindow:(XCUIElement *)window;

/**
 Changes the state and/or geometry of the window.

 @param window the window element
 @param application the application that owns the window
 @param arguments any of: state (normal, minimized, maximized, fullscreen), x, y, width, height
 and displayId. Coordinates are global, or relative to the display if displayId is set.
 minimized and fullscreen states cannot be combined with the geometry, and maximized can only be
 combined with displayId. The geometry (including maximized) needs the Accessibility permission.
 @param error AMWindowErrorInvalidArgument, AMWindowErrorFailure or AMWindowErrorNotFound
 (the element does not exist anymore, for example because the window has been minimized)
 @returns The updated window info in the infoForWindow: format or nil in case of failure
 */
+ (nullable NSDictionary<NSString *, id> *)adjustWindow:(XCUIElement *)window
                                          inApplication:(XCUIApplication *)application
                                          withArguments:(NSDictionary<NSString *, id> *)arguments
                                                  error:(NSError **)error;

/**
 Same as adjustWindow:inApplication:withArguments:error: for the first minimized window of the application.
 Minimized windows cannot be addressed by elements, because they are not a part of the element hierarchy.

 @returns The updated window info or nil in case of failure. AMWindowErrorNotFound is returned
 if there are no minimized windows
 */
+ (nullable NSDictionary<NSString *, id> *)adjustMinimizedWindowOfApplication:(XCUIApplication *)application
                                                                withArguments:(NSDictionary<NSString *, id> *)arguments
                                                                        error:(NSError **)error;

/**
 @returns The number of minimized windows of the application
 */
+ (NSUInteger)minimizedWindowsCountOfApplication:(XCUIApplication *)application;

@end

NS_ASSUME_NONNULL_END
