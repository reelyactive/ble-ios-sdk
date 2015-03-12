//
//  ViewController.m
//  Bluetooth
//
//  Created by Callum Henshall on 02/03/15.
//  Copyright (c) 2015 Sidereo. All rights reserved.
//

#import "ViewController.h"

#import "BeaconManager.h"
#import "Beacon.h"

//static NSString * const kServiceUUID = @"7265656C-7941-6374-6976-652055554944";
static NSString * const kServiceUUID = @"00000000-0000-0000-0000-000000000000";

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setBeaconDetectedNotifications:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self setBeaconDetectedNotifications:NO];
}

- (IBAction)startCentralAction:(id)sender {
    
    if ([BeaconManager sharedManager].beacons.count == 0)
    {
        Beacon *beacon = [[Beacon alloc] initWithName:@"Test Beacon"
                                                 uuid:[[NSUUID alloc] initWithUUIDString:kServiceUUID]
                                                major:0
                                                minor:0];
        
        [[BeaconManager sharedManager] addBeacon:beacon];
    }
    
    [BeaconManager sharedManager].peripheralName = @"Test Beacon";
    [BeaconManager sharedManager].peripheralUUID = kServiceUUID;
    [BeaconManager sharedManager].advertisePeripheralWhenBeaconDetected = YES;

    [[BeaconManager sharedManager] setBeaconDetection:YES iBeacons:YES inBackground:YES];
}

- (IBAction)startPeripheralAction:(id)sender {

    [BeaconManager sharedManager].peripheralName = @"Test Beacon";
    [BeaconManager sharedManager].peripheralUUID = kServiceUUID;
    [BeaconManager sharedManager].peripheralCaracteristicUUID = kServiceUUID;
    
    [[BeaconManager sharedManager] debugIBeacon];
}

- (void)setBeaconDetectedNotifications:(BOOL)setNotifications
{
    if (setNotifications)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(beaconsDetectedUpdate:)
                                                     name:BeaconManagerBeaconsDetectedChangedNotification
                                                   object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:BeaconManagerBeaconsDetectedChangedNotification
                                                      object:nil];
    }
}

- (void)beaconsDetectedUpdate:(NSNotification *)notification
{
    [self notify:[NSString stringWithFormat:@"Did detect %llu beacons", (unsigned long long)[BeaconManager sharedManager].detectedBeacons.count]];
}

- (void)notify:(NSString *)message
{
    UILocalNotification *local = [[UILocalNotification alloc] init];
    
    local.fireDate = nil;
    
    local.alertTitle = @"Alert";
    local.alertBody = message;
    local.soundName = UILocalNotificationDefaultSoundName;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:local];
    
}

@end
