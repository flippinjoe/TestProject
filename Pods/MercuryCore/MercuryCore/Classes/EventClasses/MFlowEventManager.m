//
//  MFlowEventManager.m
//  MFlowEventManagerDev
//
//  Created by Stephen Tallent on 6/22/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import "MFlowAggEvent.h"
#import "TC_NSDateExtensions.h"
#import "TC_NSDataExtensions.h"
#import "base64.h"
#import "CXMLDocument.h"
#import "CXMLElement.h"
#import "MFlowHelperMacros.h"
#import "MFlowEventContext.h"
#import "MFlowLaunchEvent.h"
#import "MFlowSessionEvent.h"
#import "MFlowUserManager.h"
#import "MFlowConfig.h"


NSString * const MFlowLaunchEventObjectURLKey = @"mflowLaunchEventObjectURL";
NSString * const MFlowSessionEventObjectURLKey = @"mflowSessionEventObjectURL";
NSString * const MFlowSessionLastPausedKey = @"mflowSessionLastPaused";
NSString * const MFlowEventManagerDidBeginNewSessionNotification = @"mflowEventManagerDidBeginNewSessionNotification";

#define foo4random() (arc4random() % ((unsigned)RAND_MAX + 1))
#define SESSION_EXPIRE_TIME_INTERVAL_DEFAULT 90.0
#define EVENTS_FUNCTION_URL @"%@tallent.mflow.ws/rest/event.aspx?function=PostScreenServerEvents&userid=%i&uuid=%@&version=1&compressionMode=gzip_zlib"
#define EVENTS_ECHO_FUNCTION_URL @"%@tallent.mflow.ws/rest/event.aspx?function=EchoScreenServerEvents&userid=%i&uuid=%@&version=1&compressionMode=gzip_zlib"

NSDateFormatter *kEventDateFormatter;

@interface MFlowEventManager ()
@property (nonatomic, strong) NSURLConnection *urlConnection;
@property (nonatomic, strong) NSMutableData *connectionData;
@property (nonatomic, strong) NSMutableSet *uploadedEventObjectIDs;
@property (nonatomic, assign) NSUInteger eventThreshold;
@property (nonatomic, assign) NSUInteger eventCount;
@property (nonatomic, assign) BOOL uploadAfterThreshold;

- (void)startObservingNotifications;
- (void)stopObservingNotifications;
- (MFlowEventAggregationType)aggTypeForLaunch;
- (void)handleApplicationDidEnterBackground:(UIApplication *)application;
- (NSURLRequest *)submissionRequestWithPayload:(NSString *)payloadXML userID:(NSNumber *)uid uniqueID:(NSString *)uuid;
- (void)runCompleteHandler:(NSData *)responseData withError:(NSError *)uploadError;
- (NSString *)generateEventPayloadForType:(NSNumber *)n data:(NSArray *)d;
- (NSString *)generateEventID;
- (void) uploadEventsWithDate:(NSDate *)d;
- (NSDate *)generateAggEventDate;
- (NSString *)generateAggEventKeyWithDate:(NSDate *)d eventType:(NSNumber *)n itemID:(NSNumber *)i parentID:(NSNumber *)p;
- (void)loadCurrentAggEventsIntoCache;
- (void)handleEventContextDidChange:(NSNotification *)notification;
- (void)doSessionStart;
- (void)doSessionStart:(MFlowEventCompleteHandler)handler;
- (NSString *)deviceID;
@end

@implementation MFlowEventManager


@synthesize sessionTimeoutSeconds;

@synthesize aggKeyDateFormatter = _aggKeyDateFormatter;

@synthesize uploadCompleteHandler = _uploadCompleteHandelr;
@synthesize urlConnection = _urlConnection;
@synthesize connectionData = _connectionData;
@synthesize uploadedEventObjectIDs = _uploadedEventObjectIDs;

@synthesize aggMode = _aggMode;
@synthesize currentSesssionObjectIDURL = _currentSesssionObjectIDURL;
@synthesize currentLaunchObjectIDURL = _currentLaunchObjectIDURL;

@synthesize GMTOffsetInMinutes = _GMTOffsetInMinutes;
@synthesize aggEventURICache = _aggEventURICache;
@synthesize eventManagerStarted = _eventManagerStarted;
@synthesize useEcho = _useEcho;

@synthesize eventCount = _eventCount;
@synthesize eventThreshold = _eventThreshold;
@synthesize uploadAfterThreshold = _uploadAfterThreshold;

