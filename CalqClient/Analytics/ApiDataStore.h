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

#import "QueuedApiCall.h"

@interface ApiDataStore : NSObject

/**
 * Gets the shared instance of this ApiDataStore. Typically this is the method that you would use
 * rather than init because the DB is shared. init is normally used directly only in tests.
 */
+ (ApiDataStore *) sharedInstance;

/**
  * Adds the given API call to the queue.
  *
  * @param apiCall		The call to add to the queue.
  */
- (BOOL) addToQueue:(AbstractAnalyticsApiCall*)apiCall;

/**
 * Gets the next API message from the queue (doesn't remove from queue).
 *
 * @param writeKey		The writeKey to peek for queued calls for.
 */
- (QueuedApiCall *) peekQueue:(NSString*)writeKey;

/**
 * Removes the given QueuedApiCall from the queue.
 *
 * @param apiCall		The previously queued API call to remove.
 */
- (BOOL) deleteFromQueue:(QueuedApiCall*)apiCall;

/**
 * Empties the current queue. Not normally used outside of testing.
 */
- (BOOL) truncateQueue;

@end
