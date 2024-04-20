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

#import "AMXCUIDeviceWrapper.h"

#import "FBErrorBuilder.h"
#import "FBRunLoopSpinner.h"
#import "XCSynthesizedEventRecord.h"
#import "XCUIEventSynthesizing-Protocol.h"

#define MAX_ACTIONS_DURATION_SEC 300

@implementation AMXCUIDeviceWrapper

+ (instancetype)sharedDevice;
{
  static AMXCUIDeviceWrapper *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (id)xcuiDeviceInstance
{
  return [NSClassFromString(@"XCUIDevice") valueForKey:@"sharedDevice"];
}

- (BOOL)supportsOpenUrl
{
  id<XCUIApplicationProcessManaging> platformApplicationManager = [self platformApplicationManager];
  return nil != platformApplicationManager
    && [(NSObject *)platformApplicationManager respondsToSelector:@selector(openDefaultApplicationForURL:completion:)];
}

- (id<XCUIApplicationProcessManaging>)platformApplicationManager
{
  return [self.xcuiDeviceInstance valueForKey:@"platformApplicationManager"];
}

- (id<XCUIEventSynthesizing>)eventSynthesizer
{
  return [self.xcuiDeviceInstance valueForKey:@"eventSynthesizer"];
}

- (BOOL)openUrl:(NSURL *)url error:(NSError **)error
{
  id<XCUIApplicationProcessManaging> platformApplicationManager = [self platformApplicationManager];
  if (nil == platformApplicationManager 
      || ![(NSObject *)platformApplicationManager respondsToSelector:@selector(openDefaultApplicationForURL:completion:)]) {
    NSString *description = [NSString stringWithFormat:@"Cannot open '%@' with the default application assigned for it. Consider upgrading to Xcode 14.3+", url];
    return [[[FBErrorBuilder builder]
             withDescriptionFormat:@"%@", description]
            buildError:error];;
  }

  __block NSError *innerError = nil;
  __block BOOL didSucceed = NO;
  [FBRunLoopSpinner spinUntilCompletion:^(void(^completion)(void)){
    [platformApplicationManager openDefaultApplicationForURL:url 
                                                  completion:^(bool result, NSError *invokeError) {
      if (nil != invokeError) {
        innerError = invokeError;
      } else {
        didSucceed = result;
      }
      completion();
    }];
  }];
  if (nil != innerError && error) {
    *error = innerError;
  }
  return didSucceed;
}

- (BOOL)openUrl:(NSURL *)url
withApplication:(NSString *)bundleId
          error:(NSError **)error
{
  id<XCUIApplicationProcessManaging> platformApplicationManager = [self platformApplicationManager];
  if (nil == platformApplicationManager 
      || ![(NSObject *)platformApplicationManager respondsToSelector:@selector(openURL:usingApplication:completion:)]) {
    NSString *description = [NSString stringWithFormat:@"Cannot open '%@' with the default application assigned for it. Consider upgrading to Xcode 14.3+", url];
    return [[[FBErrorBuilder builder]
             withDescriptionFormat:@"%@", description]
            buildError:error];;
  }

  __block NSError *innerError = nil;
  __block BOOL didSucceed = NO;
  [FBRunLoopSpinner spinUntilCompletion:^(void(^completion)(void)){
    [platformApplicationManager openURL:(NSURL *)url 
                       usingApplication:bundleId
                             completion:^(bool result, NSError *invokeError) {
      if (nil != invokeError) {
        innerError = invokeError;
      } else {
        didSucceed = result;
      }
      completion();
    }];
  }];
  if (nil != innerError && error) {
    *error = innerError;
  }
  return didSucceed;
}

- (BOOL)synthesizeEvent:(XCSynthesizedEventRecord *)event
                  error:(NSError **)error
{
  __block NSError *internalError = nil;
  dispatch_semaphore_t sem = dispatch_semaphore_create(0);
  id<XCUIEventSynthesizing> eventSynthesizer = [self eventSynthesizer];
  [eventSynthesizer synthesizeEvent:event
                         completion:(id)^(BOOL result, NSError *invokeError) {
    if (!result) {
      internalError = invokeError;
    }
    dispatch_semaphore_signal(sem);
  }];
  BOOL didTimeout = 0 != dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MAX_ACTIONS_DURATION_SEC * NSEC_PER_SEC)));
  if (didTimeout) {
    return [[[FBErrorBuilder builder]
             withDescriptionFormat:@"Cannot perform actions within %@ seconds timeout", @(MAX_ACTIONS_DURATION_SEC)]
            buildError:error];;
  }
  if (nil != internalError) {
    if (error) {
      *error = internalError;
    }
    return NO;
  }

  return YES;
}

@end
