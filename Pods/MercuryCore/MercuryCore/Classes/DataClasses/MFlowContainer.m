//
//  MFlowContainer.m
//  MercuryCoreDev
//
//  Created by Stephen Tallent on 5/11/09.
//  Copyright 2009 Stephen. All rights reserved.
//
#import "MFlowConfig.h"
#import "MFlowContainer.h"
#import "MFlowContainerData.h"
#import "MFlowItem.h"
#import "MFlowNetworkActivityManager.h"
#import "TC_CXMLExtensions.h"
#import "TC_NSDataExtensions.h"
#import "MFlowItemParser.h"
#import "MFlowContainerParser.h"
#import "TC_NSDateExtensions.h"


NSString * const kMFlowContainerUpdated = @"kMFlowContainerUpdated";
NSString * const kMFlowContainerError = @"kMFlowContainerError";
NSString * const MFlowContainerErrorDomain = @"MFlowContainerErrorDomain";

static dispatch_queue_t container_archive_queue;

dispatch_queue_t mflow_container_archive_queue(void);
dispatch_queue_t mflow_container_archive_queue() {
    if (container_archive_queue == NULL) {
        container_archive_queue = dispatch_queue_create("com.mercury.mflow.container_archive_queue", 0);
    }
    return container_archive_queue;
}

@interface MFlowContainer ()
@property (nonatomic, assign, readwrite) BOOL useDiskCache;
@property (nonatomic, assign, readwrite) NSInteger numNewItems;

- (void)notify;
- (void)notifyWithContentsChanged:(BOOL)c;
- (void)notifyWithError:(NSError *)error;
- (NSArray *) arrayAsStitchedCopyOfMFlowPublishedItems;
- (void) flushToDisk;
- (void) rebuildData;

@end


@implementation MFlowContainer

@synthesize delegate = _delegate;
@synthesize compressionMode = _compressionMode;
@synthesize data = _data;
@synthesize useDiskCache = _useDiskCache;
@synthesize containerID = _containerID;
@synthesize numNewItems = _numNewItems;
@synthesize diskCachePath = _diskCachePath;
@synthesize contentsChanged = _contentsChanged;
/*
@synthesize parseTime;
@synthesize totalTime;
 */
@synthesize mflowData = _mflowData;
@synthesize canceled = _cancled;
@synthesize updateBlock = _updateBlock;
@synthesize responseQueue = _responseQueue;

NSString *kMFlowContainerURLFormat = @"%@Tallent.MFlow.WS/REST/Item.aspx?compressionMode=%@&Function=GetPublishingContainersItems%@&ContainerIDList=%i&ContainerVersion=%@";

#pragma mark - Class Methods

+ (id)containerWithContainerID:(int)cID
{
	return [MFlowContainer containerWithContainerID:cID useDiskCache:true];
}

+ (id)containerWithContainerID:(int)cID useDiskCache:(bool)uc
{
	return [[MFlowContainer alloc] initWithContainerID:cID useDiskCache:uc];
}

+ (NSString *)diskCachePathWithContainerID:(NSInteger)aContainerID
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES); 
	NSString *cachesDirectory = [paths objectAtIndex:0];
	return [cachesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"containerV2Cache%i",aContainerID]];
}

+ (NSDateFormatter *) dateFormatter
{
	static NSDateFormatter		*sDateFormatter = nil;
	
	if (sDateFormatter == nil) {
		sDateFormatter = [[NSDateFormatter alloc] init];
		sDateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"EN"];
		[sDateFormatter setDateFormat:@"MM/dd/yyyy hh:mm:ss a"];
	}
	
	return sDateFormatter;
}


#pragma mark - Initializer

- (id)initWithContainerID:(int)cID 
{
	return [self initWithContainerID:cID useDiskCache:true];
}

- (id)initWithContainerID:(int)cID useDiskCache:(bool)uc
{
	
	if ((self = [super init])) {
		
		_containerID = cID;
		_useDiskCache = uc;
		_compressionMode = @"gzip";
		_numNewItems = 0;
        _diskCachePath = [[self class] diskCachePathWithContainerID:_containerID];
		
		if (_useDiskCache){
			
			@try {
				_mflowData = [NSKeyedUnarchiver unarchiveObjectWithFile:_diskCachePath];
			}
			@catch (NSException* ex) {
				_mflowData = nil;
			}
			
			
			if (_mflowData != nil) {
				[self rebuildData];
			}
		}
		
		if (_mflowData == nil) {
			_mflowData = [[MFlowContainerData alloc] init];
		}
	
    }
	
	return self;
}


