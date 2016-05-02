//
//  BeaconManager.m
//  Bluetooth
//
//  Created by Callum Henshall on 03/03/15.
//  Copyright (c) 2015 reelyActive. All rights reserved.
//

@import UIKit; // Needed for the UIApplication Notifications
@import CoreBluetooth;
@import CoreLocation;

#import "RABeaconManager.h"

#import "RABeacon.h"
#import "RAIBeacon.h"
#import "RABeaconService.h"
#import "RAIBeaconService.h"

#define BLOG_DEBUG 0

#if BLOG_DEBUG
#   define BLog(...) NSLog(__VA_ARGS__)
#else
#   define BLog(...)
#endif

NSString *BeaconManagerBeaconsDetectedChangedNotification = @"BeaconManagerBeaconsDetectedChangedNotification";
NSString *BeaconManagerIBeaconsDetectedChangedNotification = @"BeaconManagerBeaconsDetectedChangedNotification";
NSString *BeaconManagerStateChangedNotification = @"BeaconManagerStateChangedNotification";

NSString *kBeaconManagerDateKey = @"kBeaconManagerDateKey";
NSString *kBeaconManagerBeaconKey = @"kBeaconManagerBeaconKey";
NSString *kBeaconManagerMacAddrKey = @"kBeaconManagerMacAddrKey";

NSString *beaconBackgroundAdvertisingDefaultURL = @"https://www.hyperlocalcontext.com/events";

static NSString * const kStoredBeaconServicesKey = @"kStoredBeaconServicesKey";
static NSString * const kStoredIBeaconServicesKey = @"kStoredIBeaconServicesKey";

static NSTimeInterval const kRefreshTimeInterval = 2.f;
static NSTimeInterval const kBeaconExpiryAge = 60.f;

@interface RABeaconManager () <CBCentralManagerDelegate, CBPeripheralManagerDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheralManager *peripheralManager;

@property (strong, nonatomic) CLLocationManager *locationManager;


@property (assign, nonatomic) BOOL detectInBackground;
@property (assign, nonatomic) BOOL detectBeacons;
@property (assign, nonatomic) BOOL detectIBeacons;


@property (assign, nonatomic) BeaconManagerState state;

@property (strong, nonatomic) NSArray *beaconServices;
@property (strong, nonatomic) NSArray *iBeaconServices;
@property (strong, nonatomic) NSMutableArray *mutableDetectedBeacons;
@property (strong, nonatomic) NSMutableArray *mutableDetectedIBeacons;

@property (strong, nonatomic) NSTimer *refreshTimer;

@property (assign, nonatomic) BOOL debugIBeacon;

@end

@implementation RABeaconManager

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
        self.mutableDetectedIBeacons = [[NSMutableArray alloc] init];
        
        [self loadBeaconServices];
        
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

- (NSArray *)loadItemsForKey:(NSString *)key
{
    
    NSArray *storedItems = [[NSUserDefaults standardUserDefaults] arrayForKey:key];
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    if (storedItems.count > 0)
    {
        for (NSData *itemData in storedItems)
        {
            id item = [NSKeyedUnarchiver unarchiveObjectWithData:itemData];
            [items addObject:item];
        }
        return [[NSArray alloc] initWithArray:items];
    }
    return @[];
}

- (void)loadBeaconServices
{
    self.beaconServices = [self loadItemsForKey:kStoredBeaconServicesKey];
    self.iBeaconServices = [self loadItemsForKey:kStoredIBeaconServicesKey];
}

- (void)persistItems:(NSArray *)items forKey:(NSString *)key
{
    NSMutableArray *itemDataArray = [[NSMutableArray alloc] init];
    
    for (id <NSCoding> item in items)
    {
        NSData *itemData = [NSKeyedArchiver archivedDataWithRootObject:item];
        [itemDataArray addObject:itemData];
    }
    [[NSUserDefaults standardUserDefaults] setObject:itemDataArray forKey:key];
}

- (void)persistBeacons
{
    [self persistItems:self.beaconServices forKey:kStoredBeaconServicesKey];
    [self persistItems:self.iBeaconServices forKey:kStoredIBeaconServicesKey];
}

