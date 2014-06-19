//
//  ApiDataStoreTest.m
//  CalqClient
//
//  Created by Andy Savage on 18/06/2014.
//  Copyright (c) 2014 Calq. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ActionApiCall.h"
#import "ApiDataStore.h"

@interface ApiDataStoreTest : XCTestCase

@end

@implementation ApiDataStoreTest

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

/**
 * Tests that we get the same sharedInstance each time
 */
- (void) testSharedInstance
{
    ApiDataStore *store = [ApiDataStore sharedInstance];
    
    XCTAssertEqualObjects(store, [ApiDataStore sharedInstance], @"Shared instance did not match");
}

/**
 * Tests that an API call be queued.
 */
- (void) testQueueApiCall
{
    ApiDataStore *store = [ApiDataStore sharedInstance];
    
    ActionApiCall *call = [self createDummyActionCall];
    [store addToQueue:call];
}

/**
 * Tests that the call to truncate works correctly (and removes all data). This requires that
 * queing an API call also works, as we need to add some data to test if it was then removed.
 */
- (void) testTruncateEmptiesStore
{
    ApiDataStore *store = [ApiDataStore sharedInstance];
    
    ActionApiCall *call = [self createDummyActionCall];
    [store addToQueue:call];
    
    XCTAssert([store peekQueue:call.writeKey] != nil, "Unable to fetch previously stored call before testing truncate");
    
    XCTAssertTrue([store truncateQueue], @"truncate failed");
    
    QueuedApiCall *peek = [store peekQueue:call.writeKey];
    XCTAssert(peek == nil, @"Data remained in queue after truncate call. Id was %d", [peek callId]);
}

/**
 * Tests that an API call be queued and then the same data read back again. Requires that truncate
 * works as we need an empty queue to guarantee getting back the same API call.
 */
- (void) testQueueThenReadApiCall
{
    ApiDataStore *store = [ApiDataStore sharedInstance];
    [store truncateQueue];
    
    ActionApiCall *call = [self createDummyActionCall];
    [store addToQueue:call];
    
    QueuedApiCall *peek = [store peekQueue:call.writeKey];
    XCTAssertNotNil(peek, @"Call was nil when reading back");
    
    XCTAssertEqualObjects([call payload], [peek payload], @"Queued payload did not match original");
}

/**
 * Tests that an API call be queued and then that data deleted. Requires working truncate, add,
 * and peek from previous tests to work correctly.
 */
- (void) testDeleteApiCall
{
    // Open and truncate so start empty
    ApiDataStore *store = [ApiDataStore sharedInstance];
    [store truncateQueue];
    
    // Add dummy call
    ActionApiCall *call = [self createDummyActionCall];
    [store addToQueue:call];
    
    // Read back so we have queued version with ID
    QueuedApiCall *peek = [store peekQueue:call.writeKey];
    XCTAssertNotNil(peek, @"Call was nil when reading back");
    
    // Delete
    XCTAssertTrue([store deleteFromQueue:peek], @"Failed to delete api call");
   
    // Test the deleted item is no longer in queue
    peek = [store peekQueue:call.writeKey];
    XCTAssert(peek == nil, @"Data remained in queue after deleting call. Id was %d", [peek callId]);
}

/**
 * Creates a dummy action call for use in our tests.
 */
- (ActionApiCall *) createDummyActionCall
{
    return [[ActionApiCall alloc] initWithData:@"TestActor" action:@"Test Action" properties:[[NSDictionary alloc] init] writeKey:@"dummykey_00000000000000000000000"];
}

@end