#pragma mark - Memory Management

- (void)dealloc
{
    //self.updateBlock = nil;
    
	
    
    self.responseQueue = NULL;
	
}


#pragma mark - Data Age

- (bool)dataStale
{
	
	return self.mflowData.dataStale;
	
}

- (NSDate *)dataRetrievalDate
{
	
	return self.mflowData.dataRetrievalDate;
}


#pragma mark - Updating

- (void)getContents
{
	if (!_responseQueue) {
        self.responseQueue = dispatch_get_main_queue();
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self checkContents];
    });
}

- (void)checkContents
{
    
	@autoreleasepool {
	
        // no matter what, lets make certain numNewItems is 0 because
        // it is only to show the amoutn of new items to a container immediately after a call to the server
            self.numNewItems = 0;
            
            // lets check to see if we can skip updating
        BOOL success = YES;
        NSError *error;
        if (!self.dataStale) {
            if (self.data == nil) {
                [self rebuildData];
            }
            _contentsChanged = false;
        } else {
            success = [self updateContentsSynchronously:&error];
        }
            
        if (success || _data != nil)
        {
            [self notify];
        }
        else
        {
            [self notifyWithError:error];
        }

    }
}

- (BOOL)updateContentsSynchronously:(NSError **)error
{
	NSHTTPURLResponse *response = nil;
	NSString *useDeltaString = @"&Delta=true";
	NSNumber *cVersion = self.mflowData.containerVersion;
	NSString *cVersionString = (cVersion != nil) ? [cVersion stringValue] : @"";
	
	if (cVersion == nil) {
		cVersionString = @"";
	}

	NSString *urlString = [NSString stringWithFormat: kMFlowContainerURLFormat, [MFlowConfig mflowAppURL], self.compressionMode, useDeltaString, self.containerID, cVersionString];
	
    NSError *connectionError = nil;
    [[MFlowNetworkActivityManager sharedInstance] incrementActivityCount];
	NSData *connData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] returningResponse:&response error:&connectionError];
    [[MFlowNetworkActivityManager sharedInstance] decrementActivityCount];
    
    // IF WE HAD A CONNECTION ERROR, NOTIFY OF ERROR AND EXIT
    if(connData == nil) {
        if (error != NULL) {
            *error = connectionError;
        }

        return NO;
    }

	// handle responses
    if([response statusCode] != 200) {
        NSMutableDictionary *errorInfo = [NSMutableDictionary dictionaryWithCapacity:2];
        NSString *errorMessage = [NSString stringWithFormat:@"There was a non 200 response from the server. Status code %i",[response statusCode]];
        [errorInfo setObject:errorMessage forKey:NSLocalizedDescriptionKey];
        NSError *responseError = [NSError errorWithDomain:MFlowContainerErrorDomain code:MFlowContainerServerResponseError userInfo:errorInfo];
        
        if (error != NULL) {
            *error = responseError;
        }
        
        return NO;
    }

    NSError *parseError;
    BOOL parsed = [self parseData:connData error:&parseError];
    if(!parsed)
    {
        if(error)
        {
            *error = parseError;
        }
        return NO;
    }
    
    return YES;
}

- (void)updateWithHandler:(MFlowContainerUpdatedBlock)handler
{
    self.updateBlock = handler;
    [self getContents];
}


#pragma mark - Data Structure

