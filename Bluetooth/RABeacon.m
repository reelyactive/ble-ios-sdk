//
//  Beacon.m
//  Bluetooth
//
//  Created by Callum Henshall on 03/03/15.
//  Copyright (c) 2015 reelyActive. All rights reserved.
//

#import "RABeacon.h"

#import "RABeaconService.h"

@interface RABeacon ()

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSUUID *serviceUUID;
@property (strong, nonatomic) NSString *systemID;

@end

@implementation RABeacon

- (instancetype)initWithBeaconService:(RABeaconService *)beaconService systemID:(NSString *)systemID rssi:(NSNumber*) rssi
{
    self = [super init];
    if (self)
    {
        _name = beaconService.name;
        _serviceUUID = beaconService.serviceUUID;
        _systemID = systemID;
        _rssi = rssi;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]])
    {
        return [self isEqualToBeacon:(RABeacon *)object];
    }
    return NO;
}

- (BOOL)isEqualToBeacon:(RABeacon *)beacon
{
    return [self.serviceUUID isEqual:beacon.serviceUUID]
    && [self.systemID isEqualToString:beacon.systemID];
}

@end
