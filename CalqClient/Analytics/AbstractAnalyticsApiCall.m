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
#import "ReservedApiProperties.h"


@interface AbstractAnalyticsApiCall ()

@property NSString * writeKey;
@property NSString * actor;

@end


/**
 * Base class for API calls. Should not be used directly.
 */
@implementation AbstractAnalyticsApiCall

/**
 * Abstract initialisation of class.
 */
- (instancetype) initAbstract:(NSString *)actor writeKey:(NSString *)writeKey
{
    if (self = [self init])
    {
        self.writeKey = writeKey;
        self.actor = actor;
    }
    return self;
}

/**
 * Gets the name of the API endpoint that should be called (such as Track)
 */
- (NSString *) apiEndpoint
{
    // Must be overriden in child classes!
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)] userInfo:nil];
}

/**
 * Gets the JSON payload to be sent to the API server for this call.
 */
- (NSMutableDictionary *) buildJsonPayload
{
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:[self writeKey] forKey:WriteKey];
    [data setObject:self->_actor forKey:Actor];
    return data;
}

/**
 * Gets the JSON payload to be sent to the API server for this call.
 */
- (NSString *) payload
{
    // Serialize the result
    __autoreleasing NSError *error = nil;
    NSMutableDictionary *dict = [AbstractAnalyticsApiCall convertNSDatesToNSStrings:[self buildJsonPayload]];
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error: &error];
    if(data == nil)
    {
        NSLog(@"%@ Failed to create JSON payload for API call - %@", self, [error localizedDescription]);
        return nil;
    }

    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

/**
 * Modifies the given dictionary to convert NSDates to formatted NSStrings so they
 * can be serialized to JSON. Performs modification in place.
 */
+ (NSMutableDictionary *) convertNSDatesToNSStrings:(NSMutableDictionary *)dict
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enPosix = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    
    [dateFormatter setLocale:enPosix];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];    
    
    for (id k in [dict allKeys])
    {
        if ([dict[k] isKindOfClass: [NSDate class]])
        {
            [dict setObject:[dateFormatter stringFromDate:dict[k]] forKey:k];
        }
    }
    
    return dict;
}


@end
