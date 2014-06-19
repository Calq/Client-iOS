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

#if ! __has_feature(objc_arc)
#error CalqClient must be compiled with ARC. Turn on ARC for the project or use -fobjc-arc on Calq's files.
#endif

#import "CalqClient.h"
#import "Analytics/ReservedActionProperties.h"
#import "Analytics/ApiHandler.h"
#import "Analytics/ActionApiCall.h"
#import "Analytics/ProfileApiCall.h"
#import "Analytics/TransferApiCall.h"

@interface CalqClient ()

/**
 * The unique Id of the actor used by this instance.
 */
@property NSString *actor;

@end

@implementation CalqClient
{
	/**
	 * If this client is anonymous or not.
	 */
	BOOL _isAnon;
    
    /**
     * If this client has sent an action before.
     */
    BOOL _hasTracked;
    
	/**
	 * Map of global properties for this session.
	 */
	NSMutableDictionary *_globalProperties;
    
	/**
	 * The ApiHandler we use to process API calls.
	 */
	ApiHandler *_apiHandler;
    
	/**
	 * The write key in use by this client.
	 */
	NSString *_writeKey;
}

#pragma mark Client init

/**
 * Singleton shared instance if desired.
 */
static CalqClient *client = nil;

/**
 * Attempts to create a CalqClient from previously saved data (includes identity and
 * super properties). If no previous data is found then a new client will be created.
 *
 * <p>This method stores the client as a singleton and can be used to fetch clients
 * around the app without re-creating them. Alternatively you can pass your CalqClient
 * instance around.
 *
 * <p>In order to save battery API calls are queued and batched together. There may be
 * a delay between making a call here and it being sent to Calq's API server. You can
 * call flushQueue if you want to force all pending calls to be sent immediately.
 *
 * @param writeKey		The write key to use when communicating with the API.
 * @return a new CalqClient instance either populated with the previous session data
 * 		 or with a new anonymous user Id (a blank session).
 */
+ (CalqClient *) initSharedInstanceWithKey:(NSString *)writeKey
{
    @synchronized(self)
    {
        if (client == nil)
        {
            client = [[CalqClient alloc] initWithKey:writeKey];
        }
        else
        {
            if(![writeKey isEqualToString:client->_writeKey])
            {
                NSLog(@"%@ Shared instance was already created but with different writeKey! Using first instance.", self);
            }
        }
       
        return client;
    }
}

/**
 * Gets the shared instance previously created with initSharedInstanceWithKey
 */
+ (CalqClient *) sharedInstance
{
    NSAssert(client != nil, @"You must call initSharedInstanceWithKey before using sharedInstance");    // Fire this in dev
    
    if(client == nil)
    {
        NSLog(@"%@ You must call initSharedInstanceWithKey before using sharedInstance", self);
    }
    return client;
}

/**
 * Creates a new CalqClient instance directly by specifying a write key to communicate with 
 * the API server. Typically you would not call this directly but use the sharedInstanceWithKey
 * method instead.  
 *
 * @param writeKey		The write key to use when communicating with the API.
 */
- (instancetype) initWithKey:(NSString *)writeKey
{
    return [self initWithKey:writeKey loadState:YES];
}

/**
 * Creates a new CalqClient instance directly by specifying a write key to communicate with
 * the API server. Typically you would not call this directly but use the sharedInstanceWithKey
 * method instead.
 *
 * @param writeKey		The write key to use when communicating with the API.
 * @param loadState     Whether or not to load any previous client state.
 */
