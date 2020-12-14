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

#import "XCUIElement+AMCoordinates.h"

#import "FBExceptions.h"
#import "XCUIApplication+AMHelpers.h"

@interface XCUIElementDouble : NSObject
@property (nonatomic) CGRect frame;
@end

@implementation XCUIElementDouble
@end

@interface XCUIElementProxy : NSProxy
@property (nonatomic) NSArray<NSObject *> *targets;

- (instancetype)initWithTargets:(NSArray<NSObject *> *)targets;
@end

@implementation XCUIElementProxy

- (instancetype)initWithTargets:(NSArray<NSObject *> *)targets {
  _targets = targets;
  return self;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
  for (NSObject *target in self.targets) {
    if ([target methodSignatureForSelector:invocation.selector]) {
      [invocation setTarget:target];
      [invocation invoke];
      return;
    }
  }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
  for (NSObject *target in self.targets) {
    NSMethodSignature *signature = [target methodSignatureForSelector:sel];
    if (signature) {
      return signature;
    }
  }
  return [super methodSignatureForSelector:sel];
}

@end


@implementation XCUIElement (AMCoordinates)

- (XCUICoordinate *)am_coordinateWithX:(CGFloat)x andY:(CGFloat)y
{
  CGRect frame = [self isKindOfClass:XCUIApplication.class]
    ? [(XCUIApplication *)self am_screenRect]
    : self.frame;
  XCUICoordinate *result = [self coordinateWithNormalizedOffset:CGVectorMake(x / frame.size.width,
                                                                             y / frame.size.height)];
  if ([self isKindOfClass:XCUIApplication.class]) {
    // This is a hack needed to make absolute coordinates work
    // with the application element. By default XCTest returns zero-sized
    // rectangle for XCUIApplication nodes
    XCUIElementDouble *fakeEl = [XCUIElementDouble new];
    fakeEl.frame = [(XCUIApplication *)self am_screenRect];
    XCUIElementProxy *elementProxy = [[XCUIElementProxy alloc] initWithTargets:@[fakeEl, self]];
    [result setValue:elementProxy forKey:@"_element"];
  }
  CGPoint screenPoint = result.screenPoint;
  if (screenPoint.x == INFINITY || screenPoint.y == INFINITY) {
    NSString *reason = [NSString stringWithFormat:@"Screen coordinates cannot be calculated for '%@'. Consider selecting another element", self.description];
    @throw [NSException exceptionWithName:FBInvalidElementStateException
                                   reason:reason
                                 userInfo:@{}];
  }
  return result;
}

- (XCUICoordinate *)am_coordinateWithPoint:(CGPoint)point
{
  return [self am_coordinateWithX:point.x andY:point.y];
}

@end
