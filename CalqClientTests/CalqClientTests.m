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
#import "CalqClient.h"
#import "ApiDataStore.h"

#include <stdlib.h>

@interface CalqClientTests : XCTestCase

@end

@implementation CalqClientTests
{
    NSString * _writeKey;
}

- (void) setUp
{
    _writeKey = @"55ebeaebfcd351e0b69e6cc99dbb081d";
    
    [super setUp];
}

- (void) tearDown
{
    // Make sure we empty the store of queued events
    ApiDataStore *store = [ApiDataStore sharedInstance];
    [store truncateQueue];
    
    [super tearDown];
}

/**
 * Tests creating CalqClient instances and that the sharedInstance is populated correctly.
 */
- (void) testClientSharedInstance
{
    CalqClient *calq = [CalqClient initSharedInstanceWithKey:_writeKey];
    XCTAssertNotNil(calq, @"Unable to create CalqClient instance via initSharedInstanceWithKey");
    
    XCTAssert(calq == [CalqClient sharedInstance], @"sharedInstance did not match new instance");
}

/**
 * Tests that identify is updating the instance.
 */
- (void) testIdentifyUpdatesInstance
{
    NSString *identity = [CalqClientTests generateTestActor];
    
    CalqClient *calq = [[CalqClient alloc] initWithKey:_writeKey loadState:NO];
    [calq identify:identity];
    
    XCTAssertEqualObjects([calq actor], identity, "Actor was not updated after calling identify");
}

/**
 * Tests that calling identify twice doesn't update the 2nd time
 */
- (void) testIdentifyFailsOnMultipleCalls
{
    CalqClient *calq = [[CalqClient alloc] initWithKey:_writeKey loadState:NO];
    
    NSString *identity = [CalqClientTests generateTestActor];
    [calq identify:identity];
    
    NSString *again = [CalqClientTests generateTestActor];
    [calq identify:again];
    
    XCTAssertEqualObjects([calq actor], identity, "Actor was not original after second identify call");
}

/**
 * Tests that state is saved and loaded between different instances.
 */
- (void) testStatePersistence
{
    CalqClient *first = [[CalqClient alloc] initWithKey:_writeKey loadState:NO];
    [first identify:@"TestActor"];
    
    CalqClient *second = [[CalqClient alloc] initWithKey:_writeKey];
    
    XCTAssertNotEqualObjects(first, second, "CalqClient instances were the same");
    
    XCTAssertEqualObjects([first actor], [second actor], "Actor was not the same between saved sessions");
}

/**
 * Does a full test from raising an event and sending it to Calq. This test requires you give it a valid
 * Calq writeKey or it will not be able to send data.
 */
- (void) testEndToEndApiCalls
{
    CalqClient *calq = [[CalqClient alloc] initWithKey:_writeKey loadState:NO];
    
    [calq track:@"Obj-C Test Action (Anon)" properties:[[NSDictionary alloc] init]];
    
    [calq identify:[CalqClientTests generateTestActor]];
    
    NSMutableDictionary * actionProperties = [[NSMutableDictionary alloc] init];
    [actionProperties setObject:@"Test Value" forKey:@"Test Property"];
    [calq track:@"Obj-C Test Action" properties:actionProperties];
    
    [calq trackSale:@"Obj-C Test Sale" properties:[[NSDictionary alloc] init] currencyCode:@"USD" value:[[NSDecimalNumber alloc] initWithDouble:100.00]];
    
    NSMutableDictionary * userProperties = [[NSMutableDictionary alloc] init];
    [userProperties setObject:@"test@notarealemail.com" forKey:@"$email"];
    [userProperties setObject:[calq actor] forKey:@"$full_name"];
    [calq profile:userProperties];
    
    XCTAssertTrue([calq flushQueue], @"Unable to send all API calls");
}

/**
 * Generates a test actor id.
 */
+ (NSString *) generateTestActor
{
    int random = arc4random() % 100000;
    return [NSString stringWithFormat:@"TestActor%d", random];
}

@end