#pragma mark - Shared Instance

SHARED_INSTANCE(MFlowEventManager);

+ (MFlowEventManager *)sharedManager {
    return [[self class] sharedMFlowEventManager];
}


#pragma mark - Initializer

- (id)init {
	self = [super init];
    if(nil != self) {
        
        kEventDateFormatter = [[NSDateFormatter alloc] init];
        [kEventDateFormatter setDateFormat:@"MM/dd/yyyy HH:mm:ss"]; //MM/dd/yyyy HH:mm:ss
        
        self.sessionTimeoutSeconds = SESSION_EXPIRE_TIME_INTERVAL_DEFAULT;
        
        // lets go ahead and figure out our GMT Offset for later user
        NSInteger GMTOffsetInSeconds = [[NSTimeZone systemTimeZone] secondsFromGMT];
        self.GMTOffsetInMinutes = GMTOffsetInSeconds / 60;
    }
    return self;
}


#pragma mark - Set the manager to start taking events

- (void)startEventManager {
    [self startObservingNotifications];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    self.currentLaunchObjectIDURL = [ud URLForKey:MFlowLaunchEventObjectURLKey];
    self.currentSesssionObjectIDURL = [ud URLForKey:MFlowSessionEventObjectURLKey];
    
    self.aggMode = [self aggTypeForLaunch];
	self.aggKeyDateFormatter = [[NSDateFormatter alloc] init];
	[self.aggKeyDateFormatter setDateFormat:@"MM_dd_yyyy_HH"];
    
	[self loadCurrentAggEventsIntoCache];
	
	self.eventManagerStarted = YES;
	
    // we want to push up all events before the current day in case they didn't go before.
    // pf 1/5/12 Removing this as we are now checking for events in handleAppDidBecomeActive; don't want to double fire
//    NSDate *yesterday = [NSDate dateWithTimeIntervalSinceNow:-(24 * 60 * 60)];
//    [self uploadEventsWithDate:yesterday handler:^(NSData *responseData, NSError *uploadError) {
//       // TODO: handle error
//        NSLog(@"Uploaded events before %@ with error: %@",yesterday,uploadError);
//    }];
}


#pragma mark - Aggregation Type

- (MFlowEventAggregationType)aggTypeForLaunch {
    
    // Deprecating MFlowEventAggregationTypeAggregated - pf 2/8/13
    //  All aggregated events going forward will be of type MFlowEventAggregationTypeSample
    return MFlowEventAggregationTypeSample;
    
    // now lets figure out our aggregation mode
//	double totalRuns = 10000.0;
//	double percent = (totalRuns * .10);
//	int r = foo4random() % (int)totalRuns;
//	
//	return (r < percent) ? MFlowEventAggregationTypeSample : MFlowEventAggregationTypeAggregated;
}


#pragma mark - Notifications

- (void)startObservingNotifications {
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    UIApplication *app = [UIApplication sharedApplication];
	[center addObserver:self selector:@selector(handleAppDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:app];
	[center addObserver:self selector:@selector(handleAppWillResignActive:) name:UIApplicationWillResignActiveNotification object:app];
    [center addObserver:self selector:@selector(handleApplicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:app];
}

- (void)stopObservingNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    UIApplication *app = [UIApplication sharedApplication];
    [center removeObserver:self name:UIApplicationDidBecomeActiveNotification object:app];
    [center removeObserver:self name:UIApplicationWillResignActiveNotification object:app];
    [center removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:app];
    if(self.uploadAfterThreshold) {
        [center removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:[MFlowEventContext sharedMFlowEventContext].managedObjectContext];
    }
}

- (void)handleAppDidBecomeActive:(NSNotification *)note {	
    [self doSessionStart];
    [self uploadEventsWithHandler:NULL];
}

// temporary interuptions e.g. phonecall, sms
- (void)handleAppWillResignActive:(NSNotification *)note {
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate gregorianDate] forKey:MFlowSessionLastPausedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)handleAppWillTerminate:(NSNotification *)note {
	[self uploadEventsWithHandler:nil];
}

