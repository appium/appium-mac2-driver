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
#import "AMPasteboard.h"

@interface AMPasteboardTests : AMIntegrationTestCase
@end

NSData *dataFromImage(NSImage *image) {
  if (!image) return nil;

  NSSize size = [image size];
  NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc]
                                 initWithBitmapDataPlanes:NULL
                                 pixelsWide:size.width
                                 pixelsHigh:size.height
                                 bitsPerSample:8
                                 samplesPerPixel:4
                                 hasAlpha:YES
                                 isPlanar:NO
                                 colorSpaceName:NSCalibratedRGBColorSpace
                                 bytesPerRow:0
                                 bitsPerPixel:0];
  if (!bitmapRep) return nil;

  NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmapRep];
  if (!context) return nil;

  [NSGraphicsContext saveGraphicsState];
  [NSGraphicsContext setCurrentContext:context];
  [image drawInRect:NSMakeRect(0, 0, size.width, size.height)
           fromRect:NSZeroRect
          operation:NSCompositingOperationCopy
           fraction:1.0];
  [NSGraphicsContext restoreGraphicsState];

  return [bitmapRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
}


@implementation AMPasteboardTests

- (void)testPasteboardPlaintex
{
  NSError *error;
  NSString *expected = @"test";
  XCTAssertTrue([AMPasteboard setData:[expected dataUsingEncoding:NSUTF8StringEncoding]
                              forType:@"plaintext"
                                error:&error]);
  XCTAssertNil(error);
  NSData *actual = [AMPasteboard dataForType:@"plaintext" error:&error];
  XCTAssertNotNil(actual);
  XCTAssertNil(error);
  XCTAssertEqualObjects([[NSString alloc] initWithData:actual encoding:NSUTF8StringEncoding], expected);
}

- (void)testPasteboardUrl
{
  NSError *error;
  NSString *expected = @"https://appium.io";
  XCTAssertTrue([AMPasteboard setData:[expected dataUsingEncoding:NSUTF8StringEncoding]
                              forType:@"url"
                                error:&error]);
  XCTAssertNil(error);
  NSData *actual = [AMPasteboard dataForType:@"url" error:&error];
  XCTAssertNotNil(actual);
  XCTAssertNil(error);
  XCTAssertEqualObjects([[NSString alloc] initWithData:actual encoding:NSUTF8StringEncoding], expected);
}

- (void)testPasteboardImage
{
  NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(1, 1)];
  [image lockFocus];
  [[NSColor clearColor] setFill];
  NSRectFill(NSMakeRect(0, 0, 1, 1));
  [image unlockFocus];

  NSData *expected = dataFromImage(image);
  if (nil == expected) {
    XCTFail(@"imageData cannot be nil");
  }

  NSError *error;
  XCTAssertTrue([AMPasteboard setData:expected
                              forType:@"image"
                                error:&error]);
  XCTAssertNil(error);
  NSData *actual = [AMPasteboard dataForType:@"image" error:&error];
  XCTAssertNotNil(actual);
  XCTAssertNil(error);
  XCTAssertEqualObjects(actual, expected);
}

@end
