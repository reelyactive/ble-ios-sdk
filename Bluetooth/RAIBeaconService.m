//
//  RAIBeaconService.m
//  Bluetooth
//
//  Created by Callum Henshall on 03/07/15.
//  Copyright (c) 2015 reelyActive. All rights reserved.
//

#import "RAIBeaconService.h"

static NSString *const kBeaconNameKey = @"kBeaconNameKey";
static NSString *const kBeaconServiceUUIDKey = @"kBeaconServiceUUIDKey";
static NSString *const kBeaconMajorValueKey = @"kBeaconMajorValueKey";
static NSString *const kBeaconMinorValueKey = @"kBeaconMinorValueKey";

@interface RAIBeaconService ()

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSUUID *serviceUUID;
@property (assign, nonatomic) CLBeaconMajorValue majorValue;
@property (assign, nonatomic) CLBeaconMinorValue minorValue;

@end

@implementation RAIBeaconService

- (instancetype)initWithName:(NSString *)name
                        UUID:(NSUUID *)uuid
                       major:(CLBeaconMajorValue)major
                       minor:(CLBeaconMinorValue)minor
{
    self = [super init];
    if (self) {
        
        self.name = name;
        self.serviceUUID = uuid;
        self.majorValue = major;
        self.minorValue = minor;
    }
    return self;
}

- (CLBeaconRegion *)beaconRegion
{
    return [[CLBeaconRegion alloc] initWithProximityUUID:self.serviceUUID
                                                   major:self.majorValue
                                                   minor:self.minorValue
                                              identifier:self.name];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]])
    {
        return [self isEqualToIBeaconService:(RAIBeaconService *)object];
    }
    return NO;
}

- (BOOL)isEqualToIBeaconService:(RAIBeaconService *)iBeaconService
{
    return [self.serviceUUID isEqual:iBeaconService.serviceUUID]
    && self.majorValue == iBeaconService.majorValue
    && self.minorValue == iBeaconService.minorValue;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        _name = [aDecoder decodeObjectForKey:kBeaconNameKey];
        _serviceUUID = [aDecoder decodeObjectForKey:kBeaconServiceUUIDKey];
        _majorValue = [[aDecoder decodeObjectForKey:kBeaconMajorValueKey] unsignedIntegerValue];
        _minorValue = [[aDecoder decodeObjectForKey:kBeaconMinorValueKey] unsignedIntegerValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:kBeaconNameKey];
    [aCoder encodeObject:self.serviceUUID forKey:kBeaconServiceUUIDKey];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:self.majorValue] forKey:kBeaconMajorValueKey];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:self.minorValue] forKey:kBeaconMinorValueKey];
}

@end

@implementation CLBeacon (BeaconService)

- (RAIBeaconService *)iBeaconService
{
    return [[RAIBeaconService alloc] initWithName:nil
                                             UUID:self.proximityUUID
                                            major:self.major.unsignedIntegerValue
                                            minor:self.minor.unsignedIntegerValue];
}

@end