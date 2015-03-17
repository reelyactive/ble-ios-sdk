//
//  AppDelegate.m
//  Bluetooth
//
//  Created by Callum Henshall on 02/03/15.
//  Copyright (c) 2015 reelyActive. All rights reserved.
//

#import "AppDelegate.h"

#import "BeaconManager.h"
#import "Beacon.h"

static NSString * const kServiceUUID = @"00000000-0000-0000-0000-000000000000";

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound
                                                                                         categories:nil];
    
    [application registerUserNotificationSettings:notificationSettings];
    
    
    [self notify:@"Launching"];
    
    
    [self setBeaconDetectedNotifications:YES];

    if ([BeaconManager sharedManager].beacons.count != 2)
    {
        // Create an iBeacon to detect
        Beacon *iBeacon = [[Beacon alloc] initWithName:@"Test iBeacon"
                                                  uuid:[[NSUUID alloc] initWithUUIDString:kServiceUUID]
                                                 major:0
                                                 minor:0];
        
        [[BeaconManager sharedManager] addBeacon:iBeacon];
        
        // Create a Beacon to detect
        Beacon *beacon = [[Beacon alloc] initWithName:@"Test Beacon" uuid:[[NSUUID alloc]
                                                                           initWithUUIDString:kServiceUUID]];
        
        [[BeaconManager sharedManager] addBeacon:beacon];
    }
    
    [BeaconManager sharedManager].peripheralName = @"Test Beacon";
    [BeaconManager sharedManager].peripheralUUID = kServiceUUID;
    [BeaconManager sharedManager].advertisePeripheralWhenBeaconDetected = YES;
        
    [[BeaconManager sharedManager] setBeaconDetection:YES iBeacons:YES inBackground:YES];
    
    return YES;
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


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.    
}

@end
