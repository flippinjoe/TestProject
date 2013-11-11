//
//  MFlowEventContext.m
//  MercuryEvents
//
//  Created by Tyson Tune on 12/21/11.
//  Copyright (c) 2011 Mercury Intermedia. All rights reserved.
//

#import "MFlowEventContext.h"
#import "MFlowLaunchEvent.h"
#import "MFlowSessionEvent.h"
#import "MFlowAggEvent.h"
#import <CoreData/CoreData.h>
#import "NSManagedObjectContext+TC_NSManagedObjectContextExtensions.h"
#import "TC_NSDateExtensions.h"

static NSPersistentStoreCoordinator *defaultPersistentStoreCoordinator_ = nil;
static NSManagedObjectModel *defaultManagedObjectModel_ = nil;

dispatch_queue_t mflow_event_background_save_queue(void);
void cleanup_mflow_event_background_save_queue(void);

static dispatch_queue_t mfe_background_save_queue;

dispatch_queue_t mflow_event_background_save_queue() {
    if (mfe_background_save_queue == NULL) {
        mfe_background_save_queue = dispatch_queue_create("com.mercury.mflowevents.backgroundsaves", 0);
    }
    return mfe_background_save_queue;
}

void cleanup_mflow_event_background_save_queue() {
	if (mfe_background_save_queue != NULL) {
        mfe_background_save_queue = NULL;
	}
}


@interface MFlowEventContext ()
- (NSPersistentStoreCoordinator *)defaultPersistentStoreCoordinator;
- (NSManagedObjectModel *)defaultManagedObjectModel;
- (NSString *)eventDocumentStorageDirectory;
- (void)handleContextDidSaveNotification:(NSNotification *)mergeNotification;
- (void)mergeContextWitNotification:(NSNotification *)mergeNotification;
+ (NSString *)generateEventID;
- (void)observeContext:(NSManagedObjectContext *)context;
@end

@implementation MFlowEventContext

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
//@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


#pragma mark - Shared Instance

SHARED_INSTANCE(MFlowEventContext);


#pragma mark - Initializer

- (id)init {
    self = [super init];
    if(nil != self) {
        
    }
    return self;
}


#pragma mark - Memory Mangement

- (void)dealloc {
    cleanup_mflow_event_background_save_queue();
}


#pragma mark - Inserts

+ (void)incrementLaunchEvents:(NSURL *)oldLaunchObjectURI completion:(MFlowUpdatedManagedObjectBlock)callback {
    NSString *newLaunchEventID = [MFlowEventContext generateEventID];
    MFlowUpdatedManagedObjectBlock callbackBlock = [callback copy];
    [self saveDataInBackgroundWithBlock:^(NSManagedObjectContext *localConext) {
        
        if(oldLaunchObjectURI != nil) {
            NSManagedObjectID *oldLaunchID = [localConext.persistentStoreCoordinator managedObjectIDForURIRepresentation:oldLaunchObjectURI];
            if(oldLaunchID != nil) {
                MFlowLaunchEvent *oldLaunch = (MFlowLaunchEvent *)[localConext existingObjectWithID:oldLaunchID error:NULL];
                if(oldLaunch != nil) {
                    [oldLaunch setLaunchEndTime:[NSDate gregorianDate]];
//                    NSLog(@"EVENTS: updating previous launch to set end date: %@",oldLaunch.LaunchEndTime);
                }
            }
        }
        
        MFlowLaunchEvent *launch = [NSEntityDescription insertNewObjectForEntityForName:[MFlowLaunchEvent className] inManagedObjectContext:localConext];
        [launch setEventID:newLaunchEventID];
        [launch setLaunchStartTime:[NSDate gregorianDate]];
        // setting launch end time here because it is required in the model. Setting it to the distant future.
        [launch setLaunchEndTime:[NSDate distantFuture]];
//        NSLog(@"EVENTS: new launch event at date: %@",launch.LaunchStartTime);
    }
    completionHandler:^(BOOL success, NSNotification *saveNotification, NSError *saveError) {
        NSManagedObject *inserted = [[[saveNotification userInfo] objectForKey:NSInsertedObjectsKey] anyObject];
        if(callbackBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callbackBlock([[inserted objectID] URIRepresentation],saveError);
            });
        }
    }];
}

