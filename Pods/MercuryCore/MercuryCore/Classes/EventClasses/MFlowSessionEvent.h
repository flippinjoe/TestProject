//
//  MFlowSessionEvent.h
//  MFlowEventManagerDev
//
//  Created by Stephen Tallent on 6/22/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "MFlowEventManager.h"

@interface MFlowSessionEvent :  NSManagedObject <MFlowEvent>
{
}


@property (nonatomic, strong) NSString * EventID;
@property (nonatomic, strong) NSDate * SessionStartTime;
@property (nonatomic, strong) NSDate * SessionEndTime;
@property (nonatomic, strong) NSNumber * SessionPausedSeconds;

+(NSNumber *)EventTypeID;
+(NSString *)className;

-(NSString *)asXML;

@end



