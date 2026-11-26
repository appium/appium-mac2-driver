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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMGatekeeperUtils : NSObject

/**
 Checks whether launching the given app would open a blocking Gatekeeper dialog
 ("downloaded from the internet" or "Not Opened"), which XCTest would wait on forever.
 That is the case if the bundle is quarantined and the user has not approved it yet,
 or if the quarantine attribute is malformed. Inconclusive checks (e.g. the app cannot be located)
 are treated as "not blocked".

 @param bundleId Bundle identifier of the app. Ignored if path is set
 @param path Full path to the app bundle
 @return The human-readable reason if the launch is blocked or nil otherwise
 */
+ (nullable NSString *)blockingReasonForAppWithBundleId:(nullable NSString *)bundleId
                                                   path:(nullable NSString *)path;

@end

NS_ASSUME_NONNULL_END