- (void)addBeaconService:(RABeaconService *)beaconService
{
    for (RABeaconService *aBeaconService in self.beaconServices)
    {
        if ([aBeaconService isEqualToBeaconService:beaconService])
        {
            return;
        }
    }
    
    [self refreshBeaconScanning];
    
    self.beaconServices = [self.beaconServices arrayByAddingObject:beaconService];
    
    [self persistBeacons];
}

- (void)addIBeaconService:(RAIBeaconService *)iBeaconService
{
    for (RAIBeaconService *aIBeaconService in self.iBeaconServices)
    {
        if ([aIBeaconService isEqualToIBeaconService:iBeaconService])
        {
            return;
        }
    }
    
    [self startMonitoringIBeaconService:iBeaconService];
    [self refreshBeaconScanning];
    
    self.iBeaconServices = [self.iBeaconServices arrayByAddingObject:iBeaconService];
    
    [self persistBeacons];
}

- (void)removeBeaconService:(RABeaconService *)beaconService
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(RABeaconService *evaluatedObject, NSDictionary *bindings)
                              {
                                  if ([evaluatedObject isEqualToBeaconService:beaconService])
                                  {
                                      return NO;
                                  }
                                  else
                                  {
                                      return YES;
                                  }
                              }];
    
    self.beaconServices = [self.beaconServices filteredArrayUsingPredicate:predicate];

    [self refreshBeaconScanning];

    [self persistBeacons];
}

- (void)removeIBeaconService:(RAIBeaconService *)iBeaconService
{
    [self stopMonitoringIBeaconService:iBeaconService];
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(RAIBeaconService *evaluatedObject, NSDictionary *bindings)
                              {
                                  if ([evaluatedObject isEqualToIBeaconService:iBeaconService])
                                  {
                                      return NO;
                                  }
                                  else
                                  {
                                      return YES;
                                  }
                              }];
    
    self.iBeaconServices = [self.iBeaconServices filteredArrayUsingPredicate:predicate];
    
    [self persistBeacons];
}

- (void)removeAllServices
{
    self.beaconServices = @[];
    
    [self refreshBeaconScanning];
    
    for (RAIBeaconService *iBeaconService in self.iBeaconServices)
    {
        [self stopMonitoringIBeaconService:iBeaconService];
    }
    self.iBeaconServices = @[];
    
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
        if (self.detectBeacons)
        {
            [self turnOffCentral];
        }
        
        if (self.detectIBeacons)
        {
            [self turnOffLocation];
        }
    }else if (self.detectBeacons && self.advertisePeripheralWhenBeaconDetected && self.peripheralServiceUUID != nil){
        
        // Need to call beginBackgroundTaskWithName to keep the app runing in background
        [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"fakeAdvertising" expirationHandler:^{}];
            
        // Start background task
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND,0), ^{
            [self advertisingBackgroundTask];
        });
    }
}

- (void) advertisingBackgroundTask
{
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    
    if(state == UIApplicationStateBackground || state == UIApplicationStateInactive){
    
        if([self.mutableDetectedBeacons count] > 0){
            [self fakeAdvertisingRequest];
        }
        
        [NSThread sleepForTimeInterval:(5)];
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND,0), ^{
            [self advertisingBackgroundTask];
        });
    }
}

- (void) fakeAdvertisingRequest
{
    // Build NSData
    NSData *data = [self buildData];
    
    // Send request if build data succeeded
    if(data != nil){
    
        NSString *url = [self beaconBackgroundAdvertisingURL] != nil ? [self beaconBackgroundAdvertisingURL] : beaconBackgroundAdvertisingDefaultURL;
        
        @try {
            
            NSError *error = nil;
            NSURLResponse* response;
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:url]
                                                                        cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
            [request setHTTPBody:data];
            
            [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
        } @catch (NSException *exception) {
            
            NSLog(@"Excepetion %@", exception);
        }
        
    }
}