- (instancetype) initWithKey:(NSString *)writeKey loadState:(BOOL)loadState
{
    NSAssert(writeKey != nil && [writeKey length] >= 32, @"a valid writeKey must be specified");
    
    // Check again (for assert stripped in release)
    if (writeKey == nil || [writeKey length] < 32)
    {
        NSLog(@"%@ A valid writeKey must be specified when calling initWithKey", self);
        return nil;
    }
    
    if (self = [self init])
    {
		self.actor = [self generateAnonymousId];    // Will get real id later if saved
        self->_writeKey = writeKey;
		self->_globalProperties = [[NSMutableDictionary alloc] init];
		self->_isAnon = YES;
		self->_hasTracked = NO;
        
        if(loadState)
        {
            [self loadState];
        }
        [self populateDeviceProperties];    // After load state so we overwrite
        
        _apiHandler = [ApiHandler sharedInstanceWithKey:writeKey];
        
        // We want to flush when app is going to be terminated
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        [notificationCenter addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

#pragma mark Client state persistence

static NSString * ClientStateKeyActor = @"actor";
static NSString * ClientStateKeyIsAnon = @"isAnon";
static NSString * ClientStateKeyHasTracked = @"hasTracked";
static NSString * ClientStateKeyGlobalProperties = @"globalProperties";

/**
 * Populates the CalqClient with data saved from a previous session.
 */
- (void) loadState
{
    @synchronized(self)
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        // Test as we go so this is OK to upgrade later
        self.actor = [userDefaults stringForKey:ClientStateKeyActor] ?: self.actor;
        _isAnon = [userDefaults objectForKey:ClientStateKeyIsAnon] != nil ? [userDefaults boolForKey:ClientStateKeyIsAnon] : _isAnon;
        _hasTracked = [userDefaults objectForKey:ClientStateKeyHasTracked] != nil ? [userDefaults boolForKey:ClientStateKeyHasTracked] : _hasTracked;

        // Need to copy this to mutable if present
        NSDictionary *globalProperties = [userDefaults objectForKey:ClientStateKeyGlobalProperties];
        if (globalProperties != nil)
        {
            _globalProperties = [[NSMutableDictionary alloc] initWithDictionary:globalProperties];;
        }
    }
}

/**
 * Persists the current client state to storage. Called internally by methods that
 * update client state.
 */
- (void) persistState
{
    @synchronized(self)
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        [userDefaults setObject:self.actor forKey:ClientStateKeyActor];
        [userDefaults setBool:_isAnon forKey:ClientStateKeyIsAnon];
        [userDefaults setBool:_hasTracked forKey:ClientStateKeyHasTracked];
        [userDefaults setObject:_globalProperties forKey:ClientStateKeyGlobalProperties];
        
        [userDefaults synchronize];
    }
}

#pragma mark Public API methods

/**
 * Tracks the given action.
 *
 * <p>Calq performs analytics based on actions that you send it, and any custom data
 * associated with that action. This call is the core of the analytics platform.
 *
 * <p>All actions have an action name, and some optional data to send along with it.
 *
 * <p>This method will pass data to a background worker and continue ASAP. It will not
 * block whilst API calls to Calq servers are made.
 *
 * @param action        The name of the action to track.
 * @param properties    Any optional properties to include along with this action.
 *      Can be nil.
 */
- (void) track:(NSString *)action properties:(NSDictionary *)properties
{
    if (action == nil || [action length] == 0)
    {
        NSLog(@"%@ An empty action was given to track.", self);
        return;
    }

    if (properties == nil)
    {
        properties = [[NSDictionary alloc] init];
    }
    
    if([CalqClient checkPropertyTypes:properties])
    {
        NSMutableDictionary *mergedProperties = [[NSMutableDictionary alloc] initWithDictionary:_globalProperties];
        [mergedProperties addEntriesFromDictionary:properties];

        [self enqueueApiCall:[[ActionApiCall alloc] initWithData:self.actor action:action properties:mergedProperties writeKey:self->_writeKey]];
  
        if (!_hasTracked)
        {
            _hasTracked = YES;
            [self persistState];
        }
    }
}

/**
 * Tracks the given action which has associated revenue.
 *
 * @param action        The name of the action to track.
 * @param properties    Any optional properties to include along with this action.
 * @param currency      The 3 letter currency code for this sale (can be fictional).
 * @param amount        The amount this sale is worth (can be negative for refunds).
 */
- (void) trackSale:(NSString *)action properties:(NSDictionary *)properties currencyCode:(NSString *)currency value:(NSDecimalNumber *)value
{
    if (currency == nil || [currency length] != 3)
    {
        NSLog(@"%@ When calling trackSale the 'currency' parameter must be a 3 letter currency code (fictional or otherwise).", self);
        return;
    }

    NSMutableDictionary *mergedProperties = [[NSMutableDictionary alloc] init];
    if (properties != nil)
    {
        [mergedProperties addEntriesFromDictionary:properties];
    }
    [mergedProperties setObject:currency forKey:SaleCurrency];
    [mergedProperties setObject:value forKey:SaleValue];
    
    [self track:action properties:mergedProperties];
}

/**
 * Sets a global property to be sent with all future actions when using
 * {@link #track(String, Map)}. Will be persisted to client for future. If a value
 * has been already set then it will be overwritten.
 *
 * @param property      The name of the property to set.
 * @param value         The value of the new global property.
 */
- (void) setGlobalProperty:(NSString *)property value:(id)value
{
    if(property == nil || [property length] == 0)
    {
        NSLog(@"%@ 'property' parameter can not be null or empty when calling setGlobalProperty.", self);
        return;
    }
    if(value == nil || [property length] == 0)
    {
        NSLog(@"%@ 'value' parameter can not be null when calling setGlobalProperty.", self);
        return;
    }
    if (!([CalqClient checkValueTypes:value]))
    {
        NSLog(@"%@ 'value' parameter must be either NSString, NSNumber, NSNull, NSDictionary, NSDate or NSURL when calling setGlobalProperty. Got: %@ %@", self, [value class], value);
        return;
    }

    [_globalProperties setObject:value forKey:property];
    [self persistState];
}

/**
 * Sets the ID of this client to something else. This should be called if you register or
 * sign-in a user and want to associate previously anonymous actions with this new identity.
 *
 * <p>This should only be called once for a given user. Calling identify again with a
 * different Id for the same user will result in an exception being thrown.
 *
 * @param actor         The new unique actor Id.
 */
- (void) identify:(NSString *)actor
{
    @synchronized(self)
    {
        if (![actor isEqualToString:self.actor])
        {
            if (!_isAnon)
            {
                NSLog(@"%@ identify has already been called for this actor.", self);
                return;
            }
            
            NSString *oldActor = self.actor;
            self.actor = actor;
            
            if(_hasTracked)
            {
                [self enqueueApiCall:[[TransferApiCall alloc] initWithData:oldActor newActor:self.actor writeKey:self->_writeKey]];
            }
            
            _isAnon = NO;
            _hasTracked = NO;
            [self persistState];
        }
    }
}

/**
 * Sets profile properties for the current user. These are not the same as global properties.
 * A user MUST be identified before calling profile else an exception will be thrown.
 *
 * @param properties	The custom properties to set for this user. If a property with the
 * 		same name already exists then it will be overwritten.
 */
- (void) profile:(NSDictionary *)properties
{
    if (properties == nil || [properties count] == 0)
    {
        NSLog(@"%@ You must pass some properties when calling profile.", self);
        return;
    }
    if(_isAnon)
    {
        NSLog(@"%@ A client must be identified (call identify) before calling profile.", self);
        return;
    }
    
    [self enqueueApiCall:[[ProfileApiCall alloc] initWithData:self.actor properties:properties writeKey:self->_writeKey]];
}

/**
 * Clears the current session and resets to being an anonymous user.
 * You should generally call this if a user logs out of your application.
 */
- (void) clear
{
    @synchronized (self)
    {
        self.actor = [self generateAnonymousId];
        _hasTracked = false;
        _isAnon = true;
        _globalProperties = [[NSMutableDictionary alloc] init];
        
        [self persistState];
    }
}

/**
 * Asks the CalqClient to flush any API calls which are currently queued. Normally this
 * is done in the background for you (calls are grouped together to save battery). This
 * will block until complete.
 *
 * @return YES if all actions flushed. NO if some failed (either API error or connection).
 */
- (BOOL) flushQueue
{
    return [_apiHandler forceFlush];
}

#pragma mark Internal API methods

/**
 * Passes the given API call to the ApiHandler to process.
 * @param apiCall   The api call to process.
 */
- (void) enqueueApiCall:(AbstractAnalyticsApiCall *)apiCall
{
    [_apiHandler enqueue:apiCall];
}

/**
 * Handles when the application is about to terminate.
 */
- (void) applicationWillTerminate:(NSNotification *)notification
{
    [self flushQueue];
}

/**
 * Reads the info for the current device that we set every time automatically.
 */
- (void) populateDeviceProperties
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    [self setGlobalProperty:DeviceResolution value:[NSString stringWithFormat:@"%gx%g", size.width, size.height]];
 
    [self setGlobalProperty:DeviceOs value:@"iOS"];
    
    [self setGlobalProperty:DeviceMobile value:@"true"];
    
    [self setGlobalProperty:DeviceAgent value:[NSString stringWithFormat:@"%@, %@, %@", [UIDevice currentDevice].model, [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion]];
}


#pragma mark Util methods

/**
 * Generates a new anonymous Id to identify a user.
 */
- (NSString *) generateAnonymousId
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    
    return uuidStr;
}

/**
 * Checks the given properties collection for value types we support.
 */
+ (BOOL)checkPropertyTypes:(NSDictionary *)properties
{
    for (id k in properties)
    {
        if (![k isKindOfClass: [NSString class]])
        {
            NSLog(@"%@ property keys must be NSString. Got: %@ %@", self, [k class], k);
            return NO;
        }
        
        if (!([CalqClient checkValueTypes:properties[k]]))
        {
            NSLog(@"%@ property values must be either NSString, NSNumber, NSNull, NSDictionary, NSDate or NSURL. Got: %@ %@", self, [properties[k] class], properties[k]);
            return NO;
        }
    }
    
    // Valid if here
    return YES;
}


/**
 * Checks the given value to see if it's a type we support.
 */
+ (BOOL)checkValueTypes:(id)value
{
    return  [value isKindOfClass:[NSString class]] ||
            [value isKindOfClass:[NSNumber class]] ||
            [value isKindOfClass:[NSNull class]] ||
            [value isKindOfClass:[NSDictionary class]] ||
            [value isKindOfClass:[NSDate class]] ||
            [value isKindOfClass:[NSURL class]];
}

@end
