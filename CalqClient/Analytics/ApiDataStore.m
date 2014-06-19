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

#import "ApiDataStore.h"
#import <sqlite3.h>

#define _CALQ_DB_FILENAME @"calq.db"
#define _CALQ_DB_TABLE_APIQUEUE @"api_queue"

@implementation ApiDataStore
{
    /**
     * The DB instance this store uses (and normally we only have one ApiDataStore instance).
     */
    sqlite3 * _db;
    
    /**
     * Prepared statement to insert api calls.
     */
    sqlite3_stmt * _insertApiStmt;
    
    /**
     * Prepared statement to peek for the next available API call.
     */
    sqlite3_stmt * _peekApiStmt;
    
    /**
     * Prepared statement to delete call from queue.
     */
    sqlite3_stmt * _deleteApiStmt;
}

- (instancetype) init
{
    if (self = [super init])
    {
        [self createDbIfRequired];
        if(sqlite3_open([[self databasePath] UTF8String], &self->_db) != SQLITE_OK)
        {
            NSLog(@"%@ Failed to open database", self);
            return nil;
        }
    }
    return self;
}

/**
 * Gets the shared instance of this ApiDataStore. Typically this is the method that you would use
 * rather than init because the DB is shared.
 */
+ (ApiDataStore *) sharedInstance
{
    static ApiDataStore *singleton = nil;
    @synchronized([ApiDataStore class])
    {
        if (singleton == nil)
        {
            singleton = [[ApiDataStore alloc] init];
        }
        return singleton;
    }
}

#pragma mark CRUD operations

/**
 * Adds the given API call to the queue.
 *
 * @param apiCall		The call to add to the queue.
 */
- (BOOL) addToQueue:(AbstractAnalyticsApiCall*)apiCall
{
    @synchronized([ApiDataStore class])
    {
        if(self->_insertApiStmt == nil)
        {
            const char *insertSql = [[NSString stringWithFormat: @"INSERT INTO %@ (write_key, endpoint, payload) VALUES (?, ?, ?)", _CALQ_DB_TABLE_APIQUEUE] UTF8String];
            
            if(sqlite3_prepare_v2(self->_db, insertSql, -1, &self->_insertApiStmt, NULL) != SQLITE_OK)
            {
                self->_insertApiStmt = nil; // So we try again next time
                NSLog(@"%@ Failed to prepare insert", self);
                return NO;
            }
        }
        else
        {
            // Need to reset before reuse next time
            sqlite3_reset(self->_insertApiStmt);
        }
        
        if(sqlite3_bind_text(self->_insertApiStmt, 1, [[apiCall writeKey] UTF8String], -1, SQLITE_TRANSIENT) != SQLITE_OK)
        {
            return NO;
        }
        if(sqlite3_bind_text(self->_insertApiStmt, 2, [[apiCall apiEndpoint] UTF8String], -1, SQLITE_TRANSIENT) != SQLITE_OK)
        {
            return NO;
        }
        if(sqlite3_bind_text(self->_insertApiStmt, 3, [[apiCall payload] UTF8String], -1, SQLITE_TRANSIENT) != SQLITE_OK)
        {
            return NO;
        }
        
        return (sqlite3_step(self->_insertApiStmt) == SQLITE_DONE);
    }
}

/**
 * Gets the next API message from the queue (doesn't remove from queue).
 *
 * @param writeKey		The writeKey to peek for queued calls for.
 */
- (QueuedApiCall *) peekQueue:(NSString*)writeKey
{
    @synchronized([ApiDataStore class])
    {
        if(self->_peekApiStmt == nil)
        {
            const char *peekSql = [[NSString stringWithFormat: @"SELECT id, write_key, endpoint, payload FROM %@ WHERE write_key = ? ORDER BY id ASC LIMIT 1", _CALQ_DB_TABLE_APIQUEUE] UTF8String];
            
            if(sqlite3_prepare_v2(self->_db, peekSql, -1, &self->_peekApiStmt, NULL) != SQLITE_OK)
            {
                self->_peekApiStmt = nil; // So we try again next time
                NSLog(@"%@ Failed to prepare peek select", self);
                return nil;
            }
        }
        else
        {
            // Need to reset before reuse next time
            sqlite3_reset(self->_peekApiStmt);
        }
        
        if(sqlite3_bind_text(self->_peekApiStmt, 1, [writeKey UTF8String], -1, SQLITE_TRANSIENT) != SQLITE_OK)
        {
            return nil;
        }
        
        if(sqlite3_step(self->_peekApiStmt) == SQLITE_ROW)
        {
            int resultId = sqlite3_column_int(self->_peekApiStmt, 0);
            char *resultWriteKey = (char *) sqlite3_column_text(self->_peekApiStmt, 1);
            char *resultEndpoint = (char *) sqlite3_column_text(self->_peekApiStmt, 2);
            char *resultPayload = (char *) sqlite3_column_text(self->_peekApiStmt, 3);
            
            return [[QueuedApiCall alloc] initWithId:resultId
                    endpoint:[[NSString alloc] initWithUTF8String:resultEndpoint]
                    payload:[[NSString alloc] initWithUTF8String:resultPayload]
                    writeKey:[[NSString alloc] initWithUTF8String:resultWriteKey]];
        }
        else
        {
            // No data!
            return nil;
        }
    }
}

