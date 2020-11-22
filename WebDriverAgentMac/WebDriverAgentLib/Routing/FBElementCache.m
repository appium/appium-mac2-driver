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
#import "FBLogger.h"

#define MAX_CACHE_SIZE 500
#define LOAD_FACTOR 30


@interface FBCacheItem : NSObject
@property (nonatomic, readonly) NSUUID *uuid;
@property (nonatomic, readonly) XCUIElement *element;
@property (nonatomic, readonly) NSString *elementDescription;

- (instancetype)initWithElement:(XCUIElement *)element
                     havingUuid:(NSUUID *)uuid;
@end

@implementation FBCacheItem

- (instancetype)initWithElement:(XCUIElement *)element
                     havingUuid:(NSUUID *)uuid
{
  self = [super init];
  if (!self) {
    return nil;
  }

  _element = element;
  _elementDescription = element.description;
  _uuid = uuid;
  return self;
}

@end


@interface FBElementCache ()
@property (nonatomic, readonly) NSMutableArray<FBCacheItem *> *elementCache;
@end

@implementation FBElementCache

- (instancetype)init
{
  self = [super init];
  if (!self) {
    return nil;
  }

  _elementCache = [NSMutableArray array];
  return self;
}

- (NSString *)storeElement:(XCUIElement *)element
{
  @synchronized (self.elementCache) {
    for (FBCacheItem *candidate in self.elementCache.reverseObjectEnumerator) {
      if ([element isEqualTo:candidate.element]) {
        return candidate.uuid.UUIDString;
      }
    }

    if (self.elementCache.count >= MAX_CACHE_SIZE) {
      NSUInteger maxIndex = self.elementCache.count * LOAD_FACTOR / 100;
      [FBLogger logFmt:@"The elements cache size has reached its maximum value of %@. Shrinking %lu oldest elements from it",
       @(MAX_CACHE_SIZE), maxIndex];
      for (NSUInteger index = 0; index < maxIndex; ++index) {
        [self.elementCache removeObjectAtIndex:0];
      }
    }

    NSUUID *uuid = [NSUUID UUID];
    [self.elementCache addObject:[[FBCacheItem alloc] initWithElement:element havingUuid:uuid]];
    return uuid.UUIDString;
  }
}

- (XCUIElement *)elementForUUID:(NSString *)uuidStr
{
  NSUUID *uuid = [[NSUUID new] initWithUUIDString:uuidStr];
  if (nil == uuid) {
    NSString *reason = [NSString stringWithFormat:@"Cannot extract cached element for '%@' UUID", uuidStr];
    @throw [NSException exceptionWithName:FBInvalidArgumentException reason:reason userInfo:@{}];
  }

  @synchronized (self.elementCache) {
    XCUIElement *element = nil;
    NSString *elementDescription = nil;
    for (FBCacheItem *item in self.elementCache.reverseObjectEnumerator) {
      if ([uuid isEqualTo:item.uuid]) {
        element = item.element;
        elementDescription = item.elementDescription;
        break;
      }
    }
    if (nil == element) {
      NSString *reason = [NSString stringWithFormat:@"The element identified by \"%@\" is either not present in the internal elements cache or has expired from it. Try to find the element again", uuid];
      @throw [NSException exceptionWithName:FBStaleElementException reason:reason userInfo:@{}];
    }
    NSError *error;
    id<XCUIElementSnapshot> snapshot = [element snapshotWithError:&error];
    if (nil == snapshot) {
      NSString *reason = [NSString stringWithFormat:@"The element \"%@\" identified by \"%@\" is not present on the current view (%@). Make sure the current view is the expected one",
                          elementDescription, uuid, error.localizedDescription];
      @throw [NSException exceptionWithName:FBStaleElementException reason:reason userInfo:@{}];
    }
    return element;
  }
}

- (void)reset
{
  @synchronized (self.elementCache) {
    [self.elementCache removeAllObjects];
  }
}

@end
