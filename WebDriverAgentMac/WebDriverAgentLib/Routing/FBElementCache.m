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
#import "LRUCache.h"

#define MAX_CACHE_SIZE 1000


@interface FBCacheItem : NSObject
@property (nonatomic, readonly) XCUIElement *element;
@property (nonatomic, readonly) NSString *elementDescription;

- (instancetype)initWithElement:(XCUIElement *)element;
@end

@implementation FBCacheItem

- (instancetype)initWithElement:(XCUIElement *)element
{
  self = [super init];
  if (!self) {
    return nil;
  }

  _element = element;
  _elementDescription = element.description;
  return self;
}

@end


@interface FBElementCache ()
@property (nonatomic) LRUCache *elementCache;
@end

@implementation FBElementCache

- (instancetype)init
{
  self = [super init];
  if (!self) {
    return nil;
  }

  _elementCache = [[LRUCache alloc] initWithCapacity:MAX_CACHE_SIZE];
  return self;
}

- (NSString *)storeElement:(XCUIElement *)element
{
  NSUUID *uuid = [NSUUID UUID];
  @synchronized (self.elementCache) {
    [self.elementCache setObject:[[FBCacheItem alloc] initWithElement:element]
                          forKey:uuid];
  }
  return uuid.UUIDString;
}

- (XCUIElement *)elementForUUID:(NSString *)uuidStr
{
  NSUUID *uuid = [[NSUUID new] initWithUUIDString:uuidStr];
  if (nil == uuid) {
    NSString *reason = [NSString stringWithFormat:@"Cannot extract cached element for '%@' UUID", uuidStr];
    @throw [NSException exceptionWithName:FBInvalidArgumentException reason:reason userInfo:@{}];
  }

  XCUIElement *element = nil;
  NSString *elementDescription = nil;
  FBCacheItem *matchedItem;
  @synchronized (self.elementCache) {
    matchedItem = [self.elementCache objectForKey:uuid];
  }
  if (nil != matchedItem) {
    element = matchedItem.element;
    elementDescription = matchedItem.elementDescription;
  }
  if (nil == element) {
    NSString *reason = [NSString stringWithFormat:@"The element identified by \"%@\" is either not present in the internal elements cache or has expired from it. Try to find the element again", uuidStr];
    @throw [NSException exceptionWithName:FBStaleElementException reason:reason userInfo:@{}];
  }
  NSError *error;
  id<XCUIElementSnapshot> snapshot = [element snapshotWithError:&error];
  if (nil == snapshot) {
    NSString *reason = [NSString stringWithFormat:@"The element \"%@\" identified by \"%@\" is not present on the current view (%@). Make sure the current view is the expected one",
                        elementDescription, uuidStr, error.localizedDescription];
    @throw [NSException exceptionWithName:FBStaleElementException reason:reason userInfo:@{}];
  }
  return element;
}

- (void)reset
{
  @synchronized (self.elementCache) {
    self.elementCache = [[LRUCache alloc] initWithCapacity:MAX_CACHE_SIZE];
  }
}

@end
