// 
//  MFlowURLClickEvent.m
//  MFlowEventManagerDev
//
//  Created by Stephen Tallent on 6/22/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import "MFlowURLClickEvent.h"

@implementation MFlowURLClickEvent 

@dynamic EventTimestamp;
@dynamic EventID;
@dynamic URL;
@dynamic ItemID;

+(NSString *)className{
	return @"MFlowURLClickEvent";
}

+(NSNumber *)EventTypeID{
	return [NSNumber numberWithInt:3];
}


-(NSString *)asXML{
	static NSString *format = @"<Event>"
			"<EventID>%@<EventID>"
			"<URL>%@</URL>"
			"<ItemID>%@</ItemID>"
			"<EventTimestamp>%@</EventTimestamp>"
			"<Offset>%i</Offset>"
			"</Event>";

	
	return [NSString stringWithFormat:format,
			[self EventID],
			[self URL],
			[self ItemID],
			[kEventDateFormatter stringFromDate:[self EventTimestamp]],
			[MFlowEventManager sharedManager].GMTOffsetInMinutes];
	
}
@end