- (NSArray *)arrayAsStitchedCopyOfMFlowPublishedItems
{
	NSDictionary *tmpDict;
	MFlowItem *parentItem;
	MFlowItem *childItem;
	NSString *linkedAttName;
	NSMutableArray *childItemsArray;
    
    NSDictionary *masterItems = self.mflowData.masterItems;
    NSMutableArray *stitchedItemIDs = [[NSMutableArray alloc] initWithCapacity:masterItems.count];
	NSMutableDictionary *stitchedData = [[NSMutableDictionary alloc] initWithDictionary:masterItems copyItems:YES];
	
	int cnt = self.mflowData.relationNodes.count;
	NSArray *sortedRelationNodes = self.mflowData.relationNodes;
	
	for (int i = 0; i < cnt; i++){
		
		tmpDict = [sortedRelationNodes objectAtIndex:i];
		parentItem = [stitchedData objectForKey:[tmpDict objectForKey:@"IID"]];
		childItem = [stitchedData objectForKey:[tmpDict objectForKey:@"CID"]];
		
		if (childItem == nil || parentItem == nil) {
            
			continue;
		}
		
        // if we have a child item add it to the stitched list
		[stitchedItemIDs addObject:[[childItem valueForKey:@"ItemID"] stringValue]];
        
        // look for any linked items, if we have some link in the relationship 
		linkedAttName = [self.mflowData.linkedAttNameIDs objectForKey:[tmpDict objectForKey:@"AID"]];
		if (linkedAttName == nil) {
			continue;
		}
        
		if ( [[parentItem objectForKey:linkedAttName] isKindOfClass:[NSDictionary class]] ){
			// its a one to one	
			[parentItem setObject:childItem	forKey:linkedAttName];
			
		} else {
			
			// its a one to many
			childItemsArray = [parentItem objectForKey:linkedAttName];
            
            // if this is not an array for some reason or the array is empty stick in an empty array 
			if (![childItemsArray isKindOfClass:[NSMutableArray class]] || childItemsArray.count == 0) {
				childItemsArray = [NSMutableArray arrayWithCapacity:0];
				[parentItem setObject:childItemsArray forKey:linkedAttName];
			}
			
			
			@try {
				// if this fails, it means that somehow some stitched items got written to disk i think
				[childItemsArray addObject:childItem];
			}
			@catch (NSException* ex) {
                
				childItemsArray = [NSMutableArray arrayWithCapacity:0];
				[parentItem setObject:childItemsArray forKey:linkedAttName];
				
				[childItemsArray addObject:childItem];
			}
			
            
		}
		
	}
	
    
    NSUInteger publishedItemsCount = self.mflowData.publishedItemIDs.count;
    NSMutableArray *finalItemArray = [NSMutableArray arrayWithCapacity:publishedItemsCount];
    
    for(NSString *itemIDKey in self.mflowData.publishedItemIDs)
    {
        id item = [stitchedData objectForKey:itemIDKey];
        if(item)
        {
            [finalItemArray addObject:item];
            [stitchedItemIDs addObject:[[item valueForKey:@"ItemID"] stringValue]]; // item ids are numbers
        }
    }
	
    
	// prune the list if we got changes
    if(self.contentsChanged && stitchedItemIDs.count > 0)
    {
        [self pruneMasterItemListWithIncludes:stitchedItemIDs];
    }
    
	
	return finalItemArray;
	
}

- (void)rebuildData
{
	self.data = [self arrayAsStitchedCopyOfMFlowPublishedItems];
}


#pragma mark - Parsing