+ (void)updateSessionEventWithURI:(NSURL *)oldSessionObjectURI lastPauseTime:(NSDate *)pauseTime completion:(MFlowUpdatedManagedObjectBlock)callback 
{
    MFlowUpdatedManagedObjectBlock callbackBlock = [callback copy];
    [self saveDataInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
        if(nil != oldSessionObjectURI) {
            NSManagedObjectID *sessionObjectID = [localContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:oldSessionObjectURI];
            if(nil != sessionObjectID) {
                MFlowSessionEvent *session = (MFlowSessionEvent *)[localContext existingObjectWithID:sessionObjectID error:NULL];
                if(session != nil) {
                    NSTimeInterval elapsedSeconds = [[NSDate gregorianDate] timeIntervalSinceDate:pauseTime];
                    NSTimeInterval pausedBefore = [session.SessionPausedSeconds doubleValue];
                    NSTimeInterval totalPauseTime = (pausedBefore + elapsedSeconds);
                    [session setSessionPausedSeconds:[NSNumber numberWithDouble:totalPauseTime]];
                }
            }
        }
    } 
    completionHandler:^(BOOL success, NSNotification *saveNotification, NSError *saveError) {
        NSManagedObject *updated = [[[saveNotification userInfo] objectForKey:NSUpdatedObjectsKey] anyObject];
        if(callbackBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callbackBlock([[updated objectID] URIRepresentation],saveError);
            });
        }                
    }];

}

+ (void)incrementSessionEvents:(NSURL *)oldSessionObjectURI lastPauseTime:(NSDate *)pauseTime completion:(MFlowUpdatedManagedObjectBlock)callback 
{
    MFlowUpdatedManagedObjectBlock callbackBlock = [callback copy];
    [self saveDataInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
        // first see if we can update the old one
        if(nil != oldSessionObjectURI) {
            NSManagedObjectID *sessionObjectID = [localContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:oldSessionObjectURI];
            if (sessionObjectID != nil) {
                MFlowSessionEvent *session = (MFlowSessionEvent *)[localContext existingObjectWithID:sessionObjectID error:NULL];
                if(session != nil) {
                    NSTimeInterval elapsedSeconds = [[NSDate gregorianDate] timeIntervalSinceDate:pauseTime];
                    NSTimeInterval pausedBefore = [session.SessionPausedSeconds doubleValue];
                    NSTimeInterval totalPauseTime = (pausedBefore + elapsedSeconds);
                    [session setSessionPausedSeconds:[NSNumber numberWithDouble:totalPauseTime]];
                    NSDate *endDate = (totalPauseTime > 0) ? [NSDate gregorianDateWithTimeIntervalSinceNow:-totalPauseTime] : [NSDate gregorianDate];
                    [session setSessionEndTime:endDate];
                    //                NSLog(@"EVENTS: Current session expired, session started: %@ session end time: %@ total pause time %@ seconds",session.SessionStartTime,endDate,session.SessionPausedSeconds);
                }
            } else {
                NSLog(@"sessionObjectID was nil... aborting");
            }
        }
        MFlowSessionEvent *newSession = [NSEntityDescription insertNewObjectForEntityForName:[MFlowSessionEvent className] inManagedObjectContext:localContext];
        [newSession setSessionStartTime:[NSDate gregorianDate]];
        [newSession setEventID:[MFlowEventContext generateEventID]];
        // setting end time here because it is required in the model. Setting it to the distant future.
        [newSession setSessionEndTime:[NSDate distantFuture]];
//        NSLog(@"EVENTS: New SESSION, session started: %@ session end time: %@",newSession.SessionStartTime,newSession.SessionEndTime);
    }
    completionHandler:^(BOOL success, NSNotification *saveNotification, NSError *saveError) {
        NSManagedObject *inserted = [[[saveNotification userInfo] objectForKey:NSInsertedObjectsKey] anyObject];
        if(callbackBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callbackBlock([[inserted objectID] URIRepresentation],saveError);
            });
        }
    }];
    
}

