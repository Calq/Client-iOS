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

#import "ProfileApiCall.h"
#import "ReservedApiProperties.h"

@implementation ProfileApiCall
{
	/**
	 * The custom properties sent with this action.
	 */
	NSDictionary * _properties;
}

/**
 * Initialises a new ProfileApiCall describing new profile data. This will be passed to the
 * /profile/ API endpoint.
 *
 * @param actor				The actor this profile is for.
 * @param properties		Any custom properties for this profile. Should not be empty or nil.
 * @param writeKey			The write key to use for this API call.
 */
- (instancetype) initWithData:(NSString *)actor properties:(NSDictionary *)properties writeKey:(NSString *)writeKey;
{
    if (self = [[self init] initAbstract:actor writeKey:writeKey])
    {
        self->_properties = properties;
    }
    return self;
}

/**
 * Gets the name of the API endpoint that should be called (such as Track)
 */
- (NSString *) apiEndpoint
{
    static NSString *endpoint = @"Profile";
    return endpoint;
}

/**
 * Gets the JSON payload to be sent to the API server for this call.
 */
- (NSMutableDictionary *) buildJsonPayload
{
    NSMutableDictionary *data = [super buildJsonPayload];
    [data setObject:self->_properties forKey:UserProperties];
    return data;
}

@end