- (BOOL)parseData:(NSData *)containerData error:(NSError * __autoreleasing *)error
{
	self.mflowData.dataRetrievalDate = [NSDate gregorianDate];
	
	MFlowContainerParser *p = [[MFlowContainerParser alloc] initWithXMLData:containerData];
	
	[p parse];
	
	if (p.responseStatus == MFlowContainerResponseError) {
        if(error)
        {
            *error = [NSError errorWithDomain:@"MFlowContainerDomain" code:1001 userInfo:[NSDictionary dictionaryWithObject:@"There was an error returned from parsing the container" forKey:NSLocalizedDescriptionKey]];
        }
        return NO;
    }
	
	if (p.responseStatus == MFlowContainerResponseUnchanged) {
		_contentsChanged = NO;
		if (self.data == nil)
        {
            [self rebuildData];
        }
		
		if (self.useDiskCache) 
        {
            [self flushToDisk];
        }
        
		return YES;
		
	}
	
	self.mflowData.containerVersion = p.expressedVersionNumber;
	self.mflowData.ttlSeconds = p.ttlSeconds;
	self.mflowData.relationNodes = p.sortedRelationNodes;
	
	// lets update the amount of new items in the container
	NSArray *pubItemIDs = p.pubItemIDs;
	if (self.mflowData.publishedItemIDs != nil) {
		for (NSInteger i = 0; i < pubItemIDs.count; i++) {
			if (![self.mflowData.publishedItemIDs containsObject:[pubItemIDs objectAtIndex:i]]) {
				self.numNewItems++;
			}
		}
	}
	
	self.mflowData.publishedItemIDs = p.pubItemIDs;
	
	NSMutableDictionary *linkedAttNameIDs = [NSMutableDictionary dictionaryWithDictionary:self.mflowData.linkedAttNameIDs];
	[linkedAttNameIDs addEntriesFromDictionary:p.linkedAttNameIDs];
	self.mflowData.linkedAttNameIDs = linkedAttNameIDs;
	
    // now add the new items to the existing items, if there are any
	NSMutableDictionary *newMasterList = [NSMutableDictionary dictionaryWithDictionary:self.mflowData.masterItems];
	[newMasterList addEntriesFromDictionary:p.newItems];
    
	// if this was a delta, we need to clean out items no longer used by this container
	if (p.responseStatus == MFlowContainerResponseDelta){
		NSArray *lst = [p.removedItems componentsSeparatedByString:@","];
		int cnt = lst.count;
		for (int i = 0; i < cnt; i++){
			[newMasterList removeObjectForKey:[lst objectAtIndex:i]];
		}
	}

	// now stick the new master list back onto the data object and save
	self.mflowData.masterItems = newMasterList;

	_contentsChanged = YES;
	
    [self rebuildData];
	
	if (self.useDiskCache) {
		[self flushToDisk];
	}
	
    return YES;
}


#pragma mark - Pruning

- (NSString *)diskCachePathWithContainerID:(NSInteger)aContainerID
{
	return [MFlowContainer diskCachePathWithContainerID:aContainerID];
}

- (void)pruneMasterItemListWithIncludes:(NSArray *)itemsToIncludeItemIDs
{

    NSSet *includeSet = [NSSet setWithArray:itemsToIncludeItemIDs];
    
	NSMutableDictionary *currentlyUsedItems = [[NSMutableDictionary alloc] initWithCapacity:includeSet.count];
	for (NSString *key in includeSet) {
		id item = [self.mflowData.masterItems objectForKey:key];
		if(item != nil) {
			[currentlyUsedItems setObject:item forKey:key];
		}
	}
	
	[self.mflowData setMasterItems:currentlyUsedItems];
	
}


#pragma mark - Archiving

- (void)flushToDisk
{
    // stick archive actions in the archive queue which is first-in-first-out
    dispatch_async(mflow_container_archive_queue(), ^{
       [NSKeyedArchiver archiveRootObject:self.mflowData toFile:self.diskCachePath]; 
    });
}


#pragma mark - Getters/Setters
- (void)setResponseQueue:(dispatch_queue_t)responseQueue
{
    // Note dispatch_retain/dispatch_release don't do anything if the
    // argument is a global (main and concurrent) queues.
    if (_responseQueue != NULL) {
    }
    
    
    _responseQueue = responseQueue;
}

#pragma mark - Private Methods

- (void)notify 
{
	if(self.canceled) {
        return;  
    }
    [self notifyWithContentsChanged:self.contentsChanged];
}

- (void)notifyWithContentsChanged:(BOOL)c
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    dispatch_async(_responseQueue, ^{
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(containerUpdated:contentsChanged:)]) {
            [self.delegate containerUpdated:self contentsChanged:c];
        }
        if(self.updateBlock)
        {
            self.updateBlock(YES,c,nil);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kMFlowContainerUpdated object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:c] forKey:@"contentsChanged"]];
    });
}

- (void)notifyWithError:(NSError *)err
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    dispatch_async(_responseQueue, ^{
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(containerErrorReceived:error:)]) {
            [self.delegate containerErrorReceived:self error:err];
        }
        if(self.updateBlock)
        {
            self.updateBlock(NO,NO,err);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kMFlowContainerUpdated object:self];
    });    
}

@end



