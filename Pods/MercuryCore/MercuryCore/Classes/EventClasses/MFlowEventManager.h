//
//  MFlowEventManager.h
//  MFlowEventManagerDev
//
//  Created by Stephen Tallent on 6/22/09.
//  Updated by Tyson Tune on 12/27/11
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

/**
 Removed closeSessionAndUploadEvents to support new sessions model.
 */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef void(^MFlowEventUploadCompleteHandler)(NSData *responseData, NSError *uploadError);
typedef void(^MFlowEventCompleteHandler)(NSURL *objectURI, NSError *insertError);

typedef enum {
    MFlowEventAggregationTypeAggregated = 6,	
    MFlowEventAggregationTypeSample = 7,		
    MFlowEventAggregationTypeNonAggregated = 9,
} MFlowEventAggregationType;     

extern NSString * const MFlowEventManagerDidBeginNewSessionNotification;
extern NSString * const MFlowLaunchEventObjectURLKey;
extern NSString * const MFlowSessionEventObjectURLKey;
extern NSString * const MFlowSessionLastPausedKey;

extern NSDateFormatter*  kEventDateFormatter;

@protocol MFlowEvent
-(NSString *) asXML;
@end


@interface MFlowEventManager : NSObject  {
    UIBackgroundTaskIdentifier bgTask;
	NSDate *pauseStartTime;
}

@property (nonatomic, strong) NSDateFormatter *aggKeyDateFormatter;
@property (nonatomic, copy) MFlowEventUploadCompleteHandler uploadCompleteHandler;
@property (nonatomic, assign) NSTimeInterval sessionTimeoutSeconds;
@property (nonatomic, assign) BOOL eventManagerStarted;
@property (nonatomic, assign) MFlowEventAggregationType aggMode;
@property (nonatomic, assign) NSInteger GMTOffsetInMinutes;
@property (nonatomic, strong) NSURL *currentSesssionObjectIDURL;
@property (nonatomic, strong) NSURL *currentLaunchObjectIDURL;
@property (nonatomic, strong) NSMutableDictionary *aggEventURICache;
@property (nonatomic, assign) BOOL useEcho;


/**
 GCD Method Sudo-Singleton.
 */
+ (MFlowEventManager *)sharedMFlowEventManager;

/**
 Kept around for backwards compatibility.  Just calls the sharedMFlowEventManager.
 */
+ (MFlowEventManager *) sharedManager;

/**
 Cancels the upload url connection if it is running.
 */
- (void)cancelUploadProcess;

/**
 Starts the upload manager by intitializing some needed variables.
 */
- (void)startEventManager;

/**
 Inserts a launch event and starts the event manager.  This should be the first call to the event manager in the app delegate.
 */
- (void)doLaunchEvent;

/**
 Inserts a launch event and starts the event manager.  Calls a completion handler when done.
 */
- (void)doLaunchEvent:(MFlowEventCompleteHandler)handler;

/**
 Sets a threshold number of events.  After the threshold is reached the events will be uploaded.
*/
- (void)uploadEventsAfterThreshold:(NSUInteger)threshold;

/**
 Sends all appropriate events upstream to the server and executes the handler once the upload is complete.
 */
- (void)uploadEventsWithHandler:(MFlowEventUploadCompleteHandler)handler;

/**
 Sends all appropriate events before date upstream to the server and executes the handler once the upload is complete.
 */
- (void)uploadEventsWithDate:(NSDate *)date handler:(MFlowEventUploadCompleteHandler)handler;

/**
 Creates and inserts a new non-aggregated event.
 @param eventTypeID the type ID for the event.
 @param duration the duration of the event as an NSInteger
 @param itemid the MFlow ItemID for the event.
 @param parentid the MFlow ItemID of the parent for the event.
 @param data the string to pass additional event data for the event.
 */
- (void)trackEventWithType:(NSInteger)eventTypeID duration:(NSInteger)duration itemid:(NSNumber *)itemid parentid:(NSNumber *)parentid data:(NSString *)data;

/**
 Creates and inserts a new aggregated event if not aggregated event exists for the params, if an aggregated event already exists this method increments the EventCount and adds to the duration.
 @param eventTypeID the type ID for the event.
 @param duration the duration of the event as an NSInteger
 @param itemid the MFlow ItemID for the event.
 @param parentid the MFlow ItemID of the parent for the event.
 @param data the string to pass additional event data for the event.
 */
- (void)trackEventAggregatedWithType:(NSInteger)eventTypeID duration:(NSInteger)duration itemid:(NSNumber *)itemid parentid:(NSNumber *)parentid data:(NSString *)data;


@end
