//
//  BeaconManager.h
//  Bluetooth
//
//  Created by Callum Henshall on 03/03/15.
//  Copyright (c) 2015 Sidereo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Beacon;

extern NSString *BeaconManagerBeaconsDetectedChangedNotification;

extern NSString *kBeaconManagerDateKey;
extern NSString *kBeaconManagerBeaconKey;

@interface BeaconManager : NSObject

+ (instancetype)sharedManager;

@property (strong, nonatomic, readonly) NSArray *beacons; // Beacon

- (void)addBeacon:(Beacon *)beacon;
- (void)removeBeacon:(Beacon *)beacon;

@property (strong, nonatomic) NSString *peripheralUUID;
@property (strong, nonatomic) NSString *peripheralName;

- (void)setBeaconDetection:(BOOL)detectBeacons;

/*
 * Contains an NSDictionary with 2 keys
 * kBeaconManagerDateKey: an NSDate which is the lastest date that the beacon was detected
 * kBeaconManagerBeaconKey: the Beacon object
 */
@property (strong, nonatomic, readonly) NSArray *detectedBeacons;

/*
 * Used only for debug
 */
- (void)debugIBeacon;

@end
