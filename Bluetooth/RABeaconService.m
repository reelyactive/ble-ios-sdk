//
//  RABeaconService.m
//  Bluetooth
//
//  Created by Callum Henshall on 03/07/15.
//  Copyright (c) 2015 reelyActive. All rights reserved.
//

#import "RABeaconService.h"

static NSString *const kBeaconNameKey = @"kBeaconNameKey";
static NSString *const kBeaconServiceUUIDKey = @"kBeaconServiceUUIDKey";

@interface RABeaconService ()

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSUUID *serviceUUID;

@end

@implementation RABeaconService

- (instancetype)initWithName:(NSString *)name uuid:(NSUUID *)uuid
{
    self = [super init];
    if (self) {
        
        self.name = name;
        self.serviceUUID = uuid;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]])
    {
        return [self isEqualToBeaconService:(RABeaconService *)object];
    }
    return NO;
}

- (BOOL)isEqualToBeaconService:(RABeaconService *)beaconService
{
    return [self.serviceUUID isEqual:beaconService.serviceUUID];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        _name = [aDecoder decodeObjectForKey:kBeaconNameKey];
        _serviceUUID = [aDecoder decodeObjectForKey:kBeaconServiceUUIDKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:kBeaconNameKey];
    [aCoder encodeObject:self.serviceUUID forKey:kBeaconServiceUUIDKey];
}

@end
