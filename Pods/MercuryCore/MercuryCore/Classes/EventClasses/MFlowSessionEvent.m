// 
//  MFlowSessionEvent.m
//  MFlowEventManagerDev
//
//  Created by Stephen Tallent on 6/22/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import "MFlowSessionEvent.h"

@implementation MFlowSessionEvent

@dynamic EventID;
@dynamic SessionStartTime;
@dynamic SessionEndTime;
@dynamic SessionPausedSeconds;


+(NSNumber *)EventTypeID{
	return [NSNumber numberWithInt:8];
}

+(NSString *)className{
	return @"MFlowSessionEvent";
}


-(NSString *)asXML{
	static NSString *format = @"<Evt>"
	"<EID>%@</EID>"//  <-- GUID, up to 40 characters (hyphens are not counted in total) -->
	"<ST>%@</ST>"  //  <!--client starting timestamp, use MM/dd/yyyy HH:mm:ss format -->
	"<ET>%@</ET>"  //  <!-- client ending timestamp, use MM/dd/yyyy HH:mm:ss format -->
	"<Offset>%i</Offset>"
	"</Evt>";
	
	return [NSString stringWithFormat:format,
			[self EventID],
			[kEventDateFormatter stringFromDate:[self SessionStartTime]],
			[kEventDateFormatter stringFromDate:[self SessionEndTime]],
			[MFlowEventManager sharedManager].GMTOffsetInMinutes ];
	
}

@end