- (void)handleApplicationDidEnterBackground:(UIApplication *)application {
    
    if(bgTask != UIBackgroundTaskInvalid) return;
    
    UIApplication *app = [UIApplication sharedApplication];
    
    dispatch_block_t taskExpireHandler = ^{
        [self cancelUploadProcess];
        [app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    };
    
    bgTask = [app beginBackgroundTaskWithExpirationHandler:taskExpireHandler];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self uploadEventsWithHandler:^(NSData *responseData, NSError *uploadError) {
            [app endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
    });
    
}

- (void)handleEventContextDidChange:(NSNotification *)notification {
    NSUInteger insertCount = [[[notification userInfo] objectForKey:NSInsertedObjectsKey] count];
    NSUInteger updatedCount = [[[notification userInfo] objectForKey:NSUpdatedObjectsKey] count];
    self.eventCount += (insertCount + updatedCount);
    if(self.eventCount > self.eventThreshold) {
        self.eventCount = 0;
        [self uploadEventsWithHandler:NULL];
    }
}


#pragma mark - Uploading

- (NSString *)deviceID
{ return [[MFlowConfig sharedInstance] deviceID]; }

- (void)uploadEventsWithHandler:(MFlowEventUploadCompleteHandler)handler
{
    [self uploadEventsWithDate:[NSDate gregorianDate] handler:handler];
}

- (void)uploadEventsWithDate:(NSDate *)date handler:(MFlowEventUploadCompleteHandler)handler
{
    self.uploadCompleteHandler = handler;
    [self uploadEventsWithDate:date];
}

- (void)uploadEventsWithDate:(NSDate *)d 
{
    
    NSNumber *userID = [MFlowUserManager sharedUser].userID;
    // bail if the user hasn't registered yet
	if ([userID intValue] == 0){
        // TODO: create proper error and handle it
        
//		NSLog(@"bailing because we are unregistered");
		return;
	}
    
	NSString *uuid = [self deviceID];
	
    NSMutableString *payloadXML = [[NSMutableString alloc] initWithString:@"<root>"];
    NSMutableSet *fetchedObjectIDs = [NSMutableSet set];
    
    // ???: can we leave out a node if there are no events for it?
    // ???: should we handle errors here? If we can't read from the db it might be a big issue. On the other hand that might be the context's burden to deal with the errors.
    
    NSArray *launchEvents = [[MFlowEventContext sharedMFlowEventContext] fetchExpiredLaunchEventsWithDate:d error:NULL];
    if(nil != launchEvents) {
        NSString *launchPayload = [self generateEventPayloadForType:[MFlowLaunchEvent EventTypeID] data:launchEvents];
        [payloadXML appendString:launchPayload];
        [fetchedObjectIDs addObjectsFromArray:[launchEvents valueForKeyPath:@"objectID"]];
    }
	
    NSArray *sessionEvents = [[MFlowEventContext sharedMFlowEventContext] fetchExpiredSessionEventsWithDate:d error:NULL];
    if(nil != sessionEvents) {
        NSString *sessionPayload = [self generateEventPayloadForType:[MFlowSessionEvent EventTypeID] data:sessionEvents];
//        NSLog(@"EVENTS: Session payload: %@",sessionPayload);
        [payloadXML appendString:sessionPayload];
        [fetchedObjectIDs addObjectsFromArray:[sessionEvents valueForKeyPath:@"objectID"]];
    }
    
    // NOTE: removing urlClickEvents
    
    NSArray *nonAggEvents = [[MFlowEventContext sharedMFlowEventContext] fetchExpiredNonAggEventsWithDate:d error:NULL];
    if(nil != nonAggEvents) {
        NSString *nonAggPayload = [self generateEventPayloadForType:[NSNumber numberWithInt: MFlowEventAggregationTypeNonAggregated] data:nonAggEvents];
        [payloadXML appendString:nonAggPayload];
        [fetchedObjectIDs addObjectsFromArray:[nonAggEvents valueForKeyPath:@"objectID"]];
    }
    
    NSArray *aggEvents = [[MFlowEventContext sharedMFlowEventContext] fetchExpiredAggEvents:NULL];
    if(nil != aggEvents) {
        NSString *aggPayload = [self generateEventPayloadForType:[NSNumber numberWithInt: MFlowEventAggregationTypeAggregated] data:aggEvents];
        [payloadXML appendString:aggPayload];
        [fetchedObjectIDs addObjectsFromArray:[aggEvents valueForKeyPath:@"objectID"]];
    }								 
    
    NSArray *sampleAggEvents = [[MFlowEventContext sharedMFlowEventContext] fetchExpiredSamlpeAggEvents:NULL];
    if(nil != sampleAggEvents) {
        NSString *samplePayload = [self generateEventPayloadForType:[NSNumber numberWithInt: MFlowEventAggregationTypeSample] data:sampleAggEvents];
        [payloadXML appendString:samplePayload];
        [fetchedObjectIDs addObjectsFromArray:[sampleAggEvents valueForKeyPath:@"objectID"]];
    }
    
    [payloadXML appendString:@"</root>"];
    
    // keep track of the object IDs for later deletion
    self.uploadedEventObjectIDs = fetchedObjectIDs;
    
    // if we don't have any objectIDs there was nothing to upload, so skip it
    if(self.uploadedEventObjectIDs.count == 0) {
        NSData *message = [@"No Events To Upload" dataUsingEncoding:NSUTF8StringEncoding];
        [self runCompleteHandler:message withError:nil];
    } else {
        NSURLRequest *request = [self submissionRequestWithPayload:payloadXML userID:userID uniqueID:uuid];
        // start async connection
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    }	
}

- (void)uploadEventsAfterThreshold:(NSUInteger)threshold
{
    self.uploadAfterThreshold = YES;
    self.eventThreshold = threshold;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEventContextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:[MFlowEventContext sharedMFlowEventContext].managedObjectContext];
}


