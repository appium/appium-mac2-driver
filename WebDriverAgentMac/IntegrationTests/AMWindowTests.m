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

#import "AMIntegrationTestCase.h"
#import "AMScreenUtils.h"
#import "AMSnapshotUtils.h"
#import "AMWindowUtils.h"
#import "AMXCTAccessibility.h"
#import "FBTestMacros.h"

static const CGFloat AM_GEOMETRY_ACCURACY = 1.0;

/**
 The windows are inspected and changed through the XCTest accessibility interface, which does not
 need the Accessibility permission, except for the window geometry. AMWindowAccessibilityApiTests
 runs the same tests using the Accessibility API only.
 */
@interface AMWindowTests : AMIntegrationTestCase
- (BOOL)usesUnprivilegedRoutes;
@end

@implementation AMWindowTests

- (BOOL)usesUnprivilegedRoutes
{
  return YES;
}

- (void)setUp
{
  [super setUp];
  AMWindowUtils.usesUnprivilegedRoutes = [self usesUnprivilegedRoutes];
  [self launchApplication];
}

- (void)tearDown
{
  // Leave the window in a regular state for the other tests
  NSDictionary *normal = @{@"state": AMWindowStateNormal};
  [AMWindowUtils adjustMinimizedWindowOfApplication:self.testedApplication withArguments:normal error:nil];
  XCUIElement *window = [AMWindowUtils mainWindowOfApplication:self.testedApplication];
  if (nil != window) {
    [AMWindowUtils adjustWindow:window inApplication:self.testedApplication withArguments:normal error:nil];
  }
  AMWindowUtils.usesUnprivilegedRoutes = YES;
  [super tearDown];
}

// Changing states needs the XCTest accessibility interface, or the Accessibility permission if it is not used
- (void)skipUnlessStateRoutesAvailable
{
  if ([self usesUnprivilegedRoutes]) {
    XCTSkipUnless(AMXCTAccessibility.isAvailable, @"The XCTest accessibility interface is not available");
  } else {
    [self skipUnlessAccessibilityTrusted];
  }
}

#pragma mark - Helpers

- (XCUIElement *)mainWindow
{
  XCUIElement *window = [AMWindowUtils mainWindowOfApplication:self.testedApplication];
  XCTAssertNotNil(window);
  return window;
}

- (AMScreenProperties *)mainDisplay
{
  for (AMScreenProperties *screen in AMListScreens()) {
    if (screen.isMain) {
      return screen;
    }
  }
  XCTFail(@"No main display is reported");
  return nil;
}

- (NSDictionary<NSString *, id> *)adjustWindow:(XCUIElement *)window arguments:(NSDictionary<NSString *, id> *)arguments
{
  NSError *error = nil;
  NSDictionary *result = [AMWindowUtils adjustWindow:window inApplication:self.testedApplication withArguments:arguments error:&error];
  XCTAssertNotNil(result, @"The call has failed: %@", error);
  return result;
}

- (NSDictionary<NSString *, id> *)adjustMainWindowWithArguments:(NSDictionary<NSString *, id> *)arguments
{
  return [self adjustWindow:[self mainWindow] arguments:arguments];
}

- (void)assertInvalidArgumentWithMessage:(NSString *)fragment forArguments:(NSDictionary<NSString *, id> *)arguments
{
  [self assertInvalidArgumentWithMessage:fragment forArguments:arguments window:[self mainWindow]];
}

- (void)assertInvalidArgumentWithMessage:(NSString *)fragment
                            forArguments:(NSDictionary<NSString *, id> *)arguments
                                  window:(XCUIElement *)window
{
  NSError *error = nil;
  XCTAssertNil([AMWindowUtils adjustWindow:window inApplication:self.testedApplication withArguments:arguments error:&error]);
  XCTAssertEqualObjects(error.domain, AMWindowErrorDomain);
  XCTAssertEqual(error.code, AMWindowErrorInvalidArgument);
  XCTAssertTrue([error.localizedDescription containsString:fragment], @"Unexpected message: %@", error.localizedDescription);
}

- (CGRect)rectFromInfo:(NSDictionary<NSString *, id> *)info
{
  NSDictionary<NSString *, NSNumber *> *rect = info[@"rect"];
  return CGRectMake(rect[@"x"].doubleValue, rect[@"y"].doubleValue, rect[@"width"].doubleValue, rect[@"height"].doubleValue);
}

- (void)assertRect:(CGRect)actual equalsRect:(CGRect)expected
{
  XCTAssertEqualWithAccuracy(actual.origin.x, expected.origin.x, AM_GEOMETRY_ACCURACY);
  XCTAssertEqualWithAccuracy(actual.origin.y, expected.origin.y, AM_GEOMETRY_ACCURACY);
  XCTAssertEqualWithAccuracy(actual.size.width, expected.size.width, AM_GEOMETRY_ACCURACY);
  XCTAssertEqualWithAccuracy(actual.size.height, expected.size.height, AM_GEOMETRY_ACCURACY);
}

