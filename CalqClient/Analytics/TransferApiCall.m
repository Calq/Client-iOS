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

#import "TransferApiCall.h"
#import "ReservedApiProperties.h"

@implementation TransferApiCall
{
	/**
	 * The new actor Id.
	 */
	NSString * _newActor;
}

/**
 * Inits a new TransferApiCall describing a transfer. This will be passed to the
 * /transfer/ API endpoint.
 *
 * @param oldActor			The former actor name.
 * @param newActor			The new actor name
 * @param writeKey			The write key to use for this API call.
 */
- (instancetype) initWithData:(NSString *)oldActor newActor:(NSString *)newActor writeKey:(NSString *)writeKey
{
    if (self = [[self init] initAbstract:oldActor writeKey:writeKey])
    {
        self->_newActor = newActor;
    }
    return self;
}


/**
 * Gets the name of the API endpoint that should be called (such as Track)
 */
- (NSString *) apiEndpoint
{
    static NSString *endpoint = @"Transfer";
    return endpoint;
}

/**
 * Gets the JSON payload to be sent to the API server for this call.
 */
- (NSMutableDictionary *) buildJsonPayload
{
    NSMutableDictionary *data = [super buildJsonPayload];
    [data setObject:self.actor forKey:OldActor];
    [data setObject:self->_newActor forKey:NewActor];
    return data;
}

@end
