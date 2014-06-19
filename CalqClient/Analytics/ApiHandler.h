/*
 *  Copyright 2014 Calq.io
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in
 *  compliance with the License. You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software distributed under the License is
 *  distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 *  implied. See the License for the specific language governing permissions and limitations under the
 *  License.
 *
 */

#import <Foundation/Foundation.h>
#import "AbstractAnalyticsApiCall.h"


@interface ApiHandler : NSObject

/**
 * Gets a shared instance of an ApiHandler for the given write key.
 * 
 * @param writeKey  The write key to get an ApiHandler for.
 */
+ (ApiHandler *) sharedInstanceWithKey:(NSString *)writeKey;

/**
 * Enqueues the given API call. This will put the call in a local queue and control will return to the 
 * caller immediately. The local queue is then persisted periodically in the background to local storage.
 *
 * On a schedule (default every 60s) all queued calls will be batched and sent to Calq. This means there
 * may be a delay between enqueing an API call and it showing in the reporting interface. If there is a
 * communication issue (such as signal loss) then the API calls will be retried later.
 *
 * @param apiCall   The api call to enqueue.
 */
- (void) enqueue:(AbstractAnalyticsApiCall *)apiCall;

/**
 * Requests that any outstanding API calls are flushed immediately (they will still be queued however if
 * there is a connectivity problem).
 *
 * @return YES if all actions flushed. NO if some failed (either API error or connection).
 */
- (BOOL) forceFlush;


@end
