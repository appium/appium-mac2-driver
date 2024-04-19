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

/** Bundle identifier of the application under test */
extern NSString* const AM_BUNDLE_ID_CAPABILITY;
/** Command line arguments for the application under test */
extern NSString* const AM_APP_ARGUMENTS_CAPABILITY;
/** Environment variables mapping for the application under test */
extern NSString* const AM_APP_ENVIRONMENT_CAPABILITY;
/** Whether to skip application under test termination when the test session is deleted */
extern NSString* const AM_SKIP_APP_KILL_CAPABILITY;
/** Whether to avoid resetting the state of the application under test on test startup */
extern NSString* const AM_NO_RESET_CAPABILITY;
/** Full path the the application under test bundle on the local FS */
extern NSString* const AM_APP_PATH_CAPABILITY;
/** Custom time zone name for the application under test */
extern NSString* const AM_APP_TIME_ZONE_CAPABILITY;
/** Custom locale properties for the application under test */
extern NSString* const AM_APP_LOCALE_CAPABILITY;
/** Deeplink URL to start the session with */
extern NSString* const AM_INITIAL_DEEPLINK_URL_CAPABILITY;

NS_ASSUME_NONNULL_END
