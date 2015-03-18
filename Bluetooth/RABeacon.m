//
//  Beacon.m
//  Bluetooth
//
//  Created by Callum Henshall on 03/03/15.
//  Copyright (c) 2015 reelyActive. All rights reserved.
//

#import "RABeacon.h"

static NSString *const kBeaconNameKey = @"name";
static NSString *const kBeaconUUIDKey = @"uuid";
static NSString *const kBeaconMajorValueKey = @"major";
static NSString *const kBeaconMinorValueKey = @"minor";
static NSString *const kiBeaconValueKey = @"iBeacon";

@implementation RABeacon

- (instancetype)initWithName:(NSString *)name
                        uuid:(NSUUID *)uuid
{
    self = [super init];
    if (self)
    {
        _name = name;
        _uuid = uuid;
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name
                        uuid:(NSUUID *)uuid
                       major:(CLBeaconMajorValue)major
                       minor:(CLBeaconMinorValue)minor
{
    self = [super init];
    if (self)
    {
        _name = name;
        _uuid = uuid;
        _majorValue = major;
        _minorValue = minor;
        _iBeacon = YES;
    }
    return self;
}

- (CLBeaconRegion *)beaconRegion
{
    return [[CLBeaconRegion alloc] initWithProximityUUID:self.uuid
                                                   major:self.majorValue
                                                   minor:self.minorValue
                                              identifier:self.name];
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
    return [self.uuid isEqual:beacon.uuid]
    && self.iBeacon == beacon.iBeacon
    && (self.iBeacon == NO
        || (self.majorValue == beacon.majorValue
            && self.minorValue == beacon.minorValue));
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        _name = [aDecoder decodeObjectForKey:kBeaconNameKey];
        _uuid = [aDecoder decodeObjectForKey:kBeaconUUIDKey];
        _majorValue = [[aDecoder decodeObjectForKey:kBeaconMajorValueKey] unsignedIntegerValue];
        _minorValue = [[aDecoder decodeObjectForKey:kBeaconMinorValueKey] unsignedIntegerValue];
        _iBeacon = [[aDecoder decodeObjectForKey:kiBeaconValueKey] boolValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:kBeaconNameKey];
    [aCoder encodeObject:self.uuid forKey:kBeaconUUIDKey];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:self.majorValue] forKey:kBeaconMajorValueKey];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:self.minorValue] forKey:kBeaconMinorValueKey];
    [aCoder encodeObject:[NSNumber numberWithBool:self.iBeacon] forKey:kiBeaconValueKey];
}

@end

@implementation CLBeacon (Beacon)

- (RABeacon *)beacon
{
    return [[RABeacon alloc] initWithName:nil
                                   uuid:self.proximityUUID
                                  major:self.major.unsignedIntegerValue
                                  minor:self.minor.unsignedIntegerValue];
}

@end
