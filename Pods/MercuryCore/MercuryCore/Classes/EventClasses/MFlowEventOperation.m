//
//  MFlowEventOperation.m
//  USAToday1
//
//  Created by Stephen Tallent on 1/28/10.
//  Copyright 2010 Mercury Intermedia. All rights reserved.
//

#import "MFlowEventOperation.h"
#import "MFlowEventManager.h"
#import "TC_NSDateExtensions.h"

// TODO: depreciate this, moving to dispatch based uploading from the manager with an async connection.

@implementation MFlowEventOperation


-(void)main{
	/*
	NSTimeInterval ti = [[NSDate date] timeIntervalSinceReferenceDate];
	
	ti = ti - (3 * 24 * 60 * 60);
	
	NSDate *d = [NSDate dateWithTimeIntervalSinceReferenceDate:ti];
	
	NSArray *a = [[MFlowEventManager sharedManager] allLaunchEventsBeforeDate:d];
	
	if (a.count > 0) {
		
		[[MFlowEventManager sharedManager] uploadEventsWithDate:[[NSDate date] dateRoundedDownToDay]];
		
	}
	*/
}

@end
