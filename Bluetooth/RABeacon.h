//
//  Beacon.h
//  Bluetooth
//
//  Created by Callum Henshall on 03/03/15.
//  Copyright (c) 2015 reelyActive. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RABeaconService;

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents a Bluetooth Beacon.
 */
@interface RABeacon : NSObject

/**
 * The beacon's name.
 */
@property (strong, nonatomic, readonly) NSString *name;

/**
 * The UUID for the service.
 */
@property (strong, nonatomic, readonly) NSUUID *serviceUUID;

/**
 * The system ID of the Beacon.
 */
@property (strong, nonatomic, readonly) NSString *systemID;

/**
 * The system RSSI of the Beacon.
 */
@property (strong, nonatomic, readonly) NSNumber *rssi;


/**
 * Creates a Beacon based on the gived Beacon Service.
 */
- (instancetype)initWithBeaconService:(RABeaconService *)beaconService
                             systemID:(NSString *)systemID
                                 rssi:(NSNumber *) rssi;


- (BOOL)isEqual:(id)object;

/**
 * Compares the received to a given object.
 * @return YES if all the properties of both objects are equal.
 */
- (BOOL)isEqualToBeacon:(RABeacon *)beacon;

@end

NS_ASSUME_NONNULL_END