// NOTE: should probably change to an NSTimeInterval if we can
+ (void)incrementAggEvent:(NSURL *)eventURI withDuration:(NSInteger)duration completion:(MFlowUpdatedManagedObjectBlock)handler
{
    NSURL *updateURI = eventURI;
    MFlowUpdatedManagedObjectBlock successBlock = [handler copy];
    [MFlowEventContext saveDataInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
        if(nil != updateURI) {
            NSManagedObjectID *objectID = [localContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:updateURI]; 
            if(nil != objectID) {
                MFlowAggEvent *event = (MFlowAggEvent *)[localContext existingObjectWithID:objectID error:NULL];
                if(nil != event) {
                    NSUInteger eventCount = [event.EventCount intValue];
                    event.EventCount = [NSNumber numberWithInt:eventCount + 1];
                    NSUInteger oldDuration = [event.EventDuration intValue];
                    event.EventDuration = [NSNumber numberWithInt:oldDuration + duration];
                }
            }
        }
    }
    completionHandler:^(BOOL success, NSNotification *didSaveNotification, NSError *saveError) {
        if(successBlock) {
            MFlowAggEvent *updatedEvent = [[[didSaveNotification userInfo] objectForKey:NSUpdatedObjectsKey] anyObject];
            NSURL *objectURI = [[updatedEvent objectID] URIRepresentation];
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(objectURI, saveError);
            });
        }

    }];
}

+ (void)aggEventWithType:(NSInteger)eventTypeID aggType:(MFlowEventAggregationType)aggMode duration:(NSInteger)duration itemid:(NSNumber *)iid parentid:(NSNumber *)pid date:(NSDate *)evtDate data:(NSString *)data completion:(MFlowUpdatedManagedObjectBlock)handler {
    MFlowUpdatedManagedObjectBlock successBlock = [handler copy];
    [MFlowEventContext saveDataInBackgroundWithBlock:^(NSManagedObjectContext *localContext) { 
        
        NSNumber *itemid = (iid == nil) ? [NSNumber numberWithInteger:0] : iid;
		NSNumber *parentid = (pid == nil) ? [NSNumber numberWithInteger:0] : pid;
        
        MFlowAggEvent *agg = [NSEntityDescription insertNewObjectForEntityForName:[MFlowAggEvent className] inManagedObjectContext:localContext];
        [agg setEventID:[self generateEventID]];
        [agg setEventType:[NSNumber numberWithInt:eventTypeID]];
        [agg setAggType:[NSNumber numberWithInt:aggMode]];
        [agg setEventDuration:[NSNumber numberWithInt:duration]];
        [agg setEventIsActive:[NSNumber numberWithBool:true]];
        [agg setEventData:data];
        [agg setEventItemID:itemid];
        [agg setEventTimeStamp:evtDate];
        [agg setEventCount:[NSNumber numberWithInt:1]];
        [agg setEventParentID:parentid];
        
    }
    completionHandler:^(BOOL success, NSNotification *didSaveNotification, NSError *saveError) {
        if(successBlock) {
            MFlowAggEvent *insertedEvent = [[[didSaveNotification userInfo] objectForKey:NSInsertedObjectsKey] anyObject];
            NSURL *objectURI = [[insertedEvent objectID] URIRepresentation];
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(objectURI, saveError);
            });
        }
        
    }];
}

