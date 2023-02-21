/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBFailureProofTestCase.h"

#import "FBLogger.h"

@interface FBFailureProofTestCase ()
@end

@implementation FBFailureProofTestCase

- (void)setUp
{
  [super setUp];
  self.continueAfterFailure = YES;
  // https://github.com/appium/appium/issues/13949
  [self setValue:@(NO) forKey:@"_shouldSetShouldHaltWhenReceivesControl"];
  [self setValue:@(NO) forKey:@"_shouldHaltWhenReceivesControl"];
}

#ifdef MAC_OS_VERSION_13_0
- (void)_recordIssue:(XCTIssue *)issue
{
  [self _enqueueFailureWithDescription:issue.compactDescription
                                inFile:issue.sourceCodeContext.location.fileURL.path
                                atLine:issue.sourceCodeContext.location.lineNumber
                              expected:issue.type == XCTIssueTypeUnmatchedExpectedFailure];
}

- (void)_recordIssue:(XCTIssue *)issue forCaughtError:(id)error
{
  [self _enqueueFailureWithDescription:issue.compactDescription
                                inFile:issue.sourceCodeContext.location.fileURL.path
                                atLine:issue.sourceCodeContext.location.lineNumber
                              expected:issue.type == XCTIssueTypeUnmatchedExpectedFailure];
}

- (void)recordIssue:(XCTIssue *)issue
{
  [self _recordIssue:issue];
}
#else
/**
 Override 'recordFailureWithDescription' to not stop by failures.
 */
- (void)recordFailureWithDescription:(NSString *)description
                              inFile:(NSString *)filePath
                              atLine:(NSUInteger)lineNumber
                            expected:(BOOL)expected
{
  [self _enqueueFailureWithDescription:description inFile:filePath atLine:lineNumber expected:expected];
}
#endif

/**
 Private XCTestCase method used to block and tunnel failure messages
 */
- (void)_enqueueFailureWithDescription:(NSString *)description
                                inFile:(NSString *)filePath
                                atLine:(NSUInteger)lineNumber
                              expected:(BOOL)expected
{
  [FBLogger logFmt:@"Enqueue Failure: %@ %@ %lu %d", description, filePath, (unsigned long)lineNumber, expected];
}

@end