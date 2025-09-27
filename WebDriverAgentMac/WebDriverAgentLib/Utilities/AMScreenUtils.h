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

NS_ASSUME_NONNULL_BEGIN

@interface AMScreenProperties: NSObject

/** YES if the corresponding screen is a main screen */
@property (readonly, nonatomic) BOOL isMain;
/** The integer identifier of a screen */
@property (readonly, nonatomic) long long identifier;

@end

/**
 Lists information about available screens

 @returns Screen infos
 */
NSArray<AMScreenProperties *> *AMListScreens(void);

/**
 Retrieves identifies from a XCUIScreen instance

 @returns Screen identifier
 */
long long AMFetchScreenId(XCUIScreen *screen);

/**
 @returns YES if the given screen is the main one
 */
BOOL AMIsMainScreen(XCUIScreen *screen);

NS_ASSUME_NONNULL_END
