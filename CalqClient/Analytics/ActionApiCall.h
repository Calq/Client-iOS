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

@interface ActionApiCall : AbstractAnalyticsApiCall

/**
 * Initialises a new ActionApiCall describing an action. This will be passed to the
 * /track/ API endpoint.
 *
 * @param actor				The actor performing this action.
 * @param action			The action being performed.
 * @param properties		Any custom properties related to this action. Can be empty, but not nil.
 * @param writeKey			The write key to use for this API call.
 */
- (instancetype) initWithData:(NSString *)actor action:(NSString *)action properties:(NSDictionary *)properties writeKey:(NSString *)writeKey;

/**
 * Initialises a new ActionApiCall describing an action. This will be passed to the
 * /track/ API endpoint.
 *
 * @param actor				The actor performing this action.
 * @param action			The action being performed.
 * @param properties		Any custom properties related to this action. Can be empty, but not nil.
 * @param writeKey			The write key to use for this API call.
 * @param timestamp			The timestamp that marks when this action happend (so calls can be sent later if no signal).
 */
- (instancetype) initWithDataAndTimestamp:(NSString *)actor action:(NSString *)action properties:(NSDictionary *)properties writeKey:(NSString *)writeKey timestamp:(NSDate *)timestamp;

@end
