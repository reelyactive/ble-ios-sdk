//
//  BeaconManager.h
//  Bluetooth
//
//  Created by Callum Henshall on 03/03/15.
//  Copyright (c) 2015 reelyActive. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RABeacon, RAIBeacon, RABeaconService, RAIBeaconService;

NS_ASSUME_NONNULL_BEGIN

/**
 * Posted when a Beacon is detected or is no longer in range.
 */
extern NSString *BeaconManagerBeaconsDetectedChangedNotification;
/**
 * Posted when an iBeacon is detected or is no longer in range.
 */
extern NSString *BeaconManagerIBeaconsDetectedChangedNotification;
/**
 * Posted when the manager of the Manager changes.
 */
extern NSString *BeaconManagerStateChangedNotification;

/**
 * The key used to access the date in detectedBeacons.
 */
extern NSString *kBeaconManagerDateKey;
/**
 * The key used to access the Beacon object in detectedBeacons.
 */
extern NSString *kBeaconManagerBeaconKey;

/**
 * The different states for the manager.
 */
typedef NS_ENUM(NSInteger, BeaconManagerState)
{
    /**
     * The Manager is Off.
     */
    BeaconManagerStateOff,
    /**
     * The Manager needs bluetooth to be activated or for the user to authorise the application to use bluetooth.
     */
    BeaconManagerStateNeedBluetooth,
    /**
     * The Manager needs location services to be activated or for the user to authorise the application to use location services.
     */
    BeaconManagerStateNeedLocationServices,
    /**
     * The Manager is On, all is fine.
     */
    BeaconManagerStateOn,
};

/**
 * This Beacon Manager is used for monitoring and detecting Bluetoth beacons and iBeacons.
 */
@interface RABeaconManager : NSObject

/**
 * Access the shared instance for this manager.
 */
+ (instancetype)sharedManager;

/**
 * If a Beacon isn't detected for this amount of time it's considered out of range and removed from the detectedBeacons NSArray.
 * The default value is 60 seconds.
 */
@property (assign, nonatomic) NSTimeInterval beaconExpiryAge;

/**
 * Used to add a Beacon to the list of Beacons to be detected.
 */
- (void)addBeaconService:(RABeaconService *)beaconService;

/**
 * Used to add an iBeacon to the list of iBeacons to be detected.
 */
- (void)addIBeaconService:(RAIBeaconService *)iBeaconService;

/**
 * Used to remove a Beacon from the list of Beacons.
 *
 * It doesn't need to be the exact same instance, since isEqualToBeacon: is used.
 */
- (void)removeBeaconService:(RABeaconService *)beaconService;

/**
 * Used to remove an iBeacon from the list of iBeacons.
 *
 * It doesn't need to be the exact same instance, since isEqualToBeacon: is used.
 */
- (void)removeIBeaconService:(RAIBeaconService *)iBeaconService;

/**
 * Removes all the beacon services to detect
 */
- (void)removeAllServices;


/**
 * If YES and a gived Beacon is detected, then the manager will advertise with the given UUID and Name.
 *
 * @warning If YES and peripheralServiceUUID and peripheralName aren't set an NSInternalInconsistencyException is raised.
 */
@property (assign, nonatomic) BOOL advertisePeripheralWhenBeaconDetected;

/**
 * UUID for the advertised peripheral.
 */
@property (strong, nonatomic, nullable) NSString *peripheralServiceUUID;

/**
 * Name for the advertised peripheral.
 */
@property (strong, nonatomic, nullable) NSString *peripheralName;

/**
 * Optional UUID for the Caracteristic of the advertised peripheral.
 */
@property (strong, nonatomic, nullable) NSString *peripheralCaracteristicUUID;


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
 * An array of Beacon Services objects to detect.
 * This array persists over launches of the app
 */
@property (strong, nonatomic, readonly) NSArray *beaconServices;

/**
 * An array of iBeacon Services objects to detect.
 * This array persists over launches of the app
 */
@property (strong, nonatomic, readonly) NSArray *iBeaconServices;

/**
 * Each object is an NSDictionary with 2 keys.
 * kBeaconManagerDateKey: an NSDate which is the lastest date that the beacon was detected.
 * kBeaconManagerBeaconKey: the Beacon object.
 */
@property (strong, nonatomic, readonly) NSArray *detectedBeacons;

/**
 * Each object is an NSDictionary with 2 keys.
 * kBeaconManagerDateKey: an NSDate which is the lastest date that the beacon was detected.
 * kBeaconManagerBeaconKey: the Beacon object.
 */
@property (strong, nonatomic, readonly) NSArray *detectedIBeacons;

/**
 * URL to which the background beacon data is sent, to reproduce advertising.
 * If nil, beaconBackgroundAdvertisingDefaultURL is used
 */
@property (strong, nonatomic, nullable) NSString *beaconBackgroundAdvertisingURL;

/**
 * This block is called each time a beacon is detected to workout if the beacon should be added to the list of detectedBeacons.
 * By default this is nil, so the beacons are not filtered and all detected beacons are reported.
 * @return YES to add the Beacon to the list of detectedBeacons
 */
@property (copy, nonatomic, nullable) BOOL (^filterBeaconBlock)(RABeacon *beacon);

/**
 * This block is called each time an iBeacon is detected to workout if the beacon should be added to the list of detectedIBeacons.
 * By default this is nil, so the beacons are not filtered and all detected beacons are reported.
 * @return YES to add the iBeacon to the list of detectedBeacons
 */
@property (copy, nonatomic, nullable) BOOL (^filterIBeaconBlock)(RAIBeacon *iBeacon);

/**
 * Used only for debug.
 */
- (void)startDebuggingIBeacon;

/**
 * Used only for debug.
 */
- (void)startDebuggingBeacon;

@end

NS_ASSUME_NONNULL_END