+ (void)nonAggEventWithType:(NSInteger)eventTypeID duration:(NSInteger)duration itemid:(NSNumber *)iid parentid:(NSNumber *)pid data:(NSString *)data completion:(MFlowUpdatedManagedObjectBlock)handler {
    
    MFlowUpdatedManagedObjectBlock successBlock = [handler copy];
    
    NSNumber *itemid = (iid == nil) ? [NSNumber numberWithInteger:0] : iid;
	NSNumber *parentid = (pid == nil) ? [NSNumber numberWithInteger:0] : pid;
    
    [MFlowEventContext saveDataInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
        MFlowAggEvent *agg = [NSEntityDescription insertNewObjectForEntityForName:[MFlowAggEvent className] inManagedObjectContext:localContext];
        [agg setEventID:[self generateEventID]];
		[agg setEventType:[NSNumber numberWithInt:eventTypeID]];
		[agg setAggType:[NSNumber numberWithInt:MFlowEventAggregationTypeNonAggregated]];
		[agg setEventDuration:[NSNumber numberWithInt:duration]];
		[agg setEventIsActive:[NSNumber numberWithBool:true]];
		[agg setEventData:data];
		[agg setEventItemID:itemid];
		[agg setEventTimeStamp:[NSDate gregorianDate]];
		[agg setEventCount:[NSNumber numberWithInt:1]];
		[agg setEventParentID:parentid];
    }
    completionHandler:^(BOOL success, NSNotification *didSaveNotification, NSError *saveError) {
        if(successBlock) {
            MFlowAggEvent *insertedEvent = [[[didSaveNotification userInfo] objectForKey:NSInsertedObjectsKey] anyObject];
            NSURL *objectURI = [[insertedEvent objectID] URIRepresentation];
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(objectURI, saveError);
            });
        }
       
    }];
}


#pragma mark - Read fetches

- (NSArray *)performFetchRequest:(NSFetchRequest *)request error:(NSError **)fetchError {
    NSError *internalFetchError = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:request error:&internalFetchError];
    if(nil == fetchedObjects) {
        if(*fetchError != NULL) { // if NULL is passed in as the fetchError pointer we shuldn't dereference it
            *fetchError = internalFetchError;
//            NSLog(@"Fetch request %@ error %@",request,internalFetchError);
        }
        return nil;
    }
    return fetchedObjects;
}

- (NSArray *)fetchExpiredLaunchEventsWithDate:(NSDate *)date error:(NSError **)fetchError {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[MFlowLaunchEvent className] inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	[request setPredicate:[NSPredicate predicateWithFormat:@"LaunchEndTime < %@",date]];
    return [self performFetchRequest:request error:fetchError];
}

- (NSArray *)fetchExpiredSessionEventsWithDate:(NSDate *)date error:(NSError **)fetchError {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[MFlowSessionEvent className] inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	[request setPredicate:[NSPredicate predicateWithFormat:@"SessionEndTime < %@",date]];
    
//    NSLog(@"Events: Fetch %@", request);
    NSArray *sessions = [self performFetchRequest:request error:fetchError];
//    NSLog(@"fetched sessions: %@",sessions);
    
	return sessions;
}

- (NSArray *)fetchExpiredNonAggEventsWithDate:(NSDate *)date error:(NSError **)fetchError {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[MFlowAggEvent className] inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
    NSPredicate *aggTypePredicate = [NSPredicate predicateWithFormat:@"AggType == %@",[NSNumber numberWithInt:MFlowEventAggregationTypeNonAggregated]];
    NSPredicate *timeStampPredicate = [NSPredicate predicateWithFormat:@"EventTimeStamp < %@",date];
    NSArray *predicateArray = [NSArray arrayWithObjects:aggTypePredicate,timeStampPredicate,nil];
	NSPredicate *pred = [NSCompoundPredicate andPredicateWithSubpredicates:predicateArray];
    [request setPredicate:pred];
    return [self performFetchRequest:request error:fetchError];
}

