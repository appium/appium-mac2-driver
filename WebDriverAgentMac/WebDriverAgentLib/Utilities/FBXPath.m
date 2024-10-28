/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBXPath.h"

#import "AMGeometryUtils.h"
#import "AMSnapshotUtils.h"
#import "FBConfiguration.h"
#import "FBElementUtils.h"
#import "FBExceptions.h"
#import "FBLogger.h"
#import "FBElementTypeTransformer.h"
#import "NSString+FBXMLSafeString.h"
#import "XCUIElementQuery+AMHelpers.h"


@interface FBElementAttribute : NSObject

@property (nonatomic, readonly) id<XCUIElementSnapshot> element;

+ (nonnull NSString *)name;
+ (nullable NSString *)valueForElement:(id<XCUIElementSnapshot>)element;

+ (void)recordWithNode:(NSXMLElement *)node forElement:(id<XCUIElementSnapshot>)element;

+ (NSArray<Class> *)supportedAttributes;

@end

@interface FBTypeAttribute : FBElementAttribute

@end

@interface FBTitleAttribute : FBElementAttribute

@end

@interface FBSelectedAttribute : FBElementAttribute

@end

@interface FBPlaceholderValueAttribute : FBElementAttribute

@end

@interface FBValueAttribute : FBElementAttribute

@end

@interface FBIdentifierAttribute : FBElementAttribute

@end

@interface FBLabelAttribute : FBElementAttribute

@end

@interface FBEnabledAttribute : FBElementAttribute

@end

@interface FBDimensionAttribute : FBElementAttribute

@end

@interface FBXAttribute : FBDimensionAttribute

@end

@interface FBYAttribute : FBDimensionAttribute

@end

@interface FBWidthAttribute : FBDimensionAttribute

@end

@interface FBHeightAttribute : FBDimensionAttribute

@end

@interface FBInternalIndexAttribute : FBElementAttribute

@property (nonatomic, nonnull, readonly) NSString* indexValue;

+ (void)recordWithNode:(NSXMLElement *)node forValue:(NSString *)value;

@end

@interface NSString (FBXPathFixes)

/**
 https://discuss.appium.io/t/cannot-find-element-with-mac2/44959
 */
- (NSString *)fb_toFixedXPathQuery;

@end

@implementation NSString (FBXPathFixes)

- (NSString *)fb_toFixedXPathQuery
{
  NSString *replacePattern = @"^([(]*)(/)";
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:replacePattern
                                                                         options:NSRegularExpressionCaseInsensitive
                                                                           error:nil];
  return [regex stringByReplacingMatchesInString:self
                                         options:0
                                           range:NSMakeRange(0, [self length])
                                    withTemplate:@"$1.$2"];
}

@end

static NSString *const kXMLIndexPathKey = @"private_indexPath";


@implementation FBXPath

+ (id)throwException:(NSString *)name forQuery:(NSString *)xpathQuery
{
  NSString *reason = [NSString stringWithFormat:@"Cannot evaluate results for XPath expression \"%@\"", xpathQuery];
  @throw [NSException exceptionWithName:name reason:reason userInfo:@{}];
  return nil;
}

+ (nullable NSString *)xmlStringWithRootElement:(XCUIElement *)root
{
  NSError *error;
  id<XCUIElementSnapshot> snapshot = [root snapshotWithError:&error];
  if (nil == snapshot) {
    [FBLogger logFmt:@"The snapshot of %@ cannot be taken. Original error: %@", root.description, error.description];
    return nil;
  }

  return [[self xmlRepresentationWithSnapshot:snapshot] XMLStringWithOptions:NSXMLNodePrettyPrint];
}

+ (NSArray<XCUIElement *> *)matchesWithRootElement:(XCUIElement *)root
                                          forQuery:(NSString *)xpathQuery
                             includeOnlyFirstMatch:(BOOL)firstMatch
{
  NSError *error;
  id<XCUIElementSnapshot> snapshot = [root snapshotWithError:&error];
  if (nil == snapshot) {
    NSString *reason = [NSString stringWithFormat:@"Cannot evaluate results for XPath expression \"%@\". Original error: %@", xpathQuery, error.description];
    @throw [NSException exceptionWithName:FBXPathQueryEvaluationException
                                   reason:reason
                                 userInfo:@{}];
  }

  NSXMLElement *rootElement = [self makeXmlWithRootSnapshot:snapshot
                                                  indexPath:[AMSnapshotUtils hashWithSnapshot:snapshot]];
  NSArray<__kindof NSXMLNode *> *matches = [rootElement nodesForXPath:[xpathQuery fb_toFixedXPathQuery]
                                                                error:&error];
  if (nil == matches) {
    @throw [NSException exceptionWithName:FBInvalidXPathException
                                   reason:error.description
                                 userInfo:@{}];
  }

  NSArray *matchingElements = [self collectMatchingElementsWithNodes:matches
                                                         rootElement:root
                                                        rootSnapshot:snapshot
                                               includeOnlyFirstMatch:firstMatch];
  if (nil == matchingElements) {
    return [self throwException:FBXPathQueryEvaluationException forQuery:xpathQuery];
  }
  return matchingElements;
}

