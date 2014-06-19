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
#import "ApiDispatcher.h"
#import "ActionApiCall.h"

@interface ApiDispatcherTest : XCTestCase

@end

@implementation ApiDispatcherTest

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

/**
 * Tests that calling the API with an invalid key (but valid everything else) correctly sets the API error flag.
 */
- (void)testApiErrorForInvalidKey
{
    ActionApiCall *action = [[ActionApiCall alloc] initWithData:@"TestActor" action:@"Test Action" properties:[[NSDictionary alloc] init] writeKey:@"bad_key"];
    
    ApiDispatcher *dispatcher = [[ApiDispatcher alloc] init];
    ApiDispatcherResult *result = [dispatcher dispatch:action];
    
    XCTAssertFalse(result.success, @"result.success should be false (bad api key)");
    XCTAssertTrue(result.isApiError, @"result.isApiErrpr should have been true (bad api key)");
}

@end
