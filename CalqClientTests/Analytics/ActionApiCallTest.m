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

#import <XCTest/XCTest.h>
#import "ActionApiCall.h"
#import "ReservedApiProperties.h"

@interface ActionApiCallTest : XCTestCase

@end

@implementation ActionApiCallTest
{
    ActionApiCall * _call;
    
    NSString * _actor;
    NSString * _action;
    NSString * _writeKey;
    NSDate * _date;
    NSMutableDictionary * _properties;
}

#pragma mark Setup / Teardown

- (void) setUp
{
    // Values we use before and to compare after
    _actor = @"TestActor";
    _action = @"Test Action";
    _writeKey = @"dummykey_00000000000000000000000";
    
    // We want a specific date to test format output against (2015-01-01 18:00:00)
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setYear:2015];
    [components setMonth:1];
    [components setDay:1];
    [components setHour:18];
    _date = [calendar dateFromComponents:components];
    
    _properties = [[NSMutableDictionary alloc] init];
    [_properties setObject:@"Test Value" forKey:@"Test Property"];
    
    _call = [[ActionApiCall alloc] initWithDataAndTimestamp:_actor action:_action properties:_properties writeKey:_writeKey timestamp:_date];
    
    [super setUp];
}

- (void) tearDown
{
    [super tearDown];
}

#pragma mark Tests

/**
 * Tests that an end point is actually set.
 */
- (void) testHasEndpoint
{
    XCTAssertNotNil([_call apiEndpoint], @"apiEndpoint was nil");
}

/**
 * Tests that a payload can be generated.
 */
- (void) testHasPayload
{
    XCTAssertNotNil([_call payload], @"payload was nil");
}

/**
 * Tests if the decoded payload matched the properties for this call.
 */
- (void) testPayloadMatchesInput
{
    // Decode payload
     __autoreleasing NSError *error = nil;
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData: [[_call payload] dataUsingEncoding:NSUTF8StringEncoding] options: 0 error: &error];
    XCTAssertNotNil(data, @"Unable to JSON decode generated payload");
    
    XCTAssertEqualObjects(data[Actor], _actor, @"Payload did not match input for %@", Actor);
    XCTAssertEqualObjects(data[ActionName], _action, @"Payload did not match input for %@", ActionName);
    XCTAssertEqualObjects(data[WriteKey], _writeKey, @"Payload did not match input for %@", WriteKey);
    XCTAssertNotNil(data[UserProperties], @"Payload had missing %@ node", UserProperties);
    
    XCTAssertEqualObjects(data[Timestamp], @"2015-01-01T18:00:00.000Z", @"Payload did not match input for %@", Timestamp);
}


@end