+ (NSArray *)collectMatchingElementsWithNodes:(NSArray<__kindof NSXMLNode *> *)nodes
                                  rootElement:(XCUIElement *)rootElement
                                 rootSnapshot:(id<XCUIElementSnapshot>)rootSnapshot
                        includeOnlyFirstMatch:(BOOL)firstMatch
{
  if (0 == nodes.count) {
    return @[];
  }

  NSMutableArray<NSString *> *hashes = [NSMutableArray array];
  for (NSXMLNode *node in nodes) {
    if (![node isKindOfClass:NSXMLElement.class]) {
      continue;
    }
    NSString *attrValue = [[(NSXMLElement *)node attributeForName:kXMLIndexPathKey] stringValue];
    if (nil == attrValue) {
      continue;
    }
    [hashes addObject:attrValue];
  }
  NSMutableArray<XCUIElement *> *matchingElements = [NSMutableArray array];
  NSString *selfHash = [AMSnapshotUtils hashWithSnapshot:rootSnapshot];
  if ([hashes containsObject:selfHash]) {
    [matchingElements addObject:rootElement];
    if (firstMatch) {
      return matchingElements.copy;
    }
  }
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id snapshot, NSDictionary *bindings) {
    return [hashes containsObject:[AMSnapshotUtils hashWithSnapshot:snapshot]];
  }];
  [matchingElements addObjectsFromArray:[[rootElement descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicate].am_allMatches];
  return firstMatch && matchingElements.count > 0
    ? @[matchingElements.firstObject]
    : matchingElements.copy;
}

+ (NSXMLDocument *)xmlRepresentationWithSnapshot:(id<XCUIElementSnapshot>)root
{
  NSXMLElement *rootElement = [self makeXmlWithRootSnapshot:root indexPath:nil];
  NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithRootElement:rootElement];
  [xmlDoc setVersion:@"1.0"];
  [xmlDoc setCharacterEncoding:@"UTF-8"];
  return xmlDoc;
}

+ (nullable NSString *)safeXmlStringWithString:(nullable NSString *)str
{
  return [str fb_xmlSafeStringWithReplacement:@""];
}

+ (void)recordElementAttributes:(NSXMLElement *)node
                    forSnapshot:(id<XCUIElementSnapshot>)snapshot
                      indexPath:(nullable NSString *)indexPath
{
  for (Class attributeCls in FBElementAttribute.supportedAttributes) {
    [attributeCls recordWithNode:node forElement:snapshot];
  }

  if (nil != indexPath) {
    // index path is the special case
    [FBInternalIndexAttribute recordWithNode:node forValue:indexPath];
  }
}

+ (NSXMLElement *)makeXmlWithRootSnapshot:(id<XCUIElementSnapshot>)root
                                indexPath:(nullable NSString *)indexPath
{
  NSString *type = [FBElementTypeTransformer stringWithElementType:root.elementType];
  NSXMLElement *rootElement = [NSXMLElement elementWithName:type];
  [self recordElementAttributes:rootElement
                    forSnapshot:root
                      indexPath:indexPath];

  NSArray<id<XCUIElementSnapshot>> *children = root.children;
  for (id<XCUIElementSnapshot> childSnapshot in children) {
    NSString *newIndexPath = (indexPath != nil)
      ? [AMSnapshotUtils hashWithSnapshot:childSnapshot]
      : nil;
    NSXMLElement *childElement = [self makeXmlWithRootSnapshot:childSnapshot
                                                     indexPath:newIndexPath];
    [rootElement addChild:childElement];
  }
  return rootElement;
}

@end


static NSString *const FBAbstractMethodInvocationException = @"AbstractMethodInvocationException";

@implementation FBElementAttribute

- (instancetype)initWithElement:(id<XCUIElementSnapshot>)element
{
  self = [super init];
  if (self) {
    _element = element;
  }
  return self;
}

+ (NSString *)name
{
  NSString *errMsg = [NSString stringWithFormat:@"The abstract method +(NSString *)name is expected to be overriden by %@", NSStringFromClass(self.class)];
  @throw [NSException exceptionWithName:FBAbstractMethodInvocationException reason:errMsg userInfo:nil];
}