#pragma mark - Sessions and Launches

- (void)doLaunchEvent {
    [self doLaunchEvent:NULL];
}

- (void)doLaunchEvent:(MFlowEventCompleteHandler)handler {

    // Disabling Launch Events pf - 2/8/13
    //  Apps should no longer call doLaunchEvent at startup but instead should call startEventManger directly
    //  Leave startEventManager call in place here for backward compatibility
    
//    MFlowEventCompleteHandler successBlock = [handler copy];
    if(!self.eventManagerStarted) {
        [self startEventManager];
    }
    
//    [MFlowEventContext incrementLaunchEvents:self.currentLaunchObjectIDURL completion:^(NSURL *insertedObjectURI,NSError *saveError) {
//        if(nil != insertedObjectURI) {
//            [[NSUserDefaults standardUserDefaults] setURL:insertedObjectURI forKey:MFlowLaunchEventObjectURLKey];
//            self.currentLaunchObjectIDURL = insertedObjectURI;
//        }
//        if(successBlock) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                successBlock(insertedObjectURI, saveError);
//            });
//            [successBlock release];
//        }
//        
//    }];

}

- (void)doSessionStart {
    [self doSessionStart:NULL];
}

- (void)doSessionStart:(MFlowEventCompleteHandler)handler {
    
    
    MFlowEventCompleteHandler successBlock = [handler copy];
    NSDate *lastPause = [[NSUserDefaults standardUserDefaults] objectForKey:MFlowSessionLastPausedKey];
    NSTimeInterval elapsedSeconds = (lastPause == nil) ? 0.0 : [[NSDate gregorianDate] timeIntervalSinceDate:lastPause];
    
//    NSLog(@"EVENTS: New Session Required: %d",(elapsedSeconds > self.sessionTimeoutSeconds || self.currentSesssionObjectIDURL == nil));
    
    if(elapsedSeconds > self.sessionTimeoutSeconds || self.currentSesssionObjectIDURL == nil) {
        __weak MFlowEventManager *blockSelf = self;
        [MFlowEventContext incrementSessionEvents:self.currentSesssionObjectIDURL lastPauseTime:lastPause completion:^(NSURL *insertedObjectURI, NSError *saveError) {
            if(nil != saveError) {
                // TODO: Handle the error
                NSLog(@"There was some error with incrementing the session events %@",saveError);
            }
            // if we get an ID back we inserted a new event and need to track the new objct URI.
            if(insertedObjectURI != nil) {
                [[NSUserDefaults standardUserDefaults] setURL:insertedObjectURI forKey:MFlowSessionEventObjectURLKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                blockSelf.currentSesssionObjectIDURL = insertedObjectURI;
            }
            if(successBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(insertedObjectURI, saveError);
                });
            }
        }];
    } else {
        [MFlowEventContext updateSessionEventWithURI:self.currentSesssionObjectIDURL lastPauseTime:lastPause completion:^(NSURL *updatedObjectURI, NSError *saveError) {
            
            
            if(nil != saveError) {
                // TODO: Handle the error
                NSLog(@"There was some error with updating the session events %@",saveError);
            }
            if(successBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(updatedObjectURI, saveError);
                });
            }
        }];
    }
    
}


#pragma mark - Event Uploading Helpers

