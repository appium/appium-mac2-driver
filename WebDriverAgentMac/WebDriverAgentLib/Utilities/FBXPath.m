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

#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpadded"
#endif

#import <libxml/tree.h>
#import <libxml/parser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>
#import <libxml/encoding.h>
#import <libxml/xmlwriter.h>

#ifdef __clang__
#pragma clang diagnostic pop
#endif


@interface FBElementAttribute : NSObject

@property (nonatomic, readonly) id<XCUIElementSnapshot> element;

+ (nonnull NSString *)name;
+ (nullable NSString *)valueForElement:(id<XCUIElementSnapshot>)element;

+ (int)recordWithWriter:(xmlTextWriterPtr)writer forElement:(id<XCUIElementSnapshot>)element;

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

+ (int)recordWithWriter:(xmlTextWriterPtr)writer forValue:(NSString *)value;

@end

const static char *_UTF8Encoding = "UTF-8";

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
  
  xmlDocPtr doc;
  xmlTextWriterPtr writer = xmlNewTextWriterDoc(&doc, 0);
  int rc = [self xmlRepresentationWithRootElement:snapshot
                                           writer:writer
                                            query:nil];
  if (rc < 0) {
    xmlFreeTextWriter(writer);
    xmlFreeDoc(doc);
    return nil;
  }
  int buffersize;
  xmlChar *xmlbuff;
  xmlDocDumpFormatMemory(doc, &xmlbuff, &buffersize, 1);
  xmlFreeTextWriter(writer);
  xmlFreeDoc(doc);
  return [NSString stringWithCString:(const char *)xmlbuff encoding:NSUTF8StringEncoding];
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

  xmlDocPtr doc;
  xmlTextWriterPtr writer = xmlNewTextWriterDoc(&doc, 0);
  if (NULL == writer) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlNewTextWriterDoc for XPath query \"%@\"", xpathQuery];
    return [self throwException:FBXPathQueryEvaluationException forQuery:xpathQuery];
  }
  int rc = [self xmlRepresentationWithRootElement:snapshot
                                           writer:writer
                                            query:xpathQuery];
  if (rc < 0) {
    xmlFreeTextWriter(writer);
    xmlFreeDoc(doc);
    return [self throwException:FBXPathQueryEvaluationException forQuery:xpathQuery];
  }

  xmlXPathObjectPtr queryResult = [self evaluate:xpathQuery document:doc];
  if (NULL == queryResult) {
    xmlFreeTextWriter(writer);
    xmlFreeDoc(doc);
    return [self throwException:FBInvalidXPathException forQuery:xpathQuery];
  }

  NSArray *matchingElements = [self collectMatchingElementsWithNodeSet:queryResult->nodesetval
                                                           rootElement:root
                                                          rootSnapshot:snapshot
                                                 includeOnlyFirstMatch:firstMatch];
  xmlXPathFreeObject(queryResult);
  xmlFreeTextWriter(writer);
  xmlFreeDoc(doc);
  if (nil == matchingElements) {
    return [self throwException:FBXPathQueryEvaluationException forQuery:xpathQuery];
  }
  return matchingElements;
}

+ (NSArray *)collectMatchingElementsWithNodeSet:(xmlNodeSetPtr)nodeSet
                                    rootElement:(XCUIElement *)rootElement
                                   rootSnapshot:(id<XCUIElementSnapshot>)rootSnapshot
                          includeOnlyFirstMatch:(BOOL)firstMatch
{
  if (xmlXPathNodeSetIsEmpty(nodeSet)) {
    return @[];
  }

  const xmlChar *indexPathKeyName = [self xmlCharPtrForInput:[kXMLIndexPathKey cStringUsingEncoding:NSUTF8StringEncoding]];
  NSMutableArray<NSString *> *hashes = [NSMutableArray array];
  for (NSInteger i = 0; i < nodeSet->nodeNr; i++) {
    xmlNodePtr currentNode = nodeSet->nodeTab[i];
    xmlChar *attrValue = xmlGetProp(currentNode, indexPathKeyName);
    if (NULL == attrValue) {
      [FBLogger log:@"Failed to invoke libxml2>xmlGetProp"];
      return nil;
    }

    NSString *hash = [NSString stringWithCString:(const char *)attrValue
                                        encoding:NSUTF8StringEncoding];
    [hashes addObject:hash];
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

+ (int)xmlRepresentationWithRootElement:(id<XCUIElementSnapshot>)root
                                 writer:(xmlTextWriterPtr)writer
                                  query:(nullable NSString*)query
{
  int rc = xmlTextWriterStartDocument(writer, NULL, _UTF8Encoding, NULL);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterStartDocument. Error code: %d", rc];
    return rc;
  }

  NSString *index = [AMSnapshotUtils hashWithSnapshot:root];
  rc = [self writeXmlWithRootElement:root
                           indexPath:(query != nil ? index : nil)
                              writer:writer];
  if (rc < 0) {
    [FBLogger log:@"Failed to generate XML presentation of a screen element"];
    return rc;
  }
  rc = xmlTextWriterEndDocument(writer);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlXPathNewContext. Error code: %d", rc];
    return rc;
  }
  return 0;
}