-(NSData*) buildData
{
    NSString *perifUUID = self.peripheralServiceUUID;
    perifUUID = perifUUID != nil ? [perifUUID stringByReplacingOccurrencesOfString:@"-" withString:@""] : @"DEFAULT";

    NSMutableArray *tab = [NSMutableArray array];
    
    for (NSObject *o in self.mutableDetectedBeacons) {
        
        NSMutableDictionary *d = (NSMutableDictionary *)o;
        
        RABeacon *b = [(RABeacon *) d valueForKey:@"kBeaconManagerBeaconKey"];
        if( b != nil && b.systemID != nil){
            
            int theRssi = b.rssi != nil ? 0 : [b.rssi intValue];
            theRssi = [b.rssi intValue] > 0 ? [b.rssi intValue] -128 : [b.rssi intValue] + 128;
            
            NSMutableDictionary *id_dict = [NSMutableDictionary dictionary];
            [id_dict setObject:@"EUI-64" forKey:@"type"];
            [id_dict setObject:b.systemID forKey:@"value"];
            
            NSMutableDictionary *item_dict = [NSMutableDictionary dictionary];
            [item_dict setObject: [NSNumber numberWithInt:theRssi ] forKey:@"rssi"];
            [item_dict setObject:id_dict forKey:@"identifier"];
            
            [tab addObject:item_dict];
        }
    }
    
    NSMutableDictionary *advData = [NSMutableDictionary dictionary];
    [advData setObject:perifUUID forKey:@"complete128BitUUIDs"];
    
    NSMutableDictionary *advHeader = [NSMutableDictionary dictionary];
    [advHeader setObject:@"random" forKey:@"txAdd"];

    NSMutableDictionary *identifier = [NSMutableDictionary dictionary];
    [identifier setObject:@"ADVA-48" forKey:@"type"];
    [identifier setObject: [self getMacAddr] forKey:@"value"];
    [identifier setObject:advHeader forKey:@"advHeader"];
    [identifier setObject:advData forKey:@"advData"];
    
    NSMutableDictionary *tiraid = [NSMutableDictionary dictionary];
    [tiraid setObject:identifier forKey:@"identifier"];
    [tiraid setObject:[self getFormatedDate] forKey:@"timestamp"];
    [tiraid setObject:tab forKey:@"radioDecodings"];
    
    NSMutableDictionary *obj = [NSMutableDictionary dictionary];
    [obj setObject:@"appearance" forKey:@"event"];
    [obj setObject:tiraid forKey:@"tiraid"];
    
    // Convert to json
    NSData *json;
    
    // Dictionary convertable to JSON ?
    if ([NSJSONSerialization isValidJSONObject:obj])
    {
        // Serialize the dictionary
        NSError *error = nil;
        json = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:&error];
    }

    return json;
}


-(NSString*)getMacAddr
{
    if([[NSUserDefaults standardUserDefaults] valueForKey: kBeaconManagerMacAddrKey] == nil){
    
        NSString *addr = @"";
        
        for (int i =0; i < 6; i++) {
            int n = arc4random_uniform(254);
            addr = [addr stringByAppendingFormat:@"%02x",n];
        }
        
        [[NSUserDefaults standardUserDefaults] setValue:[addr lowercaseString] forKey:kBeaconManagerMacAddrKey];
    }
    
    return [[NSUserDefaults standardUserDefaults] valueForKey: kBeaconManagerMacAddrKey];
}

