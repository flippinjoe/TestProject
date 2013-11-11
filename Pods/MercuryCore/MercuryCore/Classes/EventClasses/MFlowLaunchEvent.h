//
//  MFlowLaunchEvent.h
//  MFlowEventManagerDev
//
//  Created by Stephen Tallent on 6/22/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "MFlowEventManager.h"

@interface MFlowLaunchEvent :  NSManagedObject <MFlowEvent> 
{
}

@property (nonatomic, strong) NSString * EventID;
@property (nonatomic, strong) NSDate * LaunchStartTime;
@property (nonatomic, strong) NSDate * LaunchEndTime;


+(NSNumber *)EventTypeID;
+(NSString *)className;

-(NSString *)asXML;

@end



