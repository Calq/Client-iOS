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

#import "AbstractAnalyticsApiCall.h"

@interface QueuedApiCall : AbstractAnalyticsApiCall

/**
 * The id of this call in local storage.
 */
@property (readonly) int callId;

/**
 * Initialises an API call which has been previously queued.
 *
 * @param callId		The id of this queued call (in local storage).
 * @param endpoint		The endpoint this api call should use.
 * @param payload		The JSON payload of the call.
 * @param writeKey		The write key used.
 */
- (instancetype) initWithId:(int)callId endpoint:(NSString *)endoint payload:(NSString *)payload writeKey:(NSString *)writeKey;

/**
 * Gets the name of the API endpoint that should be called (such as Track)
 */
- (NSString *) apiEndpoint;

/**
 * Gets the JSON payload to be sent to the API server for this call.
 */
- (NSString *) payload;

@end
