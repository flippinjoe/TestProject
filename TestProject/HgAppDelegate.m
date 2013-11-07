//
//  HgAppDelegate.m
//  TestProject
//
//  Created by Joseph Ridenour on 10/31/12.
//  Copyright (c) 2012 Mercury. All rights reserved.
//

#import "HgAppDelegate.h"


@implementation HgAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.window.rootViewController = [[NSClassFromString(@"HgViewController") alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
