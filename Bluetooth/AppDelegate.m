//
//  AppDelegate.m
//  Bluetooth
//
//  Created by Callum Henshall on 02/03/15.
//  Copyright (c) 2015 reelyActive. All rights reserved.
//

#import "AppDelegate.h"

#import "RABeaconManager.h"
#import "RABeaconService.h"
#import "RAIBeaconService.h"

#import "RABeacon.h"
#import "RAIBeacon.h"

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

    if ([RABeaconManager sharedManager].beaconServices.count != 1
        && [RABeaconManager sharedManager].iBeaconServices.count != 1)
    {
        // remove all services that were saved by the Beacon Manager
        [[RABeaconManager sharedManager] removeAllServices];
        
        RABeaconService *beaconService = [[RABeaconService alloc] initWithName:@"Test Beacon"
                                                                          uuid:[[NSUUID alloc] initWithUUIDString:kServiceUUID]];
        [[RABeaconManager sharedManager] addBeaconService:beaconService];
        
        RAIBeaconService *iBeaconService = [[RAIBeaconService alloc] initWithName:@"Test iBeacon"
                                                                             UUID:[[NSUUID alloc] initWithUUIDString:kServiceUUID]
                                                                            major:1
                                                                            minor:1];
        [[RABeaconManager sharedManager] addIBeaconService:iBeaconService];
    }

    [RABeaconManager sharedManager].filterBeaconBlock = ^BOOL(RABeacon *beacon)
    {
        return YES;
    };
    
    [RABeaconManager sharedManager].filterIBeaconBlock = ^BOOL(RAIBeacon *beacon)
    {
        return YES;
    };
    
    [RABeaconManager sharedManager].peripheralName = @"Test Beacon";
    [RABeaconManager sharedManager].peripheralServiceUUID = kServiceUUID;
    [RABeaconManager sharedManager].advertisePeripheralWhenBeaconDetected = YES;
    
    [[RABeaconManager sharedManager] setBeaconDetection:YES iBeacons:YES inBackground:YES];
    
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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(iBeaconsDetectedUpdate:)
                                                     name:BeaconManagerIBeaconsDetectedChangedNotification
                                                   object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:BeaconManagerBeaconsDetectedChangedNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:BeaconManagerIBeaconsDetectedChangedNotification
                                                      object:nil];
    }
}

- (void)beaconsDetectedUpdate:(NSNotification *)notification
{
    [self notify:[NSString stringWithFormat:@"Did detect %llu beacons", (unsigned long long)[RABeaconManager sharedManager].detectedBeacons.count]];
}

- (void)iBeaconsDetectedUpdate:(NSNotification *)notification
{
    [self notify:[NSString stringWithFormat:@"Did detect %llu iBeacons", (unsigned long long)[RABeaconManager sharedManager].detectedIBeacons.count]];
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