- (NSArray *)fetchExpiredLaunchEvents:(NSError **)fetchError {
    return [self fetchExpiredLaunchEventsWithDate:[NSDate gregorianDate] error:fetchError];
}

- (NSArray *)fetchExpiredSessionEvents:(NSError **)fetchError {
    return [self fetchExpiredSessionEventsWithDate:[NSDate gregorianDate] error:fetchError];
}

- (NSArray *)fetchExpiredNonAggEvents:(NSError **)fetchError {
    return [self fetchExpiredNonAggEventsWithDate:[NSDate gregorianDate] error:fetchError];
}

- (NSArray *)fetchExpiredAggEvents:(NSError **)fetchError {
    // we only get agg events that closed the previous day to make sure we don't cut off any hourly or daily agg events happening now.
    NSDate *closeDate = [[NSDate gregorianDate] dateRoundedDownToDay];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[MFlowAggEvent className] inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
    NSPredicate *aggTypePredicate = [NSPredicate predicateWithFormat:@"AggType == %@",[NSNumber numberWithInt:MFlowEventAggregationTypeAggregated]];
    NSPredicate *timeStampPredicate = [NSPredicate predicateWithFormat:@"EventTimeStamp < %@",closeDate];
    NSArray *predicateArray = [NSArray arrayWithObjects:aggTypePredicate,timeStampPredicate,nil];
	NSPredicate *pred = [NSCompoundPredicate andPredicateWithSubpredicates:predicateArray];
    [request setPredicate:pred];
    return [self performFetchRequest:request error:fetchError];
}

- (NSArray *)fetchExpiredSamlpeAggEvents:(NSError **)fetchError {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[MFlowAggEvent className] inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	NSDate *closeDate = [[NSDate gregorianDate] dateRoundedDownToHour];
    NSPredicate *aggTypePredicate = [NSPredicate predicateWithFormat:@"AggType == %@",[NSNumber numberWithInt:MFlowEventAggregationTypeSample]];
    NSPredicate *timeStampPredicate = [NSPredicate predicateWithFormat:@"EventTimeStamp < %@",closeDate];
    NSArray *predicateArray = [NSArray arrayWithObjects:aggTypePredicate,timeStampPredicate,nil];
	NSPredicate *pred = [NSCompoundPredicate andPredicateWithSubpredicates:predicateArray];
	[request setPredicate:pred];
    return [self performFetchRequest:request error:fetchError];
}

- (NSArray *)fetchActiveAggEventsWithType:(MFlowEventAggregationType)aggType fetchError:(NSError **)fetchError {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[MFlowAggEvent className] inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	
	NSDate *sweetDate = (aggType == MFlowEventAggregationTypeSample) ? [[NSDate gregorianDate] dateRoundedDownToHour] : [[NSDate gregorianDate] dateRoundedDownToDay];
	NSPredicate *timeStampPred = [NSPredicate predicateWithFormat:@"EventTimeStamp == %@",sweetDate];
    NSPredicate *aggTypePred = [NSPredicate predicateWithFormat:@"AggType == %@",[NSNumber numberWithInt:aggType]];
    NSArray *predicates = [NSArray arrayWithObjects:timeStampPred,aggTypePred,nil];
	NSPredicate *pred = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
	[request setPredicate:pred];
    return [self performFetchRequest:request error:fetchError];
}


#pragma mark - Event ID Generation

// !!!: Should this be outside the context, seems like a manager duty
+ (NSString *)generateEventID {
	CFUUIDRef r = CFUUIDCreate(NULL);
	NSString *guid = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL,r));
	CFRelease(r);	
	return guid;
}


#pragma mark - Catch NSNotifications

- (void)handleContextDidSaveNotification:(NSNotification *)mergeNotification {
    NSManagedObjectContext *savingContext = [mergeNotification object];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self mergeContextWitNotification:mergeNotification];
        if(savingContext.saveBlock) {
            savingContext.saveBlock(YES,mergeNotification,nil);
            savingContext.saveBlock = nil;
        }
    });
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:[mergeNotification object]];
}


