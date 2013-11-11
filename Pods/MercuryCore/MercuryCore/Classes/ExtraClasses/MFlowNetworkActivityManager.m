//
//  MFlowNetworkActivityManager.m
//  JournalSentinel
//
//  Created by Demetri Miller on 9/4/12.
//  Copyright (c) 2012 Mercury Intermedia. All rights reserved.
//

#import "MFlowNetworkActivityManager.h"

@implementation MFlowNetworkActivityManager

#pragma mark - Lifecycle
+ (id)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static id _instance = nil;
    dispatch_once(&pred, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _showWhenActive = NO;
        _activityCount = 0;
    }
    return self;
}

- (void)setShowWhenActive:(BOOL)showWhenActive
{
    _showWhenActive = showWhenActive;
    if (showWhenActive == NO) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}

#pragma mark - Display
- (void)incrementActivityCount
{
    @synchronized(self) {
        _activityCount++;
    }

    [self updateActivityIndicatorForCurrentCount];
}


- (void)decrementActivityCount
{
    @synchronized(self) {
        _activityCount = MAX(0, _activityCount-1);
    }

    [self updateActivityIndicatorForCurrentCount];
}

- (void)updateActivityIndicatorForCurrentCount
{
    if (_showWhenActive) {
        if (_activityCount > 0) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        } else {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
    }
}

@end
