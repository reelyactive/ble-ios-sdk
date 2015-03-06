//
//  BeaconManager.m
//  Bluetooth
//
//  Created by Callum Henshall on 03/03/15.
//  Copyright (c) 2015 Sidereo. All rights reserved.
//

#import "BeaconManager.h"

#import <CoreBluetooth/CoreBluetooth.h>

#import <CoreLocation/CoreLocation.h>

#import "Beacon.h"

NSString *BeaconManagerBeaconsDetectedChangedNotification = @"BeaconManagerBeaconsDetectedChangedNotification";

NSString *kBeaconManagerDateKey = @"kBeaconManagerDateKey";
NSString *kBeaconManagerBeaconKey = @"kBeaconManagerBeaconKey";

static NSString * const kCaracteristicUUID = @"7265656C-7941-6374-6976-652055554945";


static NSString * const kStoredBeaconsKey = @"kStoredBeaconsKey";

static NSTimeInterval const kRefreshTimeInterval = 2.f;
static NSTimeInterval const kRemoveBeaconAge = 10.f;

@interface BeaconManager () <CBCentralManagerDelegate, CBPeripheralManagerDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheralManager *peripheralManager;

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) NSArray *beacons; // Beacon

@property (strong, nonatomic) NSMutableArray *mutableDetectedBeacons; // NSDictionary

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
    }
    return self;
}

- (void)dealloc
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

- (void)setBeaconDetection:(BOOL)detectBeacons
{
    if (detectBeacons)
    {
//        [self turnOnLocation];
        [self turnOnCentral];
        
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:kRefreshTimeInterval
                                                             target:self
                                                           selector:@selector(refresh:)
                                                           userInfo:nil
                                                            repeats:YES];
    }
    else
    {
        
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
    [self startMonitoringBeacon:beacon];
    [self refreshBeaconScanning];
    
    self.beacons = [self.beacons arrayByAddingObject:beacon];
    
    [self persistBeacons];
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

#pragma mark - CLLocationManagerDelegate

- (void)turnOnLocation
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager requestAlwaysAuthorization];
    self.locationManager.pausesLocationUpdatesAutomatically = NO;

    [CLLocationManager locationServicesEnabled];
    
    for (Beacon *beacon in self.beacons)
    {
        [self startMonitoringBeacon:beacon];
    }
    
    [self.locationManager startUpdatingLocation];
}

- (void)startMonitoringBeacon:(Beacon *)beacon
{
    CLBeaconRegion *beaconRegion = beacon.beaconRegion;
    
    beaconRegion.notifyOnEntry = YES;
    beaconRegion.notifyEntryStateOnDisplay = YES;
    beaconRegion.notifyOnExit = YES;
    
    [self.locationManager startMonitoringForRegion:beaconRegion];
    [self.locationManager startRangingBeaconsInRegion:beaconRegion];
}

- (void)stopMonitoringBeacon:(Beacon *)beacon
{
    CLBeaconRegion *beaconRegion = beacon.beaconRegion;
    
    [self.locationManager stopMonitoringForRegion:beaconRegion];
    [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"Did enter region: %@", region);
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"Did exit region: %@", region);
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    NSLog(@"Did determine state : %lld for region : %@", (long long)state, region);
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSLog(@"Did range beacons : %lld, %@", (long long)beacons.count, region);
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"Failed monitoring region: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Location manager failed: %@", error);
}

#pragma mark - CBCentralManagerDelegate

- (void)turnOnCentral
{
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil
                                                             options:@{
                                                                       CBCentralManagerOptionShowPowerAlertKey: @(YES)
                                                                       }];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"-- central state changed: %lld", (long long)self.centralManager.state);
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self refreshBeaconScanning];
    }
}

