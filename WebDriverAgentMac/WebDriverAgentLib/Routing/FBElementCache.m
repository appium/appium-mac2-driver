/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBElementCache.h"

#import "FBExceptions.h"

@interface FBElementCache ()
@property (atomic, strong) NSMutableDictionary<NSUUID *, XCUIElement *> *elementCache;
@end

@implementation FBElementCache

- (instancetype)init
{
  self = [super init];
  if (!self) {
    return nil;
  }
  _elementCache = [NSMutableDictionary dictionary];
  return self;
}

- (NSString *)storeElement:(XCUIElement *)element
{
  for (NSUUID *candidateUuid in self.elementCache) {
    if ([element isEqualTo:self.elementCache[candidateUuid]]) {
      return candidateUuid.UUIDString;
    }
  }
  NSUUID *uuid = [NSUUID UUID];
  self.elementCache[uuid] = element;
  return uuid.UUIDString;
}

- (XCUIElement *)elementForUUID:(NSString *)uuidStr
{
  NSUUID *uuid = [[NSUUID new] initWithUUIDString:uuidStr];
  if (nil == uuid) {
    NSString *reason = [NSString stringWithFormat:@"Cannot extract cached element for '%@' UUID", uuidStr];
    @throw [NSException exceptionWithName:FBInvalidArgumentException reason:reason userInfo:@{}];
  }

  XCUIElement *element = [self.elementCache objectForKey:uuid];
  if (nil == element) {
    NSString *reason = [NSString stringWithFormat:@"The element identified by \"%@\" is not present in the internal cache. Try to find it first", uuid];
    @throw [NSException exceptionWithName:FBStaleElementException reason:reason userInfo:@{}];
  }
  NSError *error;
  id<XCUIElementSnapshot> snapshot = [element snapshotWithError:&error];
  if (nil == snapshot) {
    NSString *reason = [NSString stringWithFormat:@"The element identified by \"%@\" is not present on the current view (%@). Make sure the current view is the expected one", uuid, error.localizedDescription];
    @throw [NSException exceptionWithName:FBStaleElementException reason:reason userInfo:@{}];
  }
  return element;
}

- (void)reset
{
  [self.elementCache removeAllObjects];
}

@end
