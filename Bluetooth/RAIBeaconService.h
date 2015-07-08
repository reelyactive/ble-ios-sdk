//
//  RAIBeaconService.h
//  Bluetooth
//
//  Created by Callum Henshall on 03/07/15.
//  Copyright (c) 2015 reelyActive. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

@interface RAIBeaconService : NSObject <NSCoding>

/**
 * The beacon's name
 */
@property (strong, nonatomic, readonly) NSString *name;

/**
 * The UUID for the service
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
 * Creates an iBeacon Service.
 */
- (instancetype)initWithName:(NSString *)name
                        UUID:(NSUUID *)uuid
                       major:(CLBeaconMajorValue)major
                       minor:(CLBeaconMinorValue)minor;


- (BOOL)isEqual:(id)object;

/**
 * Compares the received to a given object.
 * @return YES if all the properties of both objects are equal.
 */
- (BOOL)isEqualToIBeaconService:(RAIBeaconService *)iBeaconService;

/**
 * @return CLBeaconRegion For use with CoreLocation
 */
- (CLBeaconRegion *)beaconRegion;

@end

@interface CLBeacon (RAIBeaconService)

- (RAIBeaconService *)iBeaconService;

@end

NS_ASSUME_NONNULL_END
