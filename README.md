BeaconManager
=============

BeaconManager is an easy to use library that allows you to detect Bluetooth Beacons and iBeacons and does all the hard work for you.

How to get started
------------------
For detecting Beacons in the background you will need to add the UIBackgroundModes
```xml
bluetooth-central
```
key to your application's plist.

To detect iBeacons in the background you will need to add the UIBackgroundModes
```xml
location
```
key to your application's plist.

For advertising a Beacon from the app in the background once a Beacon has been detected, you will need to add the UIBackgroundModes
```xml
bluetooth-peripheral
```
key to your application's plist.

Since iOS 8, don't forget to fill out the
```
NSLocationAlwaysUsageDescription
NSLocationWhenInUseUsageDescription
```
keys where needed.

Installation with CocoaPods
---------------------------
[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, that greatly simplifies the use of 3rd party libraries. For more information see the [Get Started guide](http://guides.cocoapods.org/using/getting-started.html).
```ruby
pod "BeaconManager"
```

Sample Code
-----------
For information on how to use the library the [documentation](http://cocoadocs.org/docsets/BeaconManager) should be sufficient, but if not a sample project is provided that allows you to detect Beacons and iBeacons.
