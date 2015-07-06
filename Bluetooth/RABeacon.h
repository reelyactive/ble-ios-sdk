//
//  Beacon.h
//  Bluetooth
//
//  Created by Callum Henshall on 03/03/15.
//  Copyright (c) 2015 reelyActive. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RABeaconService;

/**
 * Represents a Bluetooth Beacon or an iBeacon.
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
 * Onyl used when detecting a beacon.
 */
@property (strong, nonatomic, readonly) NSString *systemID;

/**
 *
 */
- (instancetype)initWithBeaconService:(RABeaconService *)beaconService
                             systemID:(NSString *)systemID;


- (BOOL)isEqual:(id)object;

/**
 * Compares the received to a given object.
 * @return YES if all the properties of both objects are equal.
 */
- (BOOL)isEqualToBeacon:(RABeacon *)beacon;

@end
