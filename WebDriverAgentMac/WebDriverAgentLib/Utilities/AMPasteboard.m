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


#import "AMPasteboard.h"

#import <mach/mach_time.h>
#import "FBErrorBuilder.h"
#import "FBMacros.h"


@implementation AMPasteboard

+ (BOOL)setData:(NSData *)data forType:(NSString *)type error:(NSError **)error
{
  NSPasteboard *pb = NSPasteboard.generalPasteboard;
  if ([type.lowercaseString isEqualToString:@"plaintext"]) {
    [pb clearContents];
    if (![pb setString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
               forType:NSPasteboardTypeString]) {
      NSString *description = @"Failed to copy string to the clipboard";
      if (error) {
        *error = [[FBErrorBuilder.builder withDescription:description] build];
      }
      return NO;
    }
  } else if ([type.lowercaseString isEqualToString:@"image"]) {
    NSImage *image = [[NSImage alloc] initWithData:data];
    if (nil == image) {
      NSString *description = @"No image can be parsed from the given pasteboard data";
      if (error) {
        *error = [[FBErrorBuilder.builder withDescription:description] build];
      }
      return NO;
    }
    [pb clearContents];
    if (![pb writeObjects:@[image]]) {
      NSString *description = @"Failed to copy image to the clipboard";
      if (error) {
        *error = [[FBErrorBuilder.builder withDescription:description] build];
      }
      return NO;
    }
  } else if ([type.lowercaseString isEqualToString:@"url"]) {
    NSString *urlString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    if (nil == url) {
      NSString *description = @"No URL can be parsed from the given data";
      if (error) {
        *error = [[FBErrorBuilder.builder withDescription:description] build];
      }
      return NO;
    }
    [pb clearContents];
    if (![pb setString:[url absoluteString] forType:NSPasteboardTypeURL]) {
      NSString *description = @"Failed to copy URL to the clipboard";
      if (error) {
        *error = [[FBErrorBuilder.builder withDescription:description] build];
      }
      return NO;
    }
  } else {
    NSString *description = [NSString stringWithFormat:@"Unsupported content type: %@", type];
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:description] build];
    }
    return NO;
  }
  return YES;
}

+ (NSData *)dataForType:(NSString *)type error:(NSError **)error
{
  NSPasteboard *pb = NSPasteboard.generalPasteboard;
  if ([type.lowercaseString isEqualToString:@"plaintext"]) {
    if ([pb.types containsObject:NSPasteboardTypeString]) {
      NSString* result = [pb stringForType:NSPasteboardTypeString];
      return [result dataUsingEncoding:NSUTF8StringEncoding];
    }
  } else if ([type.lowercaseString isEqualToString:@"image"]) {
    NSData *imageData = nil;

    for (NSPasteboardType pbType in @[NSPasteboardTypePNG, NSPasteboardTypeTIFF]) {
      if ([pb.types containsObject:pbType]) {
        imageData = [pb dataForType:pbType];
        break;
      }
    }

    if (nil != imageData) {
      NSImage *image = [[NSImage alloc] initWithData:imageData];
      if (nil != image) {
        NSArray *reps = [image representations];
        if ([reps count] > 0 && [reps[0] isKindOfClass:[NSBitmapImageRep class]]) {
          NSBitmapImageRep *bitmapRep = (NSBitmapImageRep *)reps[0];
          return [bitmapRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
        }
      }
    }
  } else if ([type.lowercaseString isEqualToString:@"url"]) {
    if ([pb.types containsObject:NSPasteboardTypeURL]) {
      NSString* result = [pb stringForType:NSPasteboardTypeURL];
      return [result dataUsingEncoding:NSUTF8StringEncoding];
    }
  } else {
    NSString *description = [NSString stringWithFormat:@"Unsupported content type: %@", type];
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:description] build];
    }
    return nil;
  }
  return [@"" dataUsingEncoding:NSUTF8StringEncoding];
}

@end