/**
 * Removes the given QueuedApiCall from the queue.
 *
 * @param apiCall		The previously queued API call to remove.
 */
- (BOOL) deleteFromQueue:(QueuedApiCall*)apiCall
{
    @synchronized([ApiDataStore class])
    {
        if(self->_deleteApiStmt == nil)
        {
            const char *delete = [[NSString stringWithFormat: @"DELETE FROM %@ WHERE id = ?", _CALQ_DB_TABLE_APIQUEUE] UTF8String];
            
            if(sqlite3_prepare_v2(self->_db, delete, -1, &self->_deleteApiStmt, NULL) != SQLITE_OK)
            {
                self->_deleteApiStmt = nil; // So we try again next time
                NSLog(@"%@ Failed to prepare delete", self);
                return NO;
            }
        }
        else
        {
            // Need to reset before reuse next time
            sqlite3_reset(self->_deleteApiStmt);
        }
        
        if(sqlite3_bind_int(self->_deleteApiStmt, 1, [apiCall callId]) != SQLITE_OK)
        {
            return NO;
        }
        
        return (sqlite3_step(self->_deleteApiStmt) == SQLITE_DONE);
    }
}

/**
 * Empties the current queue. Not normally used outside of testing.
 */
- (BOOL) truncateQueue
{
    @synchronized([ApiDataStore class])
    {
        const char * truncateSql = [[NSString stringWithFormat: @"DELETE FROM %@", _CALQ_DB_TABLE_APIQUEUE] UTF8String];
        
        char * errorMsg = nil;
        if(sqlite3_exec(self->_db, truncateSql, NULL, NULL, &errorMsg) != SQLITE_OK)
        {
            NSLog(@"%@ Failed during truncateQueue - %s", self, errorMsg);
            return NO;
        }
        return YES;
    }
}

#pragma mark Schema operations

/**
 * Creates the DB to persist API calls if required.
 */
- (BOOL) createDbIfRequired
{
    @synchronized([ApiDataStore class])
    {
        BOOL success = YES;
        NSString *databasePath = [self databasePath];
        NSFileManager *filemgr = [NSFileManager defaultManager];
        if (![filemgr fileExistsAtPath: databasePath])
        {
            const char *dbpath = [databasePath UTF8String];
            sqlite3 *newDb = nil;
            if (sqlite3_open(dbpath, &newDb) == SQLITE_OK)
            {
                success = [self createSchema:newDb];
                sqlite3_close(newDb);
            }
            else
            {
                success = NO;
                NSLog(@"%@ Failed to create database for persistence (or confirm an existing one)", self);
            }
        }
        return success;
    }
}

/**
 * Gets the path to the DB.
 */
- (NSString *) databasePath
{
    // Get the documents directory
    NSString *docsDir;
    NSArray *dirPaths;
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    
    // Build the path to the database file
    return [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent: _CALQ_DB_FILENAME]];
}

/**
 * Creates the database schema needed by the store.
 *
 * @param db    The db to create the schema on.
 */
- (BOOL) createSchema:(sqlite3*)db;
{
    const NSString *create = [NSString stringWithFormat:
        @"CREATE TABLE %@ (  \
            id INTEGER PRIMARY KEY, \
            write_key VARCHAR(32), \
            endpoint VARCHAR(64), \
            payload TEXT \
        )", _CALQ_DB_TABLE_APIQUEUE];
    
    char *errorMsg;
    if (!sqlite3_exec(db, [create UTF8String], NULL, NULL, &errorMsg) == SQLITE_OK)
    {
        NSLog(@"%@ unable to create schema: %s", self, errorMsg);
        return NO;
    }
    return YES;
}


@end
