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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CalqClient : NSObject

/**
 * The actor represented by this client
 */
@property (readonly) NSString *actor;

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
+ (CalqClient *) initSharedInstanceWithKey:(NSString *)writeKey;

/**
 * Gets the shared instance previously created with initSharedInstanceWithKey
 */
+ (CalqClient *) sharedInstance;

/**
 * Creates a new CalqClient instance directly by specifying a write key to communicate with
 * the API server. Typically you would not call this directly but use the sharedInstanceWithKey
 * method instead.
 *
 * @param writeKey		The write key to use when communicating with the API.
 */
- (instancetype) initWithKey:writeKey;

/**
 * Creates a new CalqClient instance directly by specifying a write key to communicate with
 * the API server. Typically you would not call this directly but use the sharedInstanceWithKey
 * method instead.
 *
 * @param writeKey		The write key to use when communicating with the API.
 * @param loadState     Whether or not to load any previous client state.
 */
- (instancetype) initWithKey:(NSString *)writeKey loadState:(BOOL)loadState;

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
- (void) track:(NSString *)action properties:(NSDictionary *)properties;

/**
 * Tracks the given action which has associated revenue.
 *
 * @param action        The name of the action to track.
 * @param properties    Any optional properties to include along with this action.
 * @param currency      The 3 letter currency code for this sale (can be fictional).
 * @param amount        The amount this sale is worth (can be negative for refunds).
 */
- (void) trackSale:(NSString *)action properties:(NSDictionary *)properties currencyCode:(NSString *)currency value:(NSDecimalNumber *)value;

/**
 * Sets a global property to be sent with all future actions when using
 * {@link #track(String, Map)}. Will be persisted to client for future. If a value
 * has been already set then it will be overwritten.
 *
 * @param property      The name of the property to set.
 * @param value         The value of the new global property.
 */
- (void) setGlobalProperty:(NSString *)property value:(id)value;

/**
 * Sets the ID of this client to something else. This should be called if you register or
 * sign-in a user and want to associate previously anonymous actions with this new identity.
 *
 * <p>This should only be called once for a given user. Calling identify(...) again with a
 * different Id for the same user will result in an exception being thrown.
 *
 * @param actor         The new unique actor Id.
 */
- (void) identify:(NSString *)actor;

/**
 * Sets profile properties for the current user. These are not the same as global properties.
 * A user MUST be identified before calling profile else an exception will be thrown.
 *
 * @param properties	The custom properties to set for this user. If a property with the
 * 		same name already exists then it will be overwritten.
 */
- (void) profile:(NSDictionary *)properties;

/**
 * Clears the current session and resets to being an anonymous user.
 * You should generally call this if a user logs out of your application.
 */
- (void) clear;

/**
 * Asks the CalqClient to flush any API calls which are currently queued. Normally this
 * is done in the background for you (calls are grouped together to save battery). This
 * will block until complete.
 *
 * @return YES if all actions flushed. NO if some failed (either API error or connection).
 */
- (BOOL) flushQueue;

@end
