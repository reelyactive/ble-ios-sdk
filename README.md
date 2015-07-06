RABeaconManager
=============

RABeaconManager is an easy to use library that allows you to detect Bluetooth Beacons and iBeacons in the foreground and background, doing all the hard work for you.

Installation with CocoaPods
---------------------------
[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, that greatly simplifies the use of 3rd party libraries. For more information see the [Get Started guide](http://guides.cocoapods.org/using/getting-started.html).

```ruby
pod "BeaconManager"
```

How to get started
------------------
For detecting Beacons in the background you will need to add the UIBackgroundModes

```
bluetooth-central
```

key to your application's plist.

To detect iBeacons in the background you will need to add the UIBackgroundModes

```
location
```

key to your application's plist.

For advertising a Beacon from the app in the background once a Beacon has been detected, you will need to add the UIBackgroundModes

```
bluetooth-peripheral
```
key to your application's plist.

Since iOS 8, don't forget to fill out the

```
NSLocationAlwaysUsageDescription
NSLocationWhenInUseUsageDescription
```

keys where needed.

Sample Code
-----------
For information on how to use the library the [documentation](http://cocoadocs.org/docsets/BeaconManager) should be sufficient, but if not a sample project is provided that allows you to detect Beacons and iBeacons.
