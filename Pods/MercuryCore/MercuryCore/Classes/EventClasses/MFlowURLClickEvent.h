//
//  MFlowURLClickEvent.h
//  MFlowEventManagerDev
//
//  Created by Stephen Tallent on 6/22/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "MFlowEventManager.h"

@interface MFlowURLClickEvent :  NSManagedObject <MFlowEvent> 
{
}


@property (nonatomic, strong) NSDate * EventTimestamp;
@property (nonatomic, strong) NSString * EventID;
@property (nonatomic, strong) NSString * URL;
@property (nonatomic, strong) NSNumber * ItemID;

+(NSString *)className;
+(NSNumber *)EventTypeID;

-(NSString *) asXML;

@end