#pragma mark - Merging

- (void)mergeContextWitNotification:(NSNotification *)mergeNotification {
    [self.managedObjectContext mergeChangesFromContextDidSaveNotification:mergeNotification];
}


#pragma mark - Observing

- (void)observeContext:(NSManagedObjectContext *)context {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:context];
}


#pragma mark - Saving

+ (void)saveDataInBackgroundWithBlock:(MFlowEventSaveDataBlock)saveBlock {
    [self saveDataInBackgroundWithBlock:saveBlock completionHandler:nil];
}

+ (void)saveDataInBackgroundWithBlock:(MFlowEventSaveDataBlock)saveBlock completionHandler:(MFlowEventChangeCompleteBlock)callback {
    if(defaultPersistentStoreCoordinator_ == nil)
    {
        // bail if no store coordinator
        return;
    }
    MFlowEventChangeCompleteBlock callbackBlock = [callback copy];

    dispatch_async(mflow_event_background_save_queue(), ^{
        MFlowEventContext		*eventContext = [[MFlowEventContext alloc] init];
        NSManagedObjectContext	*localContext = [eventContext managedObjectContext];
		
        localContext.saveBlock = callback;
        // set the main context to observe the local context saves
        [[MFlowEventContext sharedMFlowEventContext] observeContext:localContext];
        if(saveBlock) {
            saveBlock(localContext);
        }
        if([localContext hasChanges]) {
            NSError *saveError = nil;
            BOOL saved = [localContext save:&saveError];
            // if we didn't save send the error
            if(!saved && callbackBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    callbackBlock(saved, nil, saveError);
                });
            }
        }
		
    });
    
}


#pragma mark - Core Data Stack

- (NSManagedObjectModel *)defaultManagedObjectModel {
    if(defaultManagedObjectModel_ == nil) {
        NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"MFlowEventData" ofType:@"mom"];
        defaultManagedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]];
    }
    return defaultManagedObjectModel_;
}

- (NSPersistentStoreCoordinator *)defaultPersistentStoreCoordinator {
    if (defaultPersistentStoreCoordinator_ == nil) {
        NSURL *storeUrl = [NSURL fileURLWithPath: [[self eventDocumentStorageDirectory] stringByAppendingPathComponent: @"MFlowEventData.sqlite"]];
        NSError *createStoreError = nil;
        defaultPersistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        if(![defaultPersistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&createStoreError]) {
//            NSLog(@"Error creating default persistent store %@",createStoreError);
            
            if([createStoreError code] == 134100)
            {
                // there's something funky with the model, try deleting and opening again
                NSFileManager *fm = [NSFileManager defaultManager];
                
                NSError *removeError = nil;
                BOOL removed = [fm removeItemAtURL:storeUrl error:&removeError];
                if(removed)
                {
                    NSPersistentStore *store = [defaultPersistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&createStoreError];
                    
                    if(!store)
                    {
                        // we've got problems, bail
                        defaultPersistentStoreCoordinator_ = nil;
                    }
                }
                
                
            }
            
        }
    }
	return defaultPersistentStoreCoordinator_;
}

- (NSManagedObjectContext *)managedObjectContext {
	
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
	
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
	_managedObjectModel = [self defaultManagedObjectModel];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    return [self defaultPersistentStoreCoordinator];
}

- (void)setDefaultPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator {
//    if(![defaultPersistentStoreCoordinator_ isEqual:coordinator]) {
        defaultPersistentStoreCoordinator_ = coordinator;
//    }
}

- (void)setDefaultManagedObjectModel:(NSManagedObjectModel *)model {
    defaultManagedObjectModel_ = model;
}


#pragma mark - Storage Directory

- (NSString *)eventDocumentStorageDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

@end
