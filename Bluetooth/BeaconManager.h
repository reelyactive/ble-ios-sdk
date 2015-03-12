//
//  BeaconManager.h
//  Bluetooth
//
//  Created by Callum Henshall on 03/03/15.
//  Copyright (c) 2015 Sidereo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Beacon;

/**
 * Posted when a Beacon is detected or is no longer in range.
 */
extern NSString *BeaconManagerBeaconsDetectedChangedNotification;
/**
 * Posted when the manager of the Manager changes.
 */
extern NSString *BeaconManagerStateChangedNotification;

/**
 *
 */
extern NSString *kBeaconManagerDateKey;
/**
 *
 */
extern NSString *kBeaconManagerBeaconKey;

/**
 * The different states for the manager.
 */
typedef NS_ENUM(NSInteger, BeaconManagerState)
{
    BeaconManagerStateOff,
    BeaconManagerStateNeedBluetooth,
    BeaconManagerStateNeedLocationServices,
    BeaconManagerStateOn,
};

/**
 * This Beacon Manager is used for monitoring and detecting Bluetoth beacons and iBeacons.
 */
@interface BeaconManager : NSObject

/**
 * Access the shared instance for this manager.
 */
+ (instancetype)sharedManager;

/**
 * If a Beacon isn't detected for this amount of time it's considered out of range and removed from the detectedBeacons NSArray.
 * The default value is 10 seconds.
 */
@property (assign, nonatomic) NSTimeInterval beaconExpiryAge;

/**
 * Used to add a Beacon to the list of beacons to be detected.
 */
- (void)addBeacon:(Beacon *)beacon;
/**
 * Used to remove a Beacon from the list of Beacons.
 *
 * It doesn't need to be the exact same instance, since isEqualToBeacon: is used.
 */
- (void)removeBeacon:(Beacon *)beacon;

/**
 * If YES and a gived Beacon is detected, then the manager will advertise with the given UUID and Name.
 *
 * @warning If peripheralUUID and peripheralName aren't set an NSInternalInconsistencyException is raised.
 */
@property (assign, nonatomic) BOOL advertisePeripheralWhenBeaconDetected;
/**
 *
 */
@property (strong, nonatomic) NSString *peripheralUUID;
/**
 *
 */
@property (strong, nonatomic) NSString *peripheralName;

/**
 * Optional UUID for the advertised peripheral.
 */
@property (strong, nonatomic) NSString *peripheralCaracteristicUUID;


/**
 * Used to turn on and off Beacon detection.
 *
 * @param detectBeacons : YES to turn detection on.
 */
- (void)setBeaconDetection:(BOOL)detectBeacons iBeacons:(BOOL)detectIBeacons inBackground:(BOOL)detectInBackground;

/**
 * The current state of the maanger.
 */
@property (assign, nonatomic, readonly) BeaconManagerState state;

/**
 * An Array of Beacon objects to detect.
 */
@property (strong, nonatomic, readonly) NSArray *beacons;

/**
 * Each object is an NSDictionary with 2 keys.
 * kBeaconManagerDateKey: an NSDate which is the lastest date that the beacon was detected.
 * kBeaconManagerBeaconKey: the Beacon object.
 */
@property (strong, nonatomic, readonly) NSArray *detectedBeacons;

/**
 * Used only for debug.
 */
- (void)debugIBeacon;

/**
 * Used only for debug.
 */
- (void)debugBeacon;

@end
