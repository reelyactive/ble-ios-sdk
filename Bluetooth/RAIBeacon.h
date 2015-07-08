//
//  RAIBeacon.h
//  Bluetooth
//
//  Created by Callum Henshall on 03/07/15.
//  Copyright (c) 2015 reelyActive. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreLocation;

@class RAIBeaconService;

NS_ASSUME_NONNULL_BEGIN

@interface RAIBeacon : NSObject

/**
 * The beacon's name.
 */
@property (strong, nonatomic, readonly) NSString *name;

/**
 * The UUID for the service.
 */
@property (strong, nonatomic, readonly) NSUUID *serviceUUID;

/**
 * Only used if this is an iBeacon.
 */
@property (assign, nonatomic, readonly) CLBeaconMajorValue majorValue;
/**
 * Only used if this is an iBeacon.
 */
@property (assign, nonatomic, readonly) CLBeaconMinorValue minorValue;

/**
 * The CoreLocation Beacon object detected.
 */
@property (strong, nonatomic, readonly) CLBeacon *clBeacon;

/**
 * Creates an iBeacon based on the gived iBeacon Service
 */
- (instancetype)initWithBeacon:(RAIBeaconService *)iBeaconService
                      CLBeacon:(CLBeacon *)clBeacon;


- (BOOL)isEqual:(id)object;

/**
 * Compares the received to a given object.
 * @return YES if all the properties of both objects are equal.
 */
- (BOOL)isEqualToIBeacon:(RAIBeacon *)iBeacon;

@end

NS_ASSUME_NONNULL_END
