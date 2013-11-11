//
//  HgAppDelegate.m
//  TestProject
//
//  Created by Joseph Ridenour on 10/31/12.
//  Copyright (c) 2012 Mercury. All rights reserved.
//

#import "HgAppDelegate.h"
#import <MercuryCore/MFlowConfig.h>

@implementation HgAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *implementation;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        implementation = @"iPad";
    else
        implementation = @"HVGA";
    
    if([[UIScreen mainScreen] scale] > 1)
    {
        implementation = [implementation stringByAppendingString:@"2x"];
        if([UIScreen mainScreen].scale == 2.f && [[UIScreen mainScreen] bounds].size.height == 568.0f)
        { implementation = [implementation stringByAppendingString:@"h"]; }
    }
    
    [MFlowConfig initMFlowWithConfig:@{
                                       MFlowConfigKeys.stagingAppURLKey:@"http://showtime.staging.mercury.io",
                                       MFlowConfigKeys.liveAppURLKey:@"http://showtime.mercuryintermedia.net",
                                       MFlowConfigKeys.productKey:@"Showtime",
                                       MFlowConfigKeys.distributionIDKey:@9
                                       }];
    
    [MFlowConfig dump];
    
//    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
//    self.window.rootViewController = [[NSClassFromString(@"HgViewController") alloc] init];
//    [self.window makeKeyAndVisible];
    
    if([MFlowConfig sharedInstance].usingStaging)
    {
        [[[UIAlertView alloc] initWithTitle:@"Staging Enabled" message:@"You have enabled staging" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    }
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [MFlowConfig dump];
    if([MFlowConfig sharedInstance].usingStaging)
    {
        [[[UIAlertView alloc] initWithTitle:@"Staging Enabled" message:@"You have enabled staging" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    }
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