- (void)refreshBeaconScanning
{
    if (self.centralManager.state != CBCentralManagerStatePoweredOn)
    {
        NSLog(@"Error Central Manager is not powered on : state %lld", (long long)self.centralManager.state);
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
            NSLog(@"UUID : %@", beacon.uuid.UUIDString);
            [identifiers addObject:[CBUUID UUIDWithNSUUID:beacon.uuid]];
        }
        
        [self.centralManager scanForPeripheralsWithServices:identifiers
                                                    options:scanOptions];
        
//        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        
        //    CBUUID *identifier = [CBUUID UUIDWithString:serviceUUID];
        //    [self.centralManager scanForPeripheralsWithServices:@[
        //                                                          identifier
        //                                                          ]
        //                                                options:scanOptions];
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
    
//    NSLog(@"Found Peripheral Name : %@ : %@ : %@", peripheral.name, peripheral.identifier.UUIDString, advertisementData);
    //    [[NSNotificationCenter defaultCenter] postNotificationName:@"notman.detected" object:self userInfo:nil];
    
    //    [self.centralManager connectPeripheral:peripheral options:@{
    //                                                                CBConnectPeripheralOptionNotifyOnConnectionKey:@(YES)
    //                                                                }];
}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Did connect to peripheral");
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
    NSLog(@"-- peripheral state changed: %lld", (long long)self.peripheralManager.state);
    if (peripheral.state == CBPeripheralManagerStatePoweredOn)
    {
        [self startAdvertising];
    }
}

- (void)startAdvertising
{
    if (self.peripheralManager.state != CBPeripheralManagerStatePoweredOn)
    {
        NSLog(@"Error Peripheral Manager is not powered on : state %lld", (long long)self.peripheralManager.state);
        return;
    }
    
    if (self.peripheralUUID.length == 0 || self.peripheralName.length < 1)
    {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Need peripheral UUID and Name" userInfo:nil];
        return;
    }
    
//    CBMutableCharacteristic *transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:self.peripheralUUID]
//                                                                                         properties:CBCharacteristicPropertyNotify
//                                                                                              value:nil
//                                                                                        permissions:CBAttributePermissionsReadable];
    
    // Then the service
    CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:self.peripheralUUID]
                                                                       primary:YES];
    
    // Add the characteristic to the service
//    transferService.characteristics = @[
//                                        transferCharacteristic
//                                        ];
    
    // And add it to the peripheral manager
    [self.peripheralManager addService:transferService];
    
    
    [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:self.peripheralUUID]],
                                               
                                               CBAdvertisementDataLocalNameKey: self.peripheralName
                                               }];
    
    
//    if (self.iBeacon)
//    {
//        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:self.peripheralUUID];
//        NSString *identifier = self.peripheralName;
//        
////        CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
////                                                                               major:0
////                                                                               minor:0
////                                                                          identifier:identifier];
//
//        CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
//                                                                          identifier:identifier];
//
//        
//        //Passing nil will use the device default power
//        NSDictionary *payload = [beaconRegion peripheralDataWithMeasuredPower:nil];
//        
//        //Start advertising
//        [self.peripheralManager startAdvertising:payload];
//    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
                  central:(CBCentral *)central
didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Did connect to central");
}

- (void)debugIBeacon
{
    self.iBeacon = YES;

    if (self.peripheralManager == nil)
    {
        [self turnOnPeripheral];
    }
    else
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
    
    if (self.mutableDetectedBeacons.count == 0)
    {
        NSLog(@"Turning Peripheral Off");
        [self turnOffPeripheral];
    }
    else
    {
        NSLog(@"Turning Peripheral On");
        [self turnOnPeripheral];
    }
}

- (void)refresh:(NSTimer *)timer
{
    NSUInteger removed = 0;
    
    for (NSUInteger i = 0; i < self.mutableDetectedBeacons.count; )
    {
        NSDictionary *dict = self.mutableDetectedBeacons[i];
        
        NSDate *date = dict[kBeaconManagerDateKey];
        
        if (date.timeIntervalSinceNow * -1 > kRemoveBeaconAge)
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
