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

#import "AMGatekeeperUtils.h"

#import <AppKit/AppKit.h>
#include <sys/xattr.h>

static const char *QUARANTINE_ATTR = "com.apple.quarantine";
// The value looks like "0083;<hex timestamp>;<agent>;<uuid>". Gatekeeper sets this flag
// in the first field after the user approves the app, e.g. 0083 -> 00c3.
static const unsigned long long QUARANTINE_FLAG_USER_APPROVED = 0x40;

@implementation AMGatekeeperUtils

+ (nullable NSString *)blockingReasonForAppWithBundleId:(nullable NSString *)bundleId
                                                   path:(nullable NSString *)path
{
  NSURL *url = nil;
  if (nil != path) {
    url = [NSURL fileURLWithPath:path];
  } else if (nil != bundleId) {
    url = [NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:bundleId];
  }
  NSString *appPath = url.URLByStandardizingPath.path;
  if (nil == appPath) {
    return nil;
  }
  char value[256];
  ssize_t length = getxattr(appPath.fileSystemRepresentation, QUARANTINE_ATTR, value, sizeof(value) - 1, 0, 0);
  if (length <= 0) {
    return nil;
  }
  value[length] = '\0';
  NSString *flagsString = [[@(value) componentsSeparatedByString:@";"] firstObject];
  unsigned long long flags = 0;
  NSScanner *scanner = [NSScanner scannerWithString:flagsString];
  BOOL isMalformed = ![scanner scanHexLongLong:&flags] || !scanner.isAtEnd;
  // macOS shows a blocking "damaged" dialog for a malformed value, so it is treated as not approved
  if (!isMalformed && (flags & QUARANTINE_FLAG_USER_APPROVED)) {
    return nil;
  }
  // Single-quote the path for the shell, escaping the quotes inside of it
  NSString *quotedPath = [NSString stringWithFormat:@"'%@'", [appPath stringByReplacingOccurrencesOfString:@"'"
                                                                                                withString:@"'\\''"]];
  return [NSString stringWithFormat:
          @"macOS Gatekeeper would block '%@' from launching. The app is quarantined (e.g. it has been "
          "downloaded from the internet) and has not been approved yet%@, so macOS would ask for a "
          "confirmation that nothing can dismiss during the test, and the launch would hang. "
          "To fix this, either open the app manually once and approve it, or remove the quarantine "
          "flag on the machine that runs the tests: xattr -dr %s %@. "
          "If that fails with 'Operation not permitted', the app may be signed by another developer; "
          "allow your terminal app in System Settings > Privacy & Security > App Management "
          "(or Full Disk Access) and retry.",
          appPath, isMalformed ? @" (the quarantine attribute value is malformed)" : @"",
          QUARANTINE_ATTR, quotedPath];
}

@end
