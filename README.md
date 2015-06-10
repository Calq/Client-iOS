Calq iOS Client
=================

The full quick start and reference docs can be found at: https://www.calq.io/docs/client/ios

Installation (via CocoaPods)
-----------------------

The Calq iOS client can be quickly imported using using [CocoaPods](http://cocoapods.org/).

1. If you have not already done so, install CocoaPods using `gem install cocoapods` followed by `pod setup` to create a local mirror.
2. Create a file in your Xcode project called `Podfile` with the following line included:
```
pod 'CalqClient-iOS'
```
3. Run `pod install` from your Xcode project directory to import the Calq library.

Installation (Xcode - Manual)
-----------------------------

Alternatively you can add the Calq iOS client to Xcode manually with the following steps:
 
1. Grab the [latest release from GitHub](https://github.com/Calq/Client-iOS/releases) and extract it.
2. Drag the CalqClient folder into your project.
3. Make sure Copy items into destination group's folder is selected, as well as Create groups for any added folders.

You will also need to link agaisnt SQLite if you haven't already (Calq uses this to store API calls when a user has limited connectivity).

4. Select your project in Xcode's Navigator to edit it's properties and choose the Build Phases tab.
5. Under "Link Binary With Libraries" press the + button and search for a suitable SQLite library (such as libsqlite3.dylib).

For full installation steps check out the [install section of the iOS Quick Start](https://www.calq.io/docs/client/ios).

Getting a client instance
-------------------------

First you should initialize the client library using `[CalqClient initSharedInstanceWithKey]`. This will create a client and load any existing user information or properties that have been previously set.

The recommended way to do this is in `applicationDidFinishLaunching:` or `application:didFinishLaunchingWithOptions` in your Application delegate:

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    // Override point for customization after application launch.
    [CalqClient initSharedInstanceWithKey:@@"YOUR_WRITE_KEY_HERE"];

    // ...
}
```

After initialization you can access a shared CalqClient instance from anywhere using `[CalqClient sharedInstance]`

Tracking actions
----------------

Calq performs analytics based on actions that user's take. You can track an action using `CalqClient.track`. Specify the action and any associated data you wish to record.

```objective-c
// Track a new action called "Product Review" with a custom rating
[[CalqClient sharedInstance] track:@"Product Review" properties:@{@"Rating": @9.0 }];
```

The properties parameter allows you to send additional custom data about the action. This extra data can be used to make advanced queries within Calq.

Documentation
-------------

The full quick start can be found at: https://www.calq.io/docs/client/ios

The reference can be found at:  https://www.calq.io/docs/client/ios/reference

License
--------

[Licensed under the Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).