- (void)assertRect:(CGRect)rect isWithinRect:(CGRect)container
{
  XCTAssertTrue(CGRectContainsRect(CGRectInset(container, -AM_GEOMETRY_ACCURACY, -AM_GEOMETRY_ACCURACY), rect),
                @"%@ is not within %@", NSStringFromRect(rect), NSStringFromRect(container));
}

#pragma mark - Displays

- (void)testDisplaysReportTheirBounds
{
  AMScreenProperties *display = [self mainDisplay];
  XCTAssertTrue(display.bounds.size.width > 0 && display.bounds.size.height > 0);
  // The main display is the origin of the global coordinate space
  XCTAssertEqualWithAccuracy(display.bounds.origin.x, 0, AM_GEOMETRY_ACCURACY);
  XCTAssertEqualWithAccuracy(display.bounds.origin.y, 0, AM_GEOMETRY_ACCURACY);
  // The menu bar and the Dock are excluded
  [self assertRect:display.visibleBounds isWithinRect:display.bounds];
}

#pragma mark - Listing

- (void)testWindowsAreListed
{
  NSArray<XCUIElement *> *windows = [AMWindowUtils windowsOfApplication:self.testedApplication];
  XCTAssertTrue(windows.count > 0);
  NSDictionary *info = [AMWindowUtils infoForWindow:windows.firstObject];
  XCTAssertNotNil(info[@"title"]);
  CGRect rect = [self rectFromInfo:info];
  XCTAssertTrue(rect.size.width > 0 && rect.size.height > 0);
  XCTAssertEqualObjects(info[@"displayId"], @([self mainDisplay].identifier));
}

- (void)testWindowTraitsAreListed
{
  [self skipUnlessStateRoutesAvailable];

  NSDictionary *info = [AMWindowUtils infoForWindow:[self mainWindow]];
  for (NSString *trait in @[@"isMain", @"isFocused", @"isMinimized", @"isFullscreen"]) {
    XCTAssertTrue([info[trait] isKindOfClass:NSNumber.class], @"'%@' must be a boolean: %@", trait, info);
  }
  XCTAssertTrue([info[@"isMain"] boolValue]);
  XCTAssertFalse([info[@"isMinimized"] boolValue]);
  XCTAssertFalse([info[@"isFullscreen"] boolValue]);
  // These can only be asked through the Accessibility API
  if (AMSnapshotUtils.isAccessibilityTrusted) {
    XCTAssertTrue([info[@"isMovable"] boolValue]);
    XCTAssertTrue([info[@"isResizable"] boolValue]);
  } else {
    XCTAssertEqualObjects(info[@"isMovable"], NSNull.null);
    XCTAssertEqualObjects(info[@"isResizable"], NSNull.null);
  }
}

#pragma mark - Argument validation

- (void)testAdjustingRequiresAtLeastOneArgument
{
  [self assertInvalidArgumentWithMessage:@"At least one of" forArguments:@{}];
  [self assertInvalidArgumentWithMessage:@"At least one of" forArguments:@{@"windowId": @"foo"}];
}

- (void)testAdjustingRejectsUnknownState
{
  [self assertInvalidArgumentWithMessage:@"'state' must be one of" forArguments:@{@"state": @"foo"}];
}

- (void)testAdjustingRejectsInvalidGeometry
{
  [self assertInvalidArgumentWithMessage:@"'width'" forArguments:@{@"width": @0}];
  [self assertInvalidArgumentWithMessage:@"'height'" forArguments:@{@"height": @(-10)}];
  [self assertInvalidArgumentWithMessage:@"'x'" forArguments:@{@"x": @"foo"}];
}

- (void)testAdjustingRejectsStateCombinedWithGeometry
{
  [self assertInvalidArgumentWithMessage:@"cannot be combined"
                            forArguments:@{@"state": AMWindowStateMinimized, @"x": @10}];
  [self assertInvalidArgumentWithMessage:@"cannot be combined"
                            forArguments:@{@"state": AMWindowStateFullscreen, @"displayId": @([self mainDisplay].identifier)}];
  [self assertInvalidArgumentWithMessage:@"cannot be combined"
                            forArguments:@{@"state": AMWindowStateMaximized, @"width": @500}];
}

- (void)testAdjustingRejectsUnknownDisplay
{
  [self assertInvalidArgumentWithMessage:@"is unknown" forArguments:@{@"displayId": @999999}];
}

- (void)testAdjustingRejectsMalformedDisplayId
{
  [self assertInvalidArgumentWithMessage:@"'displayId' must be a number" forArguments:@{@"displayId": @{}}];
  [self assertInvalidArgumentWithMessage:@"'displayId' must be a number" forArguments:@{@"displayId": @"foo"}];
}

