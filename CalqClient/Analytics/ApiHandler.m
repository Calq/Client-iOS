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

#import "ApiHandler.h"
#import "ApiDataStore.h"
#import "ApiDispatcher.h"

/**
 * Handles API requests as they are produced. This includes flushing them to local storage in the background,
 * as well as sending calls to the dispatcher to be sent to Calq.
 */
@implementation ApiHandler
{
    /**
     * Queue of api calls we have accepted but not yet written to storage.
     */
    NSMutableArray * _receiveQueue;
    
    /**
     * Operation queue we use to schedule flushes for (seperate threads)
     */
    NSOperationQueue * _operations;
    
    /**
     * Operation queue we use to shecdule flushes for (seperate threads)
     */
    ApiDataStore * _store;
    
    /**
     * Operation queue we use to shecdule flushes for (seperate threads)
     */
    ApiDispatcher * _dispatcher;
    
    /**
     * Write key we are handling calls for.
     */
    NSString * _writeKey;
    
    /**
     * Timer we use to dispatch events on intervals (default is 60s)
     */
    NSTimer * _dispatchTimer;
}

/**
 * Gets a shared instance of an ApiHandler for the given write key.
 *
 * @param writeKey  The write key to get an ApiHandler for.
 */
+ (ApiHandler *) sharedInstanceWithKey:(NSString *)writeKey
{
    NSAssert(writeKey != nil, @"writeKey must not be nil when calling [ApiHandler sharedInstanceWithKey]");
    
    @synchronized(self)
    {
        static NSMutableDictionary *handlers = nil;
        if (handlers == nil)
        {
            handlers = [[NSMutableDictionary alloc] init];
        }
        
        ApiHandler *handler = [handlers objectForKey:writeKey];
        if (handler == nil)
        {
            handler = [[ApiHandler alloc] init:writeKey];
            [handlers setObject:handler forKey:writeKey];
        }
        
        return handler;
    }
}

- (instancetype) init:(NSString*)writeKey
{
    if (self = [super init])
    {
        self->_receiveQueue = [[NSMutableArray alloc] init];
        self->_operations = [[NSOperationQueue alloc] init];
        self->_store = [ApiDataStore sharedInstance];
        self->_dispatcher = [[ApiDispatcher alloc] init];
        self->_writeKey = writeKey;
        self->_dispatchTimer = nil;
        
        // Might be left over from last session
        [self scheduleDispatch];
    }
    return self;
}

/**
 * Enqueues the given API call. This will put the call in a local queue and control will return to the
 * caller immediately. The local queue is then persisted periodically in the background to local storage.
 *
 * On a schedule (default every 60s) all queued calls will be batched and sent to Calq. This means there
 * may be a delay between enqueing an API call and it showing in the reporting interface. If there is a
 * communication issue (such as signal loss) then the API calls will be retried later.
 */
- (void) enqueue:(AbstractAnalyticsApiCall *)apiCall
{
    @synchronized(_receiveQueue)
    {
        [_receiveQueue addObject:apiCall];
    }
    
    // Write to queue to store in BG thread
    [_operations addOperationWithBlock:
    ^{
        [self persistQueue];
    }];
    
    [self scheduleDispatch];
}

/**
 * Writes the current pending queue to persistent storage. Will write all items and will block whilst
 * writing happens.
 */
- (void) persistQueue
{
    while([_receiveQueue count] > 0)
    {
        AbstractAnalyticsApiCall *call = nil;
        
        // Only need to lock whilst we remove the bottom item
        @synchronized(_receiveQueue)
        {
            if ([_receiveQueue count] > 0)
            {
                call = _receiveQueue[0];
                [_receiveQueue removeObjectAtIndex:0];
            }
        }
        
        [_store addToQueue:call];
    }
}

/**
 * Sends all currently queued API calls for dispatch to the Calq HTTP API.
 */
- (BOOL) sendQueuedForDispatch
{
    BOOL allCallsSucceeded = YES;
    
    @synchronized(_store)
    {
        // Eat until we run out
        QueuedApiCall *apiCall = nil;
        while (nil != (apiCall = [_store peekQueue:_writeKey]))
        {
            ApiDispatcherResult *result = [_dispatcher dispatch:apiCall];
            if(result.success || result.apiError)
            {
                // We delete if the call went through, or it was an api error (which we can't replay anyway)
                [_store deleteFromQueue:apiCall];
                if (result.apiError)
                {
                    allCallsSucceeded = NO;
                }
            }
            else
            {
                // Don't peek again. Try again next schedule
                allCallsSucceeded = NO;
                break;
            }
        }
    }
    
    // Reschedule again if needed
    if(!allCallsSucceeded)
    {
        [self scheduleDispatch];
    }
    return allCallsSucceeded;
}

/**
 * Requests that any outstanding API calls are flushed immediately (they will still be queued however if
 * there is a connectivity problem). This will block until complete.
 *
 * @return YES if all actions flushed. NO if some failed (either API error or connection).
 */
- (BOOL) forceFlush
{
    [self persistQueue];
    return [self sendQueuedForDispatch];
}

/**
 * Requests that a dispatch happens. If one is already scheduled then it is ignored
 */
- (void) scheduleDispatch
{
    if(self->_dispatchTimer == nil)
    {
        self->_dispatchTimer = [NSTimer scheduledTimerWithTimeInterval:60.0f target:self selector:@selector(onDispatchTimer) userInfo:nil repeats:NO];
    }
}

/**
 * Triggers when the dispatch timer ticks.
 */
- (void) onDispatchTimer
{
    self->_dispatchTimer = nil;
    
    [_operations addOperationWithBlock:
     ^{
         [self sendQueuedForDispatch];
     }];
}


@end
