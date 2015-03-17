//
//  BeaconManager.m
//  Bluetooth
//
//  Created by Callum Henshall on 03/03/15.
//  Copyright (c) 2015 reelyActive. All rights reserved.
//

#import "BeaconManager.h"

@import CoreBluetooth;
@import CoreLocation;

#import "Beacon.h"

#import <UIKit/UIKit.h>

#define BLOG_DEBUG 0

#if BLOG_DEBUG
# define BLog(...) NSLog(__VA_ARGS__)
#else
# define BLog(...)
#endif

NSString *BeaconManagerBeaconsDetectedChangedNotification = @"BeaconManagerBeaconsDetectedChangedNotification";
NSString *BeaconManagerStateChangedNotification = @"BeaconManagerStateChangedNotification";

NSString *kBeaconManagerDateKey = @"kBeaconManagerDateKey";
NSString *kBeaconManagerBeaconKey = @"kBeaconManagerBeaconKey";

static NSString * const kStoredBeaconsKey = @"kStoredBeaconsKey";

static NSTimeInterval const kRefreshTimeInterval = 2.f;
static NSTimeInterval const kBeaconExpiryAge = 10.f;

@interface BeaconManager () <CBCentralManagerDelegate, CBPeripheralManagerDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheralManager *peripheralManager;

@property (strong, nonatomic) CLLocationManager *locationManager;


@property (assign, nonatomic) BOOL detectInBackground;
@property (assign, nonatomic) BOOL detectBeacons;
@property (assign, nonatomic) BOOL detectIBeacons;


@property (assign, nonatomic) BeaconManagerState state;

@property (strong, nonatomic) NSArray *beacons;
@property (strong, nonatomic) NSMutableArray *mutableDetectedBeacons;


@property (strong, nonatomic) NSTimer *refreshTimer;


@property (assign, nonatomic) BOOL iBeacon;

@end

@implementation BeaconManager

+ (instancetype)sharedManager
{
    static id manager;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
                  {
                      manager = [[self alloc] init];
                  });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.mutableDetectedBeacons = [[NSMutableArray alloc] init];
        
        [self loadBeacons];
        
        self.beaconExpiryAge = kBeaconExpiryAge;
        
        [self setAppNotfications:YES];
    }
    return self;
}

- (void)dealloc
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
    
    [self setAppNotfications:NO];
}

- (void)setState:(BeaconManagerState)state
{
    if (_state != state)
    {
        _state = state;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:BeaconManagerStateChangedNotification
                                                            object:self];
    }
}

- (void)updateState
{
    if (self.locationManager == nil && self.centralManager == nil)
    {
        BLog(@"BeaconManagerStateOff");
        self.state = BeaconManagerStateOff;
    }
    else if (self.centralManager
             && self.detectBeacons
             && self.centralManager.state != CBCentralManagerStatePoweredOn)
    {
        BLog(@"BeaconManagerStateNeedBluetooth");
        self.state = BeaconManagerStateNeedBluetooth;
    }
    else if (self.locationManager
             && self.detectIBeacons
             && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways
             && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse)
    {
        BLog(@"BeaconManagerStateNeedLocationServices");
        self.state = BeaconManagerStateNeedLocationServices;
    }
    else
    {
        BLog(@"BeaconManagerStateOn");
        self.state = BeaconManagerStateOn;
    }
}

- (void)setBeaconDetection:(BOOL)detectBeacons
                  iBeacons:(BOOL)detectIBeacons
              inBackground:(BOOL)detectInBackground
{
    self.detectInBackground = detectInBackground;
    
    if (detectBeacons == YES && self.detectBeacons == NO)
    {
        [self turnOnCentral];
    }
    else if (detectBeacons == NO && self.detectBeacons == YES)
    {
        [self turnOffCentral];
    }
    self.detectBeacons = detectBeacons;

    
    if (detectIBeacons == YES && self.detectIBeacons == NO)
    {
        [self turnOnLocation];
    }
    else if (detectIBeacons == NO && self.detectIBeacons == YES)
    {
        [self turnOffLocation];
    }
    self.detectIBeacons = detectIBeacons;

    
    if (detectBeacons || detectIBeacons)
    {
        if (self.refreshTimer == nil)
        {
            self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:kRefreshTimeInterval
                                                                 target:self
                                                               selector:@selector(refresh:)
                                                               userInfo:nil
                                                                repeats:YES];
        }
    }
    else
    {
        [self.refreshTimer invalidate];
        self.refreshTimer = nil;
    }
}