- (void)testAdjustingRejectsNonWindowElements
{
  XCUIElement *button = self.testedApplication.buttons.firstMatch;
  XCTAssertTrue([button waitForExistenceWithTimeout:5.0]);
  [self assertInvalidArgumentWithMessage:@"is not a window" forArguments:@{@"x": @10} window:button];
}

#pragma mark - Adjusting (requires the Accessibility permission)

- (void)testWindowCanBeResizedAndMoved
{
  [self skipUnlessAccessibilityTrusted];

  XCUIElement *window = [self mainWindow];
  CGRect original = [self rectFromInfo:[AMWindowUtils infoForWindow:window]];
  CGRect expected = CGRectMake(original.origin.x + 30, original.origin.y + 30,
                               original.size.width + 20, original.size.height + 20);
  NSDictionary *result = [self adjustWindow:window arguments:@{
    @"x": @(expected.origin.x),
    @"y": @(expected.origin.y),
    @"width": @(expected.size.width),
    @"height": @(expected.size.height),
  }];
  [self assertRect:[self rectFromInfo:result] equalsRect:expected];
  // The change is observable from the outside
  [self assertRect:[self rectFromInfo:[AMWindowUtils infoForWindow:window]] equalsRect:expected];
  [self assertRect:window.frame equalsRect:expected];
}

- (void)testOmittedGeometryIsKept
{
  [self skipUnlessAccessibilityTrusted];

  XCUIElement *window = [self mainWindow];
  CGRect original = [self rectFromInfo:[AMWindowUtils infoForWindow:window]];
  NSDictionary *result = [self adjustWindow:window arguments:@{@"width": @(original.size.width + 20)}];
  [self assertRect:[self rectFromInfo:result]
        equalsRect:CGRectMake(original.origin.x, original.origin.y, original.size.width + 20, original.size.height)];
}

- (void)testWindowCanBeMovedToDisplay
{
  [self skipUnlessAccessibilityTrusted];

  AMScreenProperties *display = [self mainDisplay];
  NSDictionary *result = [self adjustMainWindowWithArguments:@{
    @"displayId": @(display.identifier),
    @"x": @80,
    @"y": @120,
  }];
  CGRect rect = [self rectFromInfo:result];
  // Coordinates are relative to the display
  XCTAssertEqualWithAccuracy(rect.origin.x, display.bounds.origin.x + 80, AM_GEOMETRY_ACCURACY);
  XCTAssertEqualWithAccuracy(rect.origin.y, display.bounds.origin.y + 120, AM_GEOMETRY_ACCURACY);
  XCTAssertEqualObjects(result[@"displayId"], @(display.identifier));
}

- (void)testWindowIsKeptWithinDisplay
{
  [self skipUnlessAccessibilityTrusted];

  AMScreenProperties *display = [self mainDisplay];
  NSDictionary *result = [self adjustMainWindowWithArguments:@{
    @"displayId": @(display.identifier),
    @"x": @(display.bounds.size.width * 10),
    @"y": @(display.bounds.size.height * 10),
  }];
  [self assertRect:[self rectFromInfo:result] isWithinRect:display.bounds];
}

- (void)testWindowCanBeMaximized
{
  [self skipUnlessAccessibilityTrusted];

  AMScreenProperties *display = [self mainDisplay];
  CGRect original = [self rectFromInfo:[AMWindowUtils infoForWindow:[self mainWindow]]];
  CGRect rect = [self rectFromInfo:[self adjustMainWindowWithArguments:@{@"state": AMWindowStateMaximized}]];
  XCTAssertTrue(rect.size.width * rect.size.height >= original.size.width * original.size.height,
                @"%@ must not be smaller than %@", NSStringFromRect(rect), NSStringFromRect(original));
  // Fills the display, except the menu bar and the Dock
  [self assertRect:rect isWithinRect:display.bounds];
  XCTAssertTrue(rect.size.width >= display.visibleBounds.size.width - AM_GEOMETRY_ACCURACY);

  // Maximizing is idempotent
  NSDictionary *repeated = [self adjustMainWindowWithArguments:@{@"state": AMWindowStateMaximized}];
  [self assertRect:[self rectFromInfo:repeated] equalsRect:rect];
}

