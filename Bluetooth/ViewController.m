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

static NSString * const kServiceUUID = @"7265656C-7941-6374-6976-652055554944";

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

- (IBAction)startCentralAction:(id)sender {
    
    if ([BeaconManager sharedManager].beacons.count == 0)
    {
        Beacon *beacon = [[Beacon alloc] initWithName:@"Test Beacon"
                                                 uuid:[[NSUUID alloc] initWithUUIDString:kServiceUUID]
                                                major:0
                                                minor:0];
        
        [[BeaconManager sharedManager] addBeacon:beacon];
    }
    
    [[BeaconManager sharedManager] setPeripheralName:@"Test Beacon"];
    [[BeaconManager sharedManager] setPeripheralUUID:kServiceUUID];
    
    [[BeaconManager sharedManager] setBeaconDetection:YES];
}

- (IBAction)startPeripheralAction:(id)sender {

    [[BeaconManager sharedManager] setPeripheralName:@"Test Beacon"];
    [[BeaconManager sharedManager] setPeripheralUUID:kServiceUUID];
    
    [[BeaconManager sharedManager] debugIBeacon];
}

@end