-(NSString*)getFormatedDate
{
    NSDate *d = [[NSDate alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    NSString *date = [dateFormatter stringFromDate: d];
    
    return date;
}

- (void)appWillEnterForegroundActive:(NSNotification *)notification
{
    BLog(@"appWillEnterForegroundActive");
    if (self.detectInBackground == NO)
    {
        if (self.detectBeacons)
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
        for (RAIBeaconService *iBeaconService in self.iBeaconServices)
        {
            [self startMonitoringIBeaconService:iBeaconService];
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
        for (RAIBeaconService *iBeaconService in self.iBeaconServices)
        {
            [self stopMonitoringIBeaconService:iBeaconService];
        }
    }
    
    [self.locationManager stopUpdatingLocation];
    
    self.locationManager = nil;
    
    [self updateState];
}

- (void)startMonitoringIBeaconService:(RAIBeaconService *)iBeaconService
{
    CLBeaconRegion *beaconRegion = iBeaconService.beaconRegion;
    
    beaconRegion.notifyOnEntry = YES;
    beaconRegion.notifyEntryStateOnDisplay = YES;
    beaconRegion.notifyOnExit = YES;
    
    [self.locationManager startMonitoringForRegion:beaconRegion];
    [self.locationManager startRangingBeaconsInRegion:beaconRegion];
}

- (void)stopMonitoringIBeaconService:(RAIBeaconService *)iBeaconService
{
    CLBeaconRegion *beaconRegion = iBeaconService.beaconRegion;
    
    [self.locationManager stopMonitoringForRegion:beaconRegion];
    [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
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
        [self didDetectCLBeacon:beacon];
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
    
    if (self.beaconServices.count == 0)
    {
        [self.centralManager stopScan];
    }
    else
    {
        NSDictionary *scanOptions = @{
                                      CBCentralManagerScanOptionAllowDuplicatesKey: @(YES)
                                      };
        
        NSMutableArray *identifiers = [[NSMutableArray alloc] init];
        
        for (RABeaconService *beaconService in self.beaconServices)
        {
            BLog(@"UUID : %@", beaconService.serviceUUID.UUIDString);
            [identifiers addObject:[CBUUID UUIDWithNSUUID:beaconService.serviceUUID]];
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
    
    CBUUID *systemUUIDKey = [CBUUID UUIDWithData:[NSData dataWithBytes:"\x2A\x23" length:2]];
    NSDictionary *serviceData = advertisementData[CBAdvertisementDataServiceDataKey];
    NSString *sysIDString = nil;
    if (serviceData)
    {
        NSData *sysID = serviceData[systemUUIDKey];
        if (sysID && [sysID length] >= 8) {
            unsigned char *s = (unsigned char*)sysID.bytes;
            sysIDString = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x", s[7], s[6], s[5], s[4], s[3], s[2], s[1], s[0]];
        }
    }
    
    for (CBUUID *uuid in uuids)
    {
        [self didDetectServiceUUID:[[NSUUID alloc] initWithUUIDString:uuid.UUIDString] systemID:sysIDString rssi:RSSI];
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
    if (self.peripheralServiceUUID.length == 0 || self.peripheralName.length < 1)
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
    
    if (self.debugIBeacon)
    {
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:self.peripheralServiceUUID];
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

        CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:self.peripheralServiceUUID]
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
                                                   CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:self.peripheralServiceUUID]],
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

- (void)startDebuggingIBeacon
{
    self.debugIBeacon = YES;

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

- (void)startDebuggingBeacon
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

- (void)didDetectServiceUUID:(NSUUID *)uuid systemID:(NSString*)sysIDString rssi:(NSNumber*)rssi
{
    for (RABeaconService *beaconService in self.beaconServices)
    {
        if ([beaconService.serviceUUID isEqual:uuid])
        {
            RABeacon *beacon = [[RABeacon alloc] initWithBeaconService:beaconService
                                                              systemID:sysIDString
                                                                  rssi:rssi];
            
            [self didDetectBeacon:beacon];
            break;
        }
    }
}

- (void)didDetectBeacon:(RABeacon *)beacon
{
    NSDictionary *dict = [self dictForBeacon:beacon];
    
    if (self.filterBeaconBlock && self.filterBeaconBlock(beacon) == NO)
    {
        return;
    }
    
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
            // Update to override rssi
            mutableDict[kBeaconManagerBeaconKey] = beacon;

            [self.mutableDetectedBeacons replaceObjectAtIndex:index withObject:[[NSDictionary alloc] initWithDictionary:mutableDict]];
        }
    }
}

- (void)didDetectCLBeacon:(CLBeacon *)clBeacon
{
    RAIBeaconService *tmpIBeaconService = clBeacon.iBeaconService;
    
    for (RAIBeaconService *iBeaconService in self.iBeaconServices) {
        
        if ([iBeaconService isEqualToIBeaconService:tmpIBeaconService])
        {
            RAIBeacon *iBeacon = [[RAIBeacon alloc] initWithBeacon:iBeaconService CLBeacon:clBeacon];
            
            [self didDetectIBeacon:iBeacon];
            return;
        }
    }
}

- (void)didDetectIBeacon:(RAIBeacon *)iBeacon
{
    NSDictionary *dict = [self dictForIBeacon:iBeacon];
    
    if (self.filterIBeaconBlock && self.filterIBeaconBlock(iBeacon) == NO)
    {
        return;
    }
    
    if (dict == nil)
    {
        BLog(@"Adding new Dict : %@", self.mutableDetectedIBeacons);
        
        dict = @{
                 kBeaconManagerDateKey: [NSDate date],
                 kBeaconManagerBeaconKey: iBeacon
                 };
        
        [self.mutableDetectedIBeacons addObject:dict];
        
        [self detectedIBeaconsDidUpdate];
    }
    else
    {
        NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
        
        mutableDict[kBeaconManagerDateKey] = [NSDate date];
        
        NSUInteger index = [[self mutableDetectedIBeacons] indexOfObject:dict];
        
        if (index != NSNotFound)
        {
            [self.mutableDetectedIBeacons replaceObjectAtIndex:index withObject:[[NSDictionary alloc] initWithDictionary:mutableDict]];
        }
    }
}


- (NSDictionary *)dictForBeacon:(RABeacon *)beacon
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

- (NSDictionary *)dictForIBeacon:(RAIBeacon *)iBeacon
{
    for (NSDictionary *dict in self.detectedIBeacons)
    {
        if ([dict[kBeaconManagerBeaconKey] isEqual:iBeacon])
        {
            return dict;
        }
    }
    return nil;
}

- (void)detectedBeaconsDidUpdate
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BeaconManagerBeaconsDetectedChangedNotification object:self];
    
    [self advertisePeripheralIfNeeded];
}

- (void)detectedIBeaconsDidUpdate
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BeaconManagerIBeaconsDetectedChangedNotification object:self];
    
    [self advertisePeripheralIfNeeded];
}