- (NSString *)generateEventPayloadForType:(NSNumber *)n data:(NSArray *)evts {
	id<MFlowEvent> evt;
	NSMutableString *guts = [NSMutableString stringWithCapacity:0];
	
	for (int i=0; i < evts.count; i++) {
		evt = [evts objectAtIndex:i];
		
		[guts appendString:[evt asXML]];
	}
	
	return [NSString stringWithFormat:@"<Events EventTypeID=\"%@\">%@</Events>",n,guts];
	
}

- (NSURLRequest *)submissionRequestWithPayload:(NSString *)payloadXML userID:(NSNumber *)userID uniqueID:(NSString *)uuid {
    
    if([MFlowConfig mflowAppURL] == nil) {
        [self runCompleteHandler:nil withError:nil];
    }
    
//    NSLog(@"EVENTS: Send Payload XML: %@",payloadXML);
    
    // Added allowLossyConvertsion:YES - pf 2/19/13
    //  (Needed specifically to catch problem with Cox apps where non-ascii characters were [mistakenly] getting into the data attribute of agg events causing the conversion here to return nil)
    NSData *d1 = [payloadXML dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	NSData *d2 = [d1 gzipDeflate];
	NSString *fullXMLEncoded = [[d2 base64Encoding] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	NSString *payloadString = [NSString stringWithFormat:@"xml=%@",fullXMLEncoded];
	payloadString = [payloadString stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
	NSString *urlFormat = (self.useEcho) ? EVENTS_ECHO_FUNCTION_URL : EVENTS_FUNCTION_URL;
	NSString *url = [NSString stringWithFormat:urlFormat, [MFlowConfig mflowAppURL],[userID intValue],uuid];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[payloadString dataUsingEncoding:NSASCIIStringEncoding]];
    return request;
}


#pragma mark - Public Tracking Methods

- (NSString *)generateEventID {
	
	CFUUIDRef r = CFUUIDCreate(NULL);
	NSString *guid = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL,r));
	CFRelease(r);
	
	return guid;
}

- (void)trackEventWithType:(NSInteger)eventTypeID duration:(NSInteger)duration itemid:(NSNumber *)iid parentid:(NSNumber *)pid data:(NSString *)data {
	[MFlowEventContext nonAggEventWithType:eventTypeID duration:duration itemid:iid parentid:pid data:data completion:NULL];
}

- (void)trackEventAggregatedWithType:(NSInteger)eventTypeID duration:(NSInteger)duration itemid:(NSNumber *)iid parentid:(NSNumber *)pid data:(NSString *)data {
    
    if(nil == self.aggEventURICache) {
        self.aggEventURICache = [NSMutableDictionary dictionary];
    }
    
    NSDate *evtDate = [self generateAggEventDate];
    NSNumber *itemid = (iid == nil) ? [NSNumber numberWithInteger:0] : iid;
    NSNumber *parentid = (pid == nil) ? [NSNumber numberWithInteger:0] : pid;
    NSString *evtKey = [self generateAggEventKeyWithDate:evtDate eventType:[NSNumber numberWithInt:eventTypeID] itemID:itemid parentID:parentid];
    NSURL *eventURI = [self.aggEventURICache objectForKey:evtKey];
    
    if(nil != eventURI) {
        [MFlowEventContext incrementAggEvent:eventURI withDuration:duration completion:NULL];
    } else {
        __weak MFlowEventManager *blockSelf = self;
        [MFlowEventContext aggEventWithType:eventTypeID aggType:self.aggMode duration:duration itemid:itemid parentid:parentid date:evtDate data:data completion:^(NSURL *managedObjectURI, NSError *saveError) {
            if(nil == saveError) {
                [blockSelf.aggEventURICache setObject:managedObjectURI forKey:evtKey];
            }
        }];
    }
}


#pragma mark - Agg Event Helpers

- (void)loadCurrentAggEventsIntoCache {    
    // DO URL CAPTURE FOR CURRENT AGG EVENTS
    NSArray *activeAggEvents = [[MFlowEventContext sharedMFlowEventContext] fetchActiveAggEventsWithType:self.aggMode fetchError:NULL];
    NSMutableDictionary *aggEventURICache = [NSMutableDictionary dictionaryWithCapacity:activeAggEvents.count];
    for(MFlowAggEvent *event in activeAggEvents) {
        NSString *eventKey = [self generateAggEventKeyWithDate:event.EventTimeStamp eventType:event.EventType itemID:event.EventItemID parentID:event.EventParentID];
        NSURL *eventURI = [[event objectID] URIRepresentation];
        [aggEventURICache setObject:eventURI forKey:eventKey];
    }
    self.aggEventURICache = aggEventURICache;
}

