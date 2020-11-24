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

- (nullable FBCacheItem *)getItemWithElement:(nullable XCUIElement *)element
                                      orUuid:(nullable NSUUID *)uuid
{
  FBCacheItem *matchedItem = nil;
  NSUInteger matchIndex = self.elementCache.count - 1;
  for (FBCacheItem *candidate in self.elementCache.reverseObjectEnumerator) {
    if ((nil != element && [element isEqualTo:candidate.element])
        || (nil != uuid && [uuid isEqualTo:candidate.uuid])) {
      matchedItem = candidate;
      break;
    }
    --matchIndex;
  }
  if (nil == matchedItem) {
    return nil;
  }

  if (matchIndex < self.elementCache.count - 1) {
    // Put the accessed element to the top of the cache
    [self.elementCache removeObjectAtIndex:matchIndex];
    [self.elementCache addObject:matchedItem];
  }
  return matchedItem;
}

- (NSString *)storeElement:(XCUIElement *)element
{
  @synchronized (self.elementCache) {
    FBCacheItem *matchedItem = [self getItemWithElement:element orUuid:nil];
    if (nil != matchedItem) {
      return matchedItem.uuid.UUIDString;
    }

    if (self.elementCache.count >= MAX_CACHE_SIZE) {
      NSUInteger count = self.elementCache.count * LOAD_FACTOR / 100;
      [FBLogger logFmt:@"The elements cache size has reached its maximum value of %@. Shrinking %lu oldest elements from it",
       @(MAX_CACHE_SIZE), count];
      [self.elementCache removeObjectsInRange:NSMakeRange(0, count)];
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
    FBCacheItem *matchedItem = [self getItemWithElement:nil orUuid:uuid];
    if (nil != matchedItem) {
      element = matchedItem.element;
      elementDescription = matchedItem.elementDescription;
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