- (void)loadBeacons
{
    NSArray *storedItems = [[NSUserDefaults standardUserDefaults] arrayForKey:kStoredBeaconsKey];
    NSMutableArray *beacons = [[NSMutableArray alloc] init];
    
    if (storedItems)
    {
        for (NSData *beaconData in storedItems)
        {
            Beacon *beacon = [NSKeyedUnarchiver unarchiveObjectWithData:beaconData];
            [beacons addObject:beacon];
        }
    }
    self.beacons = [[NSArray alloc] initWithArray:beacons];
}

- (void)persistBeacons
{
    NSMutableArray *beaconDataArray = [[NSMutableArray alloc] init];
    
    for (Beacon *beacon in self.beacons)
    {
        NSData *beaconData = [NSKeyedArchiver archivedDataWithRootObject:beacon];
        [beaconDataArray addObject:beaconData];
    }
    [[NSUserDefaults standardUserDefaults] setObject:beaconDataArray forKey:kStoredBeaconsKey];
}

- (void)addBeacon:(Beacon *)beacon
{
    BOOL isUnique = YES;
    
    for (Beacon *aBeacon in self.beacons)
    {
        if ([aBeacon isEqualToBeacon:beacon])
        {
            isUnique = NO;
            break;
        }
    }
   
    if (isUnique)
    {
        [self startMonitoringBeacon:beacon];
        [self refreshBeaconScanning];
        
        self.beacons = [self.beacons arrayByAddingObject:beacon];
        
        [self persistBeacons];
    }
}

- (void)removeBeacon:(Beacon *)beacon
{
    [self stopMonitoringBeacon:beacon];
    [self refreshBeaconScanning];
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(Beacon *evaluatedObject, NSDictionary *bindings)
                              {
                                  if ([evaluatedObject isEqualToBeacon:beacon])
                                  {
                                      return NO;
                                  }
                                  else
                                  {
                                      return YES;
                                  }
                              }];
    
    self.beacons = [self.beacons filteredArrayUsingPredicate:predicate];
    
    [self persistBeacons];
}

#pragma mark - App Notifications

- (void)setAppNotfications:(BOOL)setNotifications
{
    if (setNotifications)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidEnterBackgroundActive:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillEnterForegroundActive:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIApplicationDidEnterBackgroundNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIApplicationWillEnterForegroundNotification
                                                      object:nil];
    }
}

- (void)appDidEnterBackgroundActive:(NSNotification *)notification
{
    BLog(@"appDidEnterBackgroundActive");
    if (self.detectInBackground == NO)
    {
        if (self.detectedBeacons)
        {
            [self turnOffCentral];
        }
        
        if (self.detectIBeacons)
        {
            [self turnOffLocation];
        }
    }
}

- (void)appWillEnterForegroundActive:(NSNotification *)notification
{
    BLog(@"appWillEnterForegroundActive");
    if (self.detectInBackground == NO)
    {
        if (self.detectedBeacons)
        {
            [self turnOnCentral];
        }
        
        if (self.detectIBeacons)
        {
            [self turnOnLocation];
        }
    }
}

#pragma mark - CLLocationManagerDelegate

- (BOOL)turnOnLocation
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    if (self.detectInBackground)
    {
        [self.locationManager requestAlwaysAuthorization];
    }
    else
    {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]])
    {
        for (Beacon *beacon in self.beacons)
        {
            [self startMonitoringBeacon:beacon];
        }
    }
    else
    {
        BLog(@"Can't monitor beacon regions");
        
        [self updateState];

        return NO;
    }
    
    [self updateState];
    
    return YES;
}

- (void)turnOffLocation
{
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]])
    {
        for (Beacon *beacon in self.beacons)
        {
            [self stopMonitoringBeacon:beacon];
        }
    }
    
    [self.locationManager stopUpdatingLocation];
    
    self.locationManager = nil;
    
    [self updateState];
}

- (void)startMonitoringBeacon:(Beacon *)beacon
{
    if (beacon.iBeacon)
    {
        CLBeaconRegion *beaconRegion = beacon.beaconRegion;
        
        beaconRegion.notifyOnEntry = YES;
        beaconRegion.notifyEntryStateOnDisplay = YES;
        beaconRegion.notifyOnExit = YES;
        
        [self.locationManager startMonitoringForRegion:beaconRegion];
        [self.locationManager startRangingBeaconsInRegion:beaconRegion];
    }
}

