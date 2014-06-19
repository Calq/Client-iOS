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

@interface TransferApiCall : AbstractAnalyticsApiCall

/**
 * Inits a new TransferApiCall describing a transfer. This will be passed to the
 * /transfer/ API endpoint.
 *
 * @param oldActor			The former actor name.
 * @param newActor			The new actor name
 * @param writeKey			The write key to use for this API call.
 */
- (instancetype) initWithData:(NSString *)oldActor newActor:(NSString *)newActor writeKey:(NSString *)writeKey;


@end
