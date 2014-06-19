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

#import "ApiDispatcher.h"

@implementation ApiDispatcher

/**
 * Dispatches the given API call to the remote Calq server.
 *
 * @param apiCall   The api call to dispatch.
 * @return An ApiDispatcherResult indicating whether or not the call was successful.
 */
- (ApiDispatcherResult*) dispatch:(AbstractAnalyticsApiCall*)apiCall
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self urlForApiCall:apiCall]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[[apiCall payload] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setTimeoutInterval:10.0];

    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    ApiDispatcherResult *result = [[ApiDispatcherResult alloc] init];
    
    if (error == nil && [response statusCode] != 500)
    {
        // Got a response. Was it good?
        if ([response statusCode] == 200)
        {
            // Good
            result.success = YES;
        }
        else
        {
            // Api error!
            NSLog(@"Error response from Calq API server - %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            result.apiError = YES;
            result.success = NO;
        }
    }
    else
    {
        // Connection error, or internal server. Don't set api state
        result.success = NO;
    }
    
    // OK if we got here
    return result;
}

/**
 * Gets the end point URL for the given API call.
 */
- (NSString*) urlForApiCall:(AbstractAnalyticsApiCall*)apiCall
{
    static NSString *apiServer = @"https://api.calq.io/";
    NSMutableString *url = [[NSMutableString alloc] initWithString:apiServer];
    if (![apiServer hasSuffix:@"/"])
    {
        [url appendString:@"/"];
    }
    [url appendString:[apiCall apiEndpoint]];
    
    return url;
}

@end


/**
 * Helper class for state from dispatch call.
 */
@implementation ApiDispatcherResult


@end