+ (NSString *)valueForElement:(id<XCUIElementSnapshot>)element
{
  NSString *errMsg = [NSString stringWithFormat:@"The abstract method -(NSString *)value is expected to be overriden by %@", NSStringFromClass(self.class)];
  @throw [NSException exceptionWithName:FBAbstractMethodInvocationException reason:errMsg userInfo:nil];
}

+ (void)recordWithNode:(NSXMLElement *)node forElement:(id<XCUIElementSnapshot>)element
{
  NSString *value = [self valueForElement:element];
  if (nil == value) {
    // Skip the attribute if the value equals to nil
    return;
  }

  NSString *attrName = [FBXPath safeXmlStringWithString:self.name];
  NSString *attrValue = [FBXPath safeXmlStringWithString:value];
  [node addAttribute:[NSXMLNode attributeWithName:attrName stringValue:attrValue]];
}

+ (NSArray<Class> *)supportedAttributes
{
  static NSArray *attributes;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // The list of attributes to be written for each XML node
    // The enumeration order does matter here
    attributes = @[
      FBTypeAttribute.class,
      FBIdentifierAttribute.class,
      FBValueAttribute.class,
      FBLabelAttribute.class,
      FBTitleAttribute.class,
      FBPlaceholderValueAttribute.class,
      FBEnabledAttribute.class,
      FBSelectedAttribute.class,
      FBXAttribute.class,
      FBYAttribute.class,
      FBWidthAttribute.class,
      FBHeightAttribute.class,
    ];
  });
  return attributes;
}

@end

@implementation FBTypeAttribute

+ (NSString *)name
{
  return @"elementType";
}

+ (NSString *)valueForElement:(id<XCUIElementSnapshot>)element
{
  return [NSString stringWithFormat:@"%lu", element.elementType];
}

@end

@implementation FBValueAttribute

+ (NSString *)name
{
  return @"value";
}

+ (NSString *)valueForElement:(id<XCUIElementSnapshot>)element
{
  return [FBElementUtils stringValueWithValue:element.value];
}

@end

@implementation FBIdentifierAttribute

+ (NSString *)name
{
  return @"identifier";
}

+ (NSString *)valueForElement:(id<XCUIElementSnapshot>)element
{
  return element.identifier;
}

@end

@implementation FBLabelAttribute

+ (NSString *)name
{
  return @"label";
}

+ (NSString *)valueForElement:(id<XCUIElementSnapshot>)element
{
  return element.label;
}

@end

@implementation FBEnabledAttribute

+ (NSString *)name
{
  return @"enabled";
}

+ (NSString *)valueForElement:(id<XCUIElementSnapshot>)element
{
  return element.enabled ? @"true" : @"false";
}

@end

@implementation FBDimensionAttribute

+ (NSString *)valueForElement:(id<XCUIElementSnapshot>)element
{
  return [NSString stringWithFormat:@"%@", [AMCGRectToDict(element.frame) objectForKey:self.name]];
}

@end

@implementation FBXAttribute

+ (NSString *)name
{
  return @"x";
}

@end

@implementation FBYAttribute

+ (NSString *)name
{
  return @"y";
}

@end

@implementation FBWidthAttribute

+ (NSString *)name
{
  return @"width";
}

@end

@implementation FBHeightAttribute

+ (NSString *)name
{
  return @"height";
}

@end

@implementation FBTitleAttribute : FBElementAttribute

+ (NSString *)name
{
  return @"title";
}

+ (NSString *)valueForElement:(id<XCUIElementSnapshot>)element
{
  return element.title;
}

@end

@implementation FBSelectedAttribute : FBElementAttribute

+ (NSString *)name
{
  return @"selected";
}

+ (NSString *)valueForElement:(id<XCUIElementSnapshot>)element
{
  return element.selected ? @"true" : @"false";
}

@end

@implementation FBPlaceholderValueAttribute : FBElementAttribute

+ (NSString *)name
{
  return @"placeholderValue";
}

+ (NSString *)valueForElement:(id<XCUIElementSnapshot>)element
{
  return element.placeholderValue;
}

@end

@implementation FBInternalIndexAttribute: FBElementAttribute

+ (NSString *)name
{
  return kXMLIndexPathKey;
}

+ (void)recordWithNode:(NSXMLElement *)node forValue:(NSString *)value
{
  if (nil == value) {
    // Skip the attribute if the value equals to nil
    return;
  }

  NSString *attrName = [FBXPath safeXmlStringWithString:self.name];
  NSString *attrValue = [FBXPath safeXmlStringWithString:value];
  [node addAttribute:[NSXMLNode attributeWithName:attrName stringValue:attrValue]];
}

@end