- (void)advertisePeripheralIfNeeded
{
    if (self.advertisePeripheralWhenBeaconDetected)
    {
        if (self.mutableDetectedBeacons.count == 0 && self.mutableDetectedIBeacons.count == 0)
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
    BLog(@"Refreshing Beacons List");
    if ([self refreshDetectedBeacons:self.mutableDetectedBeacons])
    {
        [self detectedBeaconsDidUpdate];
    }
    
    BLog(@"Refreshing iBeacons List");
    if ([self refreshDetectedBeacons:self.mutableDetectedIBeacons])
    {
        [self detectedIBeaconsDidUpdate];
    }
}

- (BOOL)refreshDetectedBeacons:(NSMutableArray *)detectedBeacons
{
    NSUInteger removed = 0;
    
    for (NSUInteger i = 0; i < detectedBeacons.count; )
    {
        NSDictionary *dict = detectedBeacons[i];
        
        NSDate *date = dict[kBeaconManagerDateKey];
        
#if BLOG_DEBUG
        id beacon = dict[kBeaconManagerBeaconKey];
        
        if ([beacon isKindOfClass:[RABeacon class]])
        {
            RABeacon *beacon = beacon;
            
            BLog(@"Beacon expires in : %lf", (double)(self.beaconExpiryAge - date.timeIntervalSinceNow * -1));
        }
        else if ([beacon isKindOfClass:[RAIBeacon class]])
        {
            RAIBeacon *beacon = beacon;
            
            BLog(@"iBeacon expires in : %lf", (double)(self.beaconExpiryAge - date.timeIntervalSinceNow * -1));
        }
#endif
        
        if (date.timeIntervalSinceNow * -1 > self.beaconExpiryAge)
        {
            removed++;
            [detectedBeacons removeObjectAtIndex:i];
        }
        else
        {
            i++;
        }
    }
    
    if (removed > 0)
    {
        return YES;
    }
    return NO;
}

- (NSArray *)detectedBeacons
{
    return self.mutableDetectedBeacons;
}

- (NSArray *)detectedIBeacons
{
    return self.mutableDetectedIBeacons;
}

@end