- (void)stopMonitoringBeacon:(Beacon *)beacon
{
    if (beacon.iBeacon)
    {
        CLBeaconRegion *beaconRegion = beacon.beaconRegion;
        
        [self.locationManager stopMonitoringForRegion:beaconRegion];
        [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    BLog(@"Did enter region: %@", region);
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    BLog(@"Did exit region: %@", region);
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    BLog(@"Did determine state : %lld for region : %@", (long long)state, region);
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    BLog(@"Did range beacons : %lld, %@", (long long)beacons.count, beacons);

    for (CLBeacon *beacon in beacons)
    {
        Beacon *aBeacon = beacon.beacon;
        
        [self didDetectBeacon:aBeacon];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    BLog(@"Failed monitoring region: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    BLog(@"Location manager failed: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    BLog(@"kCLAuthorizationStatusAuthorized : %lld", (long long)kCLAuthorizationStatusAuthorized);
    BLog(@"kCLAuthorizationStatusAuthorizedAlways : %lld", (long long)kCLAuthorizationStatusAuthorizedAlways);
    BLog(@"kCLAuthorizationStatusAuthorizedWhenInUse : %lld", (long long)kCLAuthorizationStatusAuthorizedWhenInUse);
    BLog(@"Authorization Statis did change : %lld", (long long)status);

    [self updateState];
}

#pragma mark - CBCentralManagerDelegate

- (BOOL)turnOnCentral
{
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil
                                                             options:@{
                                                                       CBCentralManagerOptionShowPowerAlertKey: @(YES)
                                                                       }];
    [self updateState];

    return YES;
}

- (void)turnOffCentral
{
    [self.centralManager stopScan];

    self.centralManager = nil;
    
    [self updateState];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    BLog(@"-- central state changed: %lld", (long long)self.centralManager.state);
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self refreshBeaconScanning];
    }
    
    [self updateState];
}

- (void)refreshBeaconScanning
{
    if (self.centralManager.state != CBCentralManagerStatePoweredOn)
    {
        BLog(@"Error Central Manager is not powered on : state %lld", (long long)self.centralManager.state);
        return;
    }
    
    if (self.beacons.count == 0)
    {
        [self.centralManager stopScan];
    }
    else
    {
        NSDictionary *scanOptions = @{
                                      CBCentralManagerScanOptionAllowDuplicatesKey: @(YES)
                                      };
        
        NSMutableArray *identifiers = [[NSMutableArray alloc] init];
        
        for (Beacon *beacon in self.beacons)
        {
            if (beacon.iBeacon == NO)
            {
                BLog(@"UUID : %@", beacon.uuid.UUIDString);
                [identifiers addObject:[CBUUID UUIDWithNSUUID:beacon.uuid]];
            }
        }
        
        if (identifiers.count > 0)
        {
            [self.centralManager scanForPeripheralsWithServices:identifiers
                                                        options:scanOptions];
        }
        else
        {
            [self.centralManager stopScan];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSArray *uuids = advertisementData[CBAdvertisementDataServiceUUIDsKey];
    
    for (CBUUID *uuid in uuids)
    {
        [self didDetectUUID:[[NSUUID alloc] initWithUUIDString:uuid.UUIDString]];
    }
    
    BLog(@"Found Peripheral Name : %@ : %@ : %@", peripheral.name, peripheral.identifier.UUIDString, advertisementData);
}

#pragma mark - CBPeripheralManagerDelegate

- (void)turnOnPeripheral
{
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                     queue:nil];
}

- (void)turnOffPeripheral
{
    [self.peripheralManager stopAdvertising];
    self.peripheralManager = nil;
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    BLog(@"-- peripheral state changed: %lld", (long long)self.peripheralManager.state);
    if (peripheral.state == CBPeripheralManagerStatePoweredOn)
    {
        [self startAdvertising];
    }
}

- (void)setAdvertisePeripheralWhenBeaconDetected:(BOOL)advertisePeripheralWhenBeaconDetected
{
    if (self.peripheralUUID.length == 0 || self.peripheralName.length < 1)
    {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Need peripheral UUID and Name" userInfo:nil];
    }
    
    _advertisePeripheralWhenBeaconDetected = advertisePeripheralWhenBeaconDetected;
}

- (void)startAdvertising
{
    if (self.peripheralManager.state != CBPeripheralManagerStatePoweredOn)
    {
        BLog(@"Error Peripheral Manager is not powered on : state %lld", (long long)self.peripheralManager.state);
        return;
    }
    
    if (self.iBeacon)
    {
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:self.peripheralUUID];
        NSString *identifier = self.peripheralName;
        
        CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
                                                                               major:1
                                                                               minor:1
                                                                          identifier:identifier];
        
        NSDictionary *payload = [beaconRegion peripheralDataWithMeasuredPower:nil];
        
        [self.peripheralManager startAdvertising:payload];
    }
    else
    {

        CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:self.peripheralUUID]
                                                                           primary:YES];
    
    
        if (self.peripheralCaracteristicUUID.length > 0)
        {
            CBMutableCharacteristic *transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:self.peripheralCaracteristicUUID]
                                                                                                 properties:CBCharacteristicPropertyNotify
                                                                                                      value:nil
                                                                                                permissions:CBAttributePermissionsReadable];
            transferService.characteristics = @[
                                                transferCharacteristic
                                                ];
        }
    
        [self.peripheralManager addService:transferService];
    
        [self.peripheralManager startAdvertising:@{
                                                   CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:self.peripheralUUID]],
                                                   CBAdvertisementDataLocalNameKey: self.peripheralName
                                                   }];
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral
                                       error:(NSError *)error
{
    BLog(@"Did start advertising : %@ error : %@", peripheral, error);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error
{
    BLog(@"Did add service : %@ ; Error : %@", service, error);
}

#pragma mark - Debug

- (void)debugIBeacon
{
    self.iBeacon = YES;

    if (self.locationManager)
    {
        [self turnOffLocation];
    }
    
    if (self.centralManager)
    {
        [self turnOffCentral];
    }
    
    if (self.peripheralManager == nil)
    {
        [self turnOnPeripheral];
    }
    else if (self.peripheralManager.state == CBPeripheralManagerStatePoweredOn)
    {
        [self startAdvertising];
    }
}

- (void)debugBeacon
{
    if (self.locationManager)
    {
        [self turnOffLocation];
    }
    
    if (self.centralManager)
    {
        [self turnOffCentral];
    }

    if (self.peripheralManager == nil)
    {
        [self turnOnPeripheral];
    }
    else if (self.peripheralManager.state == CBPeripheralManagerStatePoweredOn)
    {
        [self startAdvertising];
    }
}


#pragma mark - Detected Beacons

- (void)didDetectUUID:(NSUUID *)uuid
{
    for (Beacon *beacon in self.beacons)
    {
        if ([beacon.uuid isEqual:uuid])
        {
            [self didDetectBeacon:beacon];
            break;
        }
    }
}

- (void)didDetectBeacon:(Beacon *)beacon
{
    NSDictionary *dict = [self dictForBeacon:beacon];
    
    if (dict == nil)
    {
        BLog(@"Adding new Dict : %@", self.mutableDetectedBeacons);
        
        dict = @{
                 kBeaconManagerDateKey: [NSDate date],
                 kBeaconManagerBeaconKey: beacon
                 };
        
        [self.mutableDetectedBeacons addObject:dict];
        
        [self detectedBeaconsDidUpdate];
    }
    else
    {
        NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
        
        mutableDict[kBeaconManagerDateKey] = [NSDate date];
        
        NSUInteger index = [[self mutableDetectedBeacons] indexOfObject:dict];
        
        if (index != NSNotFound)
        {
            [self.mutableDetectedBeacons replaceObjectAtIndex:index withObject:[[NSDictionary alloc] initWithDictionary:mutableDict]];
        }
    }
}

- (NSDictionary *)dictForBeacon:(Beacon *)beacon
{
    for (NSDictionary *dict in self.detectedBeacons)
    {
        if ([dict[kBeaconManagerBeaconKey] isEqual:beacon])
        {
            return dict;
        }
    }
    return nil;
}

- (void)detectedBeaconsDidUpdate
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BeaconManagerBeaconsDetectedChangedNotification object:self];
    
    if (self.advertisePeripheralWhenBeaconDetected)
    {
        if (self.mutableDetectedBeacons.count == 0)
        {
            if (self.peripheralManager)
            {
                BLog(@"Turning Peripheral Off");
                [self turnOffPeripheral];
            }
        }
        else
        {
            if (self.peripheralManager == nil)
            {
                BLog(@"Turning Peripheral On");
                [self turnOnPeripheral];                
            }
        }
    }
}

- (void)refresh:(NSTimer *)timer
{
    BLog(@"Refresh");
    
    NSUInteger removed = 0;
    
    for (NSUInteger i = 0; i < self.mutableDetectedBeacons.count; )
    {
        NSDictionary *dict = self.mutableDetectedBeacons[i];
        
        NSDate *date = dict[kBeaconManagerDateKey];
        
        if (date.timeIntervalSinceNow * -1 > self.beaconExpiryAge)
        {
            removed++;
            [self.mutableDetectedBeacons removeObjectAtIndex:i];
        }
        else
        {
            i++;
        }
    }
    
    if (removed > 0)
    {
        [self detectedBeaconsDidUpdate];
    }
}

- (NSArray *)detectedBeacons
{
    return self.mutableDetectedBeacons;
}

@end
