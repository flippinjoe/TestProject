// 
//  MFlowAggEvent.m
//  MFlowEventManagerDev
//
//  Created by Stephen Tallent on 6/22/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import "MFlowAggEvent.h"

@implementation MFlowAggEvent 

@dynamic EventDuration;
@dynamic EventData;
@dynamic AggType;
@dynamic EventIsActive;
@dynamic EventTimeStamp;
@dynamic EventItemID;
@dynamic EventParentID;
@dynamic EventID;
@dynamic EventCount;
@dynamic EventType;


+(NSString *)className{
	return @"MFlowAggEvent";
}


-(NSString *)asXML{
	static NSString *format = @"<Evt>"
				"<EID>%@</EID>"  //  <-- GUID, up to 40 characters (hyphens are not counted in total) -->
				"<ST>%@</ST>"  //  <!--client starting timestamp, use MM/dd/yyyy HH:mm:ss format -->
				"<Typ>%@</Typ>"  //  <!-- event type ID -->
				"<Dat>%@</Dat>"  //  <-- meta data associated with aggregated event -->
				"<Cnt>%@</Cnt>"  // <!-- total count -->
				"<IID>%@</IID>"  //  <!-- item ID of item being counted -->
				"<Dur>%@</Dur>"  //  <!-- total duration in seconds -->
				"<Act>%@</Act>"  //  <!-- 1 or 0, was the event considered active (user engaged) or passive (system)
				"<Par>%@</Par>"  //  <!-- up to 64 character name of parent item, optional  -->
				"<Offset>%i</Offset>"
				"</Evt>";
	
	return [NSString stringWithFormat:format,
			[self EventID],
			[kEventDateFormatter stringFromDate:[self EventTimeStamp]],
			[self EventType],
			([self EventData] == nil) ? @"" : [self EventData],
			[self EventCount],
			[self EventItemID],
			[self EventDuration],
			[self EventIsActive],
			[self EventParentID],
			[MFlowEventManager sharedManager].GMTOffsetInMinutes
			];
	
}


@end
