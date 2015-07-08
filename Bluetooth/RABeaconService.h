//
//  RABeaconService.h
//  Bluetooth
//
//  Created by Callum Henshall on 03/07/15.
//  Copyright (c) 2015 reelyActive. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RABeaconService : NSObject <NSCoding>

/**
 * The beacon's name
 */
@property (strong, nonatomic, readonly) NSString *name;

/**
 * The UUID for the service
 */
@property (strong, nonatomic, readonly) NSUUID *serviceUUID;

/**
 * Creates a Beacon Service.
 */
- (instancetype)initWithName:(NSString *)name
                        uuid:(NSUUID *)uuid;

- (BOOL)isEqual:(id)object;

/**
 * Compares the received to a given object.
 * @return YES if all the properties of both objects are equal.
 */
- (BOOL)isEqualToBeaconService:(RABeaconService *)beaconService;

@end

NS_ASSUME_NONNULL_END
