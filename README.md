RABeaconManager
=============

RABeaconManager is an easy to use library that allows you to detect Bluetooth Beacons and iBeacons in the foreground and background, doing all the hard work for you.

Installation with CocoaPods
---------------------------
[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, that greatly simplifies the use of 3rd party libraries. For more information see the [Get Started guide](http://guides.cocoapods.org/using/getting-started.html).

To add BeaconManager to you project add the following line to your Podfile :
```ruby
pod "BeaconManager"
```

How to get started
------------------
To import the Beacon manager code :
```
#import "RABeacons.h"
```
This imports all files needed in one go.

The preferred location for setting up the BeaconManger is from your App Delegate's ```application:didFinishLaunchingWithOptions:```,  this allows you to update the BeaconManager settings each time your app is launched. 

This code sets up the BeaconManager to scan for a Beacon using a given UDID.
``` Objective-C
if ([RABeaconManager sharedManager].beaconServices.count != 1)
{
[[RABeaconManager sharedManager] removeAllServices];

RABeaconService *beaconService = [[RABeaconService alloc] initWithName:@"Test Beacon"
uuid:[[NSUUID alloc] initWithUUIDString:@"7265656C-7941-6374-6976-652055554944"]];
[[RABeaconManager sharedManager] addBeaconService:beaconService];
}

[[RABeaconManager sharedManager] setBeaconDetection:YES iBeacons:NO inBackground:YES];
```

To be notified as soon as a Beacon or iBeacon is detected add the following code in the appropriate location :

``` Objective-C
[[NSNotificationCenter defaultCenter] addObserver:self
selector:@selector(beaconsDetectedUpdate:)
name:BeaconManagerBeaconsDetectedChangedNotification
object:nil];
```

Don't forget to implement the handler for the notification :
```Objective-C
- (void)beaconsDetectedUpdate:(NSNotification *)notification
{
// Beacons array did update
// check [RABeaconManger sharedManager].detectedBeacons for any beacons in range
}
```

For more information read the **Documentation** or the **Demo Project**.

Don't forget keys !
------------------
For detecting Beacons in the background you will need to add the UIBackgroundModes

```
bluetooth-central
```

key to your application's `info.plist`.

To detect iBeacons in the background you will need to add the UIBackgroundModes

```
location
```

key to your application's `info.plist`.

For advertising a Beacon from the app in the background once a Beacon has been detected, you will need to add the UIBackgroundModes

```
bluetooth-peripheral
```
key to your application's `info.plist`.

Since iOS 8, don't forget to fill out the

```
NSLocationAlwaysUsageDescription
NSLocationWhenInUseUsageDescription
```

keys where needed.

Demo project
-----------
For information on how to use the library the [documentation](http://cocoadocs.org/docsets/BeaconManager) should be sufficient, but if not a Demo project is provided that allows you to detect Beacons and iBeacons.



