//
//  QueuedApiCallTest.m
//  CalqClient
//
//  Created by Andy Savage on 18/06/2014.
//  Copyright (c) 2014 Calq. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "QueuedApiCall.h"

@interface QueuedApiCallTest : XCTestCase

@end

@implementation QueuedApiCallTest

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

/**
 * Tests that the saved data put into a QueuedApiCall is the same as we get out.
 */
- (void)testInputMatchesOutput
{
    int callId = arc4random() % 100000;
    NSString *endpoint = @"FakeEnpoint";
    NSString *payload = @"{}";
    NSString *writeKey = @"dummykey_00000000000000000000000";
    
    QueuedApiCall *call = [[QueuedApiCall alloc] initWithId:callId endpoint:endpoint payload:payload writeKey:writeKey];
    
    XCTAssertEqual(callId, [call callId], @"Input did not match output for callId");
    
    XCTAssertEqualObjects([call apiEndpoint], endpoint, @"Input did not match output for endpoint");
    XCTAssertEqualObjects([call payload], payload, @"Input did not match output for payload");
    XCTAssertEqualObjects([call writeKey], writeKey, @"Input did not match output for writeKey");
}

@end
