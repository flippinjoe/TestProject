//
//  MFlowAggEvent.h
//  MFlowEventManagerDev
//
//  Created by Stephen Tallent on 6/22/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "MFlowEventManager.h"

@interface MFlowAggEvent :  NSManagedObject <MFlowEvent>
{
}

@property (nonatomic, strong) NSNumber * EventDuration;
@property (nonatomic, strong) NSString * EventData;
@property (nonatomic, strong) NSNumber * AggType;
@property (nonatomic, strong) NSNumber * EventIsActive;
@property (nonatomic, strong) NSDate * EventTimeStamp;
@property (nonatomic, strong) NSNumber * EventItemID;
@property (nonatomic, strong) NSNumber * EventParentID;
@property (nonatomic, strong) NSString * EventID;
@property (nonatomic, strong) NSNumber * EventCount;
@property (nonatomic, strong) NSNumber * EventType;

+(NSString *)className;

@end