- (NSDate *)generateAggEventDate {
	return (self.aggMode == MFlowEventAggregationTypeSample) ? [[NSDate gregorianDate] dateRoundedDownToHour] : [[NSDate gregorianDate] dateRoundedDownToDay];
}

- (NSString *)generateAggEventKeyWithDate:(NSDate *)d eventType:(NSNumber *)n itemID:(NSNumber *)i parentID:(NSNumber *)p{
	
	return [NSString stringWithFormat:@"%@__%@__%@__%@",[self.aggKeyDateFormatter stringFromDate:d],n,i,p];
	
}


#pragma mark - Cancel

- (void)cancelUploadProcess {
    [self.urlConnection cancel];
    [self runCompleteHandler:nil withError:nil];
}


#pragma mark - Upload Response Parser

- (NSError *)errorFromResponse:(NSData *)responseData {
    
    // try to parse the error
    NSString *docString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
//    NSLog(@"EVENTS: Server response document: %@",docString);
    // there was an error constructing the string, bad encoding probably
    if(docString == nil)
    {
        return [[NSError alloc] initWithDomain:@"MFlowEventManagerDomain" code:1004 userInfo:[NSDictionary dictionaryWithObject:@"Unable to parse responseData" forKey:NSLocalizedDescriptionKey]];
    }
    
    
    NSError *parseError = nil;
    CXMLDocument *resultDoc = nil;
    
    @try {
        resultDoc = [[CXMLDocument alloc] initWithData:responseData options:0 error:&parseError];
    }
    @catch (NSException *exception) {
         return [[NSError alloc] initWithDomain:@"MFlowEventManagerDomain" code:1004 userInfo:[NSDictionary dictionaryWithObject:@"Unable to parse responseData" forKey:NSLocalizedDescriptionKey]];
    }
    
    
	if (parseError != nil) {
        return [[NSError alloc] initWithDomain:@"MFlowEventManagerDomain" code:1001 userInfo:[NSDictionary dictionaryWithObject:parseError forKey:NSUnderlyingErrorKey]];
	}
	
	if ([[[resultDoc rootElement] name] compare:@"root"] != NSOrderedSame) {
        return [[NSError alloc] initWithDomain:@"MFlowEventManagerDomain" code:1002 userInfo:[NSDictionary dictionaryWithObject:@"The response doccument is missing it's root node." forKey:NSLocalizedDescriptionKey]];
	}
	
	CXMLNode *errorNode = [[resultDoc rootElement] attributeForName:@"error"];
	if (errorNode != nil) {
        NSString *message = [NSString stringWithFormat:@"The server returned an error: %@: %@",[errorNode stringValue],[[resultDoc rootElement] stringValue]];
        return [[NSError alloc] initWithDomain:@"MFlowEventManagerDomain" code:1003 userInfo:[NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey]];
	}

    return nil;
}


#pragma mark - Upload Complete Handler

- (void)runCompleteHandler:(NSData *)responseData withError:(NSError *)uploadError {
    if(self.uploadCompleteHandler) {
        self.uploadCompleteHandler(responseData, uploadError);
    }
}


#pragma mark - NSURLConnection Delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.connectionData = [[NSMutableData alloc] initWithLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.connectionData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if(self.uploadCompleteHandler) {
        self.uploadCompleteHandler(nil, error);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    NSError *responseError = [self errorFromResponse:self.connectionData];
    if(nil != responseError) {
        [self runCompleteHandler:self.connectionData withError:responseError];
        return;
    }
    
    __weak MFlowEventManager *blockSelf = self;
    [MFlowEventContext saveDataInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
        for(NSManagedObjectID *objectID in self.uploadedEventObjectIDs) {
            NSManagedObject *object = [localContext existingObjectWithID:objectID error:NULL];
            if(nil != object) {
                [localContext deleteObject:object];
            }
        }
        blockSelf.uploadedEventObjectIDs = nil;
    }
    completionHandler:^(BOOL success, NSNotification *didSaveNotification, NSError *saveError) {
        [blockSelf runCompleteHandler:self.connectionData withError:saveError];
    }];
        
}


#pragma mark - Memory management

- (void)dealloc {
    
    [self stopObservingNotifications];
	
//	[kEventDateFormatter release];	
    
	
}

@end
