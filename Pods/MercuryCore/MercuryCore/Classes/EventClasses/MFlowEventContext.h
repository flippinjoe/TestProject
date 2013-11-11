//
//  MFlowEventContext.h
//  MercuryEvents
//
//  Created by Tyson Tune on 12/21/11.
//  Copyright (c) 2011 Mercury Intermedia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFlowHelperMacros.h"
#import "MFlow.h"


typedef void(^MFlowEventSaveDataBlock)(NSManagedObjectContext *localContext);
typedef void(^MFlowEventChangeCompleteBlock)(BOOL success, NSNotification *didSaveNotification, NSError *error);
typedef void(^MFlowUpdatedManagedObjectBlock)(NSURL *managedObjectURI, NSError *error);

@interface MFlowEventContext : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (weak, nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (MFlowEventContext *)sharedMFlowEventContext;

/**
 Perform a save operation on the background queue.
 */
+ (void)saveDataInBackgroundWithBlock:(MFlowEventSaveDataBlock)saveBlock;

/**
 Perform a save operation on the background queue with a completion handler.
 */
+ (void)saveDataInBackgroundWithBlock:(MFlowEventSaveDataBlock)saveBlock completionHandler:(MFlowEventChangeCompleteBlock)callback;

/**
 Insert a new launch event.  Close the object with the previous launch event if we pass an objectID for it.
 */
+ (void)incrementLaunchEvents:(NSURL *)oldLaunchObjectURI completion:(MFlowUpdatedManagedObjectBlock)callback;

/**
 Update a session event specified by the passed URI.
 */
+ (void)updateSessionEventWithURI:(NSURL *)oldSessionObjectURI lastPauseTime:(NSDate *)pauseTime completion:(MFlowUpdatedManagedObjectBlock)callback;

/**
 Insert a new Session event and close the old one if we pass a URI.
 */
+ (void)incrementSessionEvents:(NSURL *)oldSessionObjectURI lastPauseTime:(NSDate *)pauseTime completion:(MFlowUpdatedManagedObjectBlock)callback;

/**
 Get all LaunchEvents that have LaunchEndDate set before the specified date.
 */
- (NSArray *)fetchExpiredLaunchEventsWithDate:(NSDate *)date error:(NSError **)fetchError;

/**
 Get all LaunchEvents that have LaunchEndDate set before the current date.
 */
- (NSArray *)fetchExpiredLaunchEvents:(NSError **)fetchError;

/**
 Get all LaunchEvents that have LaunchEndDate set before the passed date.
 */
- (NSArray *)fetchExpiredSessionEventsWithDate:(NSDate *)date error:(NSError **)fetchError;

/**
 Get all SessionEvents that have a SessionEndDate set before the current date.
 */
- (NSArray *)fetchExpiredSessionEvents:(NSError **)fetchError;

/**
 Get all NonAggregatedEvents that have an EventTimeStamp set before the passed date.
 */
- (NSArray *)fetchExpiredNonAggEventsWithDate:(NSDate *)date error:(NSError **)fetchError;

/**
 Get all NonAggregatedEvents that have an EventTimeStamp set before the current date.
 */
- (NSArray *)fetchExpiredNonAggEvents:(NSError **)fetchError;

/**
 Get all AggregatedEvents that have an EventTimeStamp set before the current date.
 */
- (NSArray *)fetchExpiredAggEvents:(NSError **)fetchError;

/**
 Get all SampleAggregatedEvents that have an EventTimeStamp set before the current date.
 */
- (NSArray *)fetchExpiredSamlpeAggEvents:(NSError **)fetchError;

/**
 Get all active agg events where the EventTimeStamp is equal to the passed aggType timestamp.
 */
- (NSArray *)fetchActiveAggEventsWithType:(MFlowEventAggregationType)aggType fetchError:(NSError **)fetchError;

/**
 Runs a fetch request.
 */
- (NSArray *)performFetchRequest:(NSFetchRequest *)request error:(NSError **)fetchError;

/**
 Set the default persistent store coordinator.
 */
- (void)setDefaultPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator;

/**
 Set the default managed object model.
 */
- (void)setDefaultManagedObjectModel:(NSManagedObjectModel *)model;

/**
 Increments the count for the Agg event with the supplied URI and adds to the duration time.
 */
+ (void)incrementAggEvent:(NSURL *)eventURI withDuration:(NSInteger)duration completion:(MFlowUpdatedManagedObjectBlock)handler;

/**
 Creates a new agg event with the passed properties.
 */
+ (void)aggEventWithType:(NSInteger)eventTypeID aggType:(MFlowEventAggregationType)aggMode duration:(NSInteger)duration itemid:(NSNumber *)iid parentid:(NSNumber *)pid date:(NSDate *)evtDate data:(NSString *)data completion:(MFlowUpdatedManagedObjectBlock)handler;

/**
 Creates a new non-aggregated event with the passed properties.
 */
+ (void)nonAggEventWithType:(NSInteger)eventTypeID duration:(NSInteger)duration itemid:(NSNumber *)iid parentid:(NSNumber *)pid data:(NSString *)data completion:(MFlowUpdatedManagedObjectBlock)handler;

@end
