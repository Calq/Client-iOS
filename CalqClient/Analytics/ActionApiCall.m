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

#import "ActionApiCall.h"
#import "ReservedApiProperties.h"

@implementation ActionApiCall
{
    /**
	 * The date time of when this call was created.
	 */
	NSDate * _createdAt;
    
	/**
	 * The action being performed.
	 */
	NSString * _action;
    
	/**
	 * The custom properties sent with this action.
	 */
	NSDictionary * _properties;
}

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
- (instancetype) initWithDataAndTimestamp:(NSString *)actor action:(NSString *)action properties:(NSDictionary *)properties writeKey:(NSString *)writeKey timestamp:(NSDate *)timestamp
{
    if (self = [[self init] initAbstract:actor writeKey:writeKey])
    {
        self->_action = action;
        self->_properties = properties;
        
        self->_createdAt = timestamp;
    }
    return self;
    
}

/**
 * Initialises a new ActionApiCall describing an action. This will be passed to the
 * /track/ API endpoint.
 *
 * @param actor				The actor performing this action.
 * @param action			The action being performed.
 * @param properties		Any custom properties related to this action. Can be empty, but not nil.
 * @param writeKey			The write key to use for this API call.
 */
- (instancetype) initWithData:(NSString *)actor action:(NSString *)action properties:(NSDictionary *)properties writeKey:(NSString *)writeKey
{
    return [self initWithDataAndTimestamp:actor action:action properties:properties writeKey:writeKey timestamp:[[NSDate alloc] init]];
}

/**
 * Gets the name of the API endpoint that should be called (such as Track)
 */
- (NSString *) apiEndpoint
{
    static NSString *endpoint = @"Track";
    return endpoint;
}

/**
 * Gets the JSON payload to be sent to the API server for this call.
 */
- (NSMutableDictionary *) buildJsonPayload
{
    NSMutableDictionary *data = [super buildJsonPayload];
    [data setObject:self->_createdAt forKey:Timestamp];
    [data setObject:self->_action forKey:ActionName];
    [data setObject:self->_properties forKey:UserProperties];
    return data;
}

@end