- (void)testWindowCanBeMinimizedAndRestored
{
  [self skipUnlessStateRoutesAvailable];

  XCUIApplication *application = self.testedApplication;
  CGRect original = [self rectFromInfo:[AMWindowUtils infoForWindow:[self mainWindow]]];
  NSDictionary *minimized = [self adjustMainWindowWithArguments:@{@"state": AMWindowStateMinimized}];
  XCTAssertEqualObjects(minimized[@"isMinimized"], @YES);
  FBAssertWaitTillBecomesTrue(1 == [AMWindowUtils minimizedWindowsCountOfApplication:application]);

  // Minimized windows are not a part of the element hierarchy
  NSError *error = nil;
  NSDictionary *restored = [AMWindowUtils adjustMinimizedWindowOfApplication:application
                                                               withArguments:@{@"state": AMWindowStateNormal}
                                                                       error:&error];
  XCTAssertNotNil(restored, @"The call has failed: %@", error);
  XCTAssertEqualObjects(restored[@"isMinimized"], @NO);
  [self assertRect:[self rectFromInfo:restored] equalsRect:original];
  FBAssertWaitTillBecomesTrue(0 == [AMWindowUtils minimizedWindowsCountOfApplication:application]);
  FBAssertWaitTillBecomesTrue(nil != [AMWindowUtils mainWindowOfApplication:application]);
}

- (void)testMinimizedWindowIsRestoredByGeometryChange
{
  [self skipUnlessAccessibilityTrusted];

  XCUIApplication *application = self.testedApplication;
  CGRect original = [self rectFromInfo:[AMWindowUtils infoForWindow:[self mainWindow]]];
  [self adjustMainWindowWithArguments:@{@"state": AMWindowStateMinimized}];
  FBAssertWaitTillBecomesTrue(1 == [AMWindowUtils minimizedWindowsCountOfApplication:application]);

  NSError *error = nil;
  NSDictionary *result = [AMWindowUtils adjustMinimizedWindowOfApplication:application
                                                             withArguments:@{@"width": @(original.size.width + 10)}
                                                                     error:&error];
  XCTAssertNotNil(result, @"The call has failed: %@", error);
  XCTAssertEqualObjects(result[@"isMinimized"], @NO);
  XCTAssertEqualWithAccuracy([self rectFromInfo:result].size.width, original.size.width + 10, AM_GEOMETRY_ACCURACY);
}

- (void)testRestoringRequiresMinimizedWindow
{
  [self skipUnlessStateRoutesAvailable];

  NSError *error = nil;
  XCTAssertNil([AMWindowUtils adjustMinimizedWindowOfApplication:self.testedApplication
                                                   withArguments:@{@"state": AMWindowStateNormal}
                                                           error:&error]);
  XCTAssertEqual(error.code, AMWindowErrorNotFound);
}

- (void)testGeometryRequiresAccessibilityPermission
{
  XCTSkipIf(AMSnapshotUtils.isAccessibilityTrusted, @"The process is trusted for the Accessibility API");

  NSError *error = nil;
  XCTAssertNil([AMWindowUtils adjustWindow:[self mainWindow]
                             inApplication:self.testedApplication
                             withArguments:@{@"width": @600}
                                     error:&error]);
  XCTAssertEqual(error.code, AMWindowErrorFailure);
  XCTAssertTrue([error.localizedDescription containsString:@"Accessibility"], @"%@", error.localizedDescription);
}

- (void)testWindowCanEnterAndLeaveFullscreen
{
  [self skipUnlessStateRoutesAvailable];

  XCUIElement *window = [self mainWindow];
  NSDictionary *fullscreen = [self adjustWindow:window arguments:@{@"state": AMWindowStateFullscreen}];
  XCTAssertEqualObjects(fullscreen[@"isFullscreen"], @YES);

  NSDictionary *restored = [self adjustWindow:window arguments:@{@"state": AMWindowStateNormal}];
  XCTAssertEqualObjects(restored[@"isFullscreen"], @NO);
}

- (void)testFullscreenWindowCanBeMinimized
{
  [self skipUnlessStateRoutesAvailable];

  XCUIApplication *application = self.testedApplication;
  XCUIElement *window = [self mainWindow];
  NSDictionary *fullscreen = [self adjustWindow:window arguments:@{@"state": AMWindowStateFullscreen}];
  XCTAssertEqualObjects(fullscreen[@"isFullscreen"], @YES);

  NSDictionary *minimized = [self adjustWindow:window arguments:@{@"state": AMWindowStateMinimized}];
  XCTAssertEqualObjects(minimized[@"isMinimized"], @YES);
  XCTAssertEqualObjects(minimized[@"isFullscreen"], @NO);

  NSError *error = nil;
  XCTAssertNotNil([AMWindowUtils adjustMinimizedWindowOfApplication:application
                                                      withArguments:@{@"state": AMWindowStateNormal}
                                                              error:&error], @"The call has failed: %@", error);
  FBAssertWaitTillBecomesTrue(nil != [AMWindowUtils mainWindowOfApplication:application]);
}

@end

@interface AMWindowAccessibilityApiTests : AMWindowTests
@end

@implementation AMWindowAccessibilityApiTests

- (BOOL)usesUnprivilegedRoutes
{
  return NO;
}

@end
