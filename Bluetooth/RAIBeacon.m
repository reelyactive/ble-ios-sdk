//
//  RAIBeacon.m
//  Bluetooth
//
//  Created by Callum Henshall on 03/07/15.
//  Copyright (c) 2015 reelyActive. All rights reserved.
//

#import "RAIBeacon.h"

#import "RAIBeaconService.h"

@interface RAIBeacon ()

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSUUID *serviceUUID;
@property (assign, nonatomic) CLBeaconMajorValue majorValue;
@property (assign, nonatomic) CLBeaconMinorValue minorValue;
@property (strong, nonatomic) CLBeacon *clBeacon;

@end

@implementation RAIBeacon

- (instancetype)initWithBeacon:(RAIBeaconService *)iBeaconService CLBeacon:(CLBeacon *)clBeacon
{
    self = [super init];
    if (self)
    {
        _name = iBeaconService.name;
        _serviceUUID = iBeaconService.serviceUUID;
        _majorValue = iBeaconService.majorValue;
        _minorValue = iBeaconService.minorValue;
        _clBeacon = clBeacon;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]])
    {
        return [self isEqualToIBeacon:(RAIBeacon *)object];
    }
    return NO;
}

- (BOOL)isEqualToIBeacon:(RAIBeacon *)iBeacon
{
    return [self.serviceUUID isEqual:iBeacon.serviceUUID]
    && self.majorValue == iBeacon.majorValue
    && self.minorValue == iBeacon.minorValue;
}

@end
