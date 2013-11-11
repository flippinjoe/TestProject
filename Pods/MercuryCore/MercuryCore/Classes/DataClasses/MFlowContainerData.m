//
//  MFlowContainerData.m
//  MercuryCoreDev
//
//  Created by Stephen Tallent on 5/11/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import "MFlowContainerData.h"

@implementation MFlowContainerData

@synthesize ttlSeconds;
@synthesize containerVersion;
@synthesize dataRetrievalDate;
@synthesize relationNodes;
@synthesize linkedAttNameIDs;
@synthesize publishedItemIDs;
@synthesize masterItems;

- (id)init{
	
	if (self = [super init]) {
		
		ttlSeconds = [NSNumber numberWithInt:0];
		containerVersion = [NSNumber numberWithInt:0];

	}
	
	return self;
	
}

- (id)initWithCoder:(NSCoder *)decoder{
	
	self.ttlSeconds =			[decoder decodeObjectForKey:@"ttlSeconds"];
	self.containerVersion =		[decoder decodeObjectForKey:@"containerVersion"];
	self.dataRetrievalDate =	[decoder decodeObjectForKey:@"dataRetrievalDate"];
	self.relationNodes =		[decoder decodeObjectForKey:@"relationNodes"];
	self.linkedAttNameIDs =		[decoder decodeObjectForKey:@"linkedAttNameIDs"];
	self.publishedItemIDs =		[decoder decodeObjectForKey:@"publishedItemIDs"];
	self.masterItems =			[decoder decodeObjectForKey:@"masterItems"];
	
	//NSObject *o = [self.masterItems objectForKey:[[self.masterItems allKeys] objectAtIndex:0]]; 
	
	return self;
}

-(bool)dataStale{
	
	if (dataRetrievalDate == nil){
		return true;
	} else {
		if ( [dataRetrievalDate timeIntervalSinceNow] >= -[ttlSeconds doubleValue] ){
			return false;
		} else {
			return true;
		}
	}
	
}

- (void)encodeWithCoder:(NSCoder *)encoder{
	[encoder encodeObject:ttlSeconds forKey:@"ttlSeconds"];
	[encoder encodeObject:containerVersion forKey:@"containerVersion"];
	[encoder encodeObject:dataRetrievalDate forKey:@"dataRetrievalDate"];
	[encoder encodeObject:relationNodes forKey:@"relationNodes"];
	[encoder encodeObject:linkedAttNameIDs forKey:@"linkedAttNameIDs"];
	[encoder encodeObject:publishedItemIDs forKey:@"publishedItemIDs"];
	[encoder encodeObject:masterItems forKey:@"masterItems"];
}


@end