+ (xmlChar *)xmlCharPtrForInput:(const char *)input
{
  if (0 == input) {
    return NULL;
  }

  xmlCharEncodingHandlerPtr handler = xmlFindCharEncodingHandler(_UTF8Encoding);
  if (!handler) {
    [FBLogger log:@"Failed to invoke libxml2>xmlFindCharEncodingHandler"];
    return NULL;
  }

  int size = (int) strlen(input) + 1;
  int outputSize = size * 2 - 1;
  xmlChar *output = (unsigned char *) xmlMalloc((size_t) outputSize);

  if (0 != output) {
    int temp = size - 1;
    int ret = handler->input(output, &outputSize, (const xmlChar *) input, &temp);
    if ((ret < 0) || (temp - size + 1)) {
      xmlFree(output);
      output = 0;
    } else {
      output = (unsigned char *) xmlRealloc(output, outputSize + 1);
      output[outputSize] = 0;
    }
  }

  return output;
}

+ (xmlXPathObjectPtr)evaluate:(NSString *)xpathQuery document:(xmlDocPtr)doc
{
  xmlXPathContextPtr xpathCtx = xmlXPathNewContext(doc);
  if (NULL == xpathCtx) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlXPathNewContext for XPath query \"%@\"", xpathQuery];
    return NULL;
  }
  xpathCtx->node = doc->children;

  xmlXPathObjectPtr xpathObj = xmlXPathEvalExpression([self xmlCharPtrForInput:[xpathQuery cStringUsingEncoding:NSUTF8StringEncoding]], xpathCtx);
  if (NULL == xpathObj) {
    xmlXPathFreeContext(xpathCtx);
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlXPathEvalExpression for XPath query \"%@\"", xpathQuery];
    return NULL;
  }
  xmlXPathFreeContext(xpathCtx);
  return xpathObj;
}

+ (xmlChar *)safeXmlStringWithString:(NSString *)str
{
  if (nil == str) {
    return NULL;
  }

  NSString *safeString = [str fb_xmlSafeStringWithReplacement:@""];
  return [self.class xmlCharPtrForInput:[safeString cStringUsingEncoding:NSUTF8StringEncoding]];
}

+ (int)recordElementAttributes:(xmlTextWriterPtr)writer
                    forElement:(id<XCUIElementSnapshot>)element
                     indexPath:(nullable NSString *)indexPath
{
  for (Class attributeCls in FBElementAttribute.supportedAttributes) {
    int rc = [attributeCls recordWithWriter:writer forElement:element];
    if (rc < 0) {
      return rc;
    }
  }

  if (nil != indexPath) {
    // index path is the special case
    return [FBInternalIndexAttribute recordWithWriter:writer forValue:indexPath];
  }
  return 0;
}

+ (int)writeXmlWithRootElement:(id<XCUIElementSnapshot>)root
                     indexPath:(nullable NSString *)indexPath
                        writer:(xmlTextWriterPtr)writer
{
  id<XCUIElementSnapshot> currentSnapshot = root;
  NSArray<id<XCUIElementSnapshot>> *children = root.children;

  NSString *type = [FBElementTypeTransformer stringWithElementType:currentSnapshot.elementType];
  int rc = xmlTextWriterStartElement(writer, [self xmlCharPtrForInput:[type cStringUsingEncoding:NSUTF8StringEncoding]]);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterStartElement for the tag value '%@'. Error code: %d", type, rc];
    return rc;
  }

  rc = [self recordElementAttributes:writer
                          forElement:currentSnapshot
                           indexPath:indexPath];
  if (rc < 0) {
    return rc;
  }

  for (NSUInteger i = 0; i < [children count]; i++) {
    id<XCUIElementSnapshot> childSnapshot = [children objectAtIndex:i];
    NSString *newIndexPath = (indexPath != nil)
      ? [AMSnapshotUtils hashWithSnapshot:childSnapshot]
      : nil;
    rc = [self writeXmlWithRootElement:childSnapshot
                             indexPath:newIndexPath
                                writer:writer];
    if (rc < 0) {
      return rc;
    }
  }

  rc = xmlTextWriterEndElement(writer);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterEndElement. Error code: %d", rc];
    return rc;
  }
  return 0;
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

+ (int)recordWithWriter:(xmlTextWriterPtr)writer forElement:(id<XCUIElementSnapshot>)element
{
  NSString *value = [self valueForElement:element];
  if (nil == value) {
    // Skip the attribute if the value equals to nil
    return 0;
  }
  int rc = xmlTextWriterWriteAttribute(writer, [FBXPath safeXmlStringWithString:self.name], [FBXPath safeXmlStringWithString:value]);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterWriteAttribute(%@='%@'). Error code: %d", self.name, value, rc];
  }
  return rc;
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

@implementation FBInternalIndexAttribute

+ (NSString *)name
{
  return kXMLIndexPathKey;
}

+ (int)recordWithWriter:(xmlTextWriterPtr)writer forValue:(NSString *)value
{
  if (nil == value) {
    // Skip the attribute if the value equals to nil
    return 0;
  }
  int rc = xmlTextWriterWriteAttribute(writer, [FBXPath safeXmlStringWithString:[self name]], [FBXPath safeXmlStringWithString:value]);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterWriteAttribute(%@='%@'). Error code: %d", [self name], value, rc];
  }
  return rc;
}

@end
