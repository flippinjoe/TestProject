// 
//  MFlowLaunchEvent.m
//  MFlowEventManagerDev
//
//  Created by Stephen Tallent on 6/22/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import "MFlowLaunchEvent.h"

@implementation MFlowLaunchEvent 

@dynamic EventID;
@dynamic LaunchStartTime;
@dynamic LaunchEndTime;


+(NSString *)className{
	return @"MFlowLaunchEvent";
}

+(NSNumber *)EventTypeID{
	return [NSNumber numberWithInt:1];
}

-(NSString *)asXML{
	static NSString *format = @"<Event>"
		"<EventID>%@</EventID>"
		"<LaunchStartTime>%@</LaunchStartTime>"
		"<LaunchEndTime>%@</LaunchEndTime>"
		"<Offset>%i</Offset>"
		"</Event>";
	
	return [NSString stringWithFormat:format,
						[self EventID],
						[kEventDateFormatter stringFromDate:[self LaunchStartTime]],
						[kEventDateFormatter stringFromDate:[self LaunchEndTime]],
						[MFlowEventManager sharedManager].GMTOffsetInMinutes
			];

}

@end
