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

#import "FBXPath.h"

@interface FBXPath (Testing)
+ (NSString *)xmlStringWithSnapshot:(id)snapshot;
+ (NSXMLDocument *)xmlRepresentationWithSnapshot:(id)snapshot;
@end

@interface AMSourceSnapshot : NSObject
@property (nonatomic) XCUIElementType elementType;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *placeholderValue;
@property (nonatomic, strong) id value;
@property (nonatomic, getter=isEnabled) BOOL enabled;
@property (nonatomic, getter=isSelected) BOOL selected;
@property (nonatomic, copy) NSArray *children;
@property (nonatomic) NSUInteger frameReads;
@property (nonatomic) BOOL throwOnLabel;
@end

@implementation AMSourceSnapshot
- (CGRect)frame
{
  self.frameReads++;
  return CGRectMake(-1.5, 2.5, 10.25, 20.25);
}
- (NSString *)label
{
  if (self.throwOnLabel) {
    @throw [NSException exceptionWithName:@"SnapshotFailure" reason:@"test" userInfo:nil];
  }
  return _label;
}
@end

@interface AMXPathTests : XCTestCase
@end

@implementation AMXPathTests

- (AMSourceSnapshot *)snapshot
{
  AMSourceSnapshot *snapshot = [AMSourceSnapshot new];
  snapshot.elementType = XCUIElementTypeButton;
  snapshot.identifier = @"native-id";
  snapshot.label = @"Quotes \" & < > café 😀\n\t\r\x01";
  snapshot.title = @"";
  snapshot.value = @42;
  snapshot.enabled = YES;
  snapshot.selected = YES;
  snapshot.children = @[];
  return snapshot;
}

- (void)assertNode:(NSXMLElement *)actual equalsNode:(NSXMLElement *)expected
{
  XCTAssertEqualObjects(actual.name, expected.name);
  XCTAssertEqual(actual.attributes.count, expected.attributes.count);
  for (NSXMLNode *attribute in expected.attributes) {
    XCTAssertEqualObjects([actual attributeForName:attribute.name].stringValue, attribute.stringValue);
  }
  XCTAssertEqual(actual.childCount, expected.childCount);
  for (NSUInteger i = 0; i < expected.childCount; i++) {
    [self assertNode:(NSXMLElement *)[actual childAtIndex:i]
         equalsNode:(NSXMLElement *)[expected childAtIndex:i]];
  }
}

- (void)testStreamingSourcePreservesAttributesAndTree
{
  AMSourceSnapshot *root = [self snapshot];
  AMSourceSnapshot *child = [self snapshot];
  child.identifier = nil;
  child.label = nil;
  child.enabled = NO;
  root.children = @[child, [self snapshot]];
  // Compare against the serialized legacy output, including XML parsing's
  // normalization of literal whitespace inside attribute values.
  NSString *legacyXml = [[FBXPath xmlRepresentationWithSnapshot:root] XMLStringWithOptions:NSXMLNodePrettyPrint];
  NSError *error = nil;
  NSXMLDocument *expected = [[NSXMLDocument alloc] initWithXMLString:legacyXml options:0 error:&error];
  XCTAssertNil(error);
  NSString *xml = [FBXPath xmlStringWithSnapshot:root];
  NSXMLDocument *actual = [[NSXMLDocument alloc] initWithXMLString:xml options:0 error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(actual);
  [self assertNode:actual.rootElement equalsNode:expected.rootElement];
  XCTAssertFalse([xml containsString:@"private_indexPath"]);
  XCTAssertEqualObjects([actual.rootElement attributeForName:@"label"].stringValue,
                        @"Quotes \" & < > café 😀   ");
}

- (void)testStreamingSourceWithLeafRoot
{
  AMSourceSnapshot *root = [self snapshot];
  NSError *error = nil;
  NSXMLDocument *document = [[NSXMLDocument alloc] initWithXMLString:[FBXPath xmlStringWithSnapshot:root]
                                                          options:0 error:&error];
  XCTAssertNil(error);
  XCTAssertEqualObjects(document.rootElement.name, @"XCUIElementTypeButton");
  XCTAssertEqual(document.rootElement.childCount, 0);
  XCTAssertEqualObjects([document.rootElement attributeForName:@"title"].stringValue, @"");
  XCTAssertNil([document.rootElement attributeForName:@"placeholderValue"]);
}

- (void)testGeometryIsReadOncePerElement
{
  AMSourceSnapshot *root = [self snapshot];
  XCTAssertNotNil([FBXPath xmlStringWithSnapshot:root]);
  XCTAssertEqual(root.frameReads, 1);
  root.frameReads = 0;
  XCTAssertNotNil([FBXPath xmlRepresentationWithSnapshot:root]);
  XCTAssertEqual(root.frameReads, 1);
}

- (void)testSerializationCanRecoverAfterSnapshotException
{
  AMSourceSnapshot *root = [self snapshot];
  root.throwOnLabel = YES;
  XCTAssertThrowsSpecificNamed([FBXPath xmlStringWithSnapshot:root], NSException, @"SnapshotFailure");
  root.throwOnLabel = NO;
  XCTAssertNotNil([FBXPath xmlStringWithSnapshot:root]);
}

@end
