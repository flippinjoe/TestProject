//
//  MFlowNetworkActivityManager.h
//  JournalSentinel
//
//  Created by Demetri Miller on 9/4/12.
//  Copyright (c) 2012 Mercury Intermedia. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
    This class is a singleton wrapper around the networkActivityIndicator
    that gets displayed in the status bar of the device.
 
    Display of the indicator is disabled by default. Developers using 
    this class need only set the showWhenActive flag to have it appear.
    
    If a developer chooses this class, it should use this class for all
    management of the indicator. While the MFlow classes provide support
    already, it is the developer's responsibility to manage the indicator for any
    network communications outside this class. To show activity, simply
    increment the activity counter.
 */
@interface MFlowNetworkActivityManager : NSObject
{
    int _activityCount;
}

/** @name Managing activity indicator display */
/// When set, the activity indicator will appear while network communications are occurring.
@property(nonatomic, assign) BOOL showWhenActive;

/** @name Lifecycle */
/// Returns the singleton instance for this class.
+ (id)sharedInstance;


/** @name Activity indicator display */
/// Increments the activity count showing the indicator if needed.
- (void)incrementActivityCount;

/// Decrements the activity count hiding the indicator if needed.
- (void)decrementActivityCount;

@end
