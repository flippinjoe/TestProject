//
//  MFLowContainerBatchProcess.m
//  MercuryCoreLib
//
//  Created by Joseph Ridenour on 11/30/10.
//  Copyright 2010 Mercury Intermedia. All rights reserved.
//

#import "MFLowContainerBatchProcess.h"
#import "MFlowContainerBatchStatus.h"
#import "MFlowFileManager.h"
#import "MFlowContainer.h"
#import "MFlowConfig.h"
#import "MFlowItem.h"

@implementation MFLowContainerBatchProcess

@synthesize batchQueue = _batchQueue;
@synthesize batchItems = _batchItems;

@synthesize currentContainer = _currentContainer;
@synthesize totalContainers = _totalContainers;

#pragma mark - Initialize

-(id)initWithBatchItems:(NSArray *)a
{
	self = [super init];
    if(self) 
    {
        _batchItems = [[NSArray alloc] initWithArray:a];
        _batchQueue = [NSOperationQueue new];
	}
	return self;
}

-(id)initWithBatchItems:(NSArray *)a withMaxCCOperations:(NSInteger)max
{
	self = [self initWithBatchItems:a];
    if(self) 
    {
        [self.batchQueue setMaxConcurrentOperationCount:max];
    }
	return self;
}

#pragma mark - Start Process

-(void)start
{
    
	if (_batchItems == nil) 
    {
        NSLog(@"Error: No batch items can't start");
		return;
	}
    
    self.totalContainers = [self.batchItems count];

	for (MFLowContainerBatchItem2 *item in self.batchItems) 
    {
        
#ifdef NS_BLOCKS_AVAILABLE
        __block __typeof__(self) selfRef = self;
        __block NSLock *counterLock = [NSLock new];
        NSString *itemTitle = item.title;
        NSString *itemSubtitle = item.subtitle;
        NSInteger itemContainerID = item.containerID;
        //NSLog(@"using block style callback");
        [item setCallbackHandler:^(id b, MFlowBatchPhase phase) {
            MFlowContainerBatchStatus *s = [[MFlowContainerBatchStatus alloc] init];
            if([selfRef.batchQueue operationCount] <= 1 && phase == MFlowBatchPhaseContainerEnd){
                s.phase = MFlowBatchPhaseEnd;
            } else {
                s.phase = phase;
            }
            
            s.currentContainer = selfRef.currentContainer;
            s.totalContainers = selfRef.totalContainers;
            s.currentTitle = itemTitle;
            s.currentSubtitle = itemSubtitle;
            s.currentContainerID = itemContainerID;
            
            [selfRef performSelectorOnMainThread:@selector(postNotificationWithObject:) withObject:s waitUntilDone:NO];
            
            [counterLock lock];
            selfRef.currentContainer++;
            [counterLock unlock];
        }];
#else
		[item setDelegate:self];
#endif
		[self.batchQueue addOperation:item];
	}
    
	_batchItems = nil;
}

#pragma mark - Cancel

- (void)cancel 
{
    [self.batchQueue cancelAllOperations];
    
    if(_batchQueue) _batchQueue = nil;
    if(_batchItems) _batchItems = nil;
    
    MFlowContainerBatchStatus *s = [[MFlowContainerBatchStatus alloc] init];
	s.phase = MFlowBatchPhaseEnd;
    [self performSelectorOnMainThread:@selector(postNotificationWithObject:) withObject:s waitUntilDone:NO];
}

-(void)postNotificationWithObject:(MFlowContainerBatchStatus *)statusObj
{
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	
	[center postNotificationName:kBatchProgress2 
						  object:self 
						userInfo:[NSDictionary dictionaryWithObject:statusObj forKey:@"statusObject"]];
	
}


-(void)dispatchStatusUpdateForItem:(MFlowBatchPhase)phase withObject:(MFLowContainerBatchItem2 *)item{
	MFlowContainerBatchStatus *s = [[MFlowContainerBatchStatus alloc] init];
	if([self.batchQueue operationCount] <= 1 && phase == MFlowBatchPhaseContainerEnd){
        //NSLog(@"Last Item of %i", [_batchItems count]);
		s.phase = MFlowBatchPhaseEnd;
	} else {
		s.phase = phase;
	}
	
    s.currentContainer = self.currentContainer;
    s.totalContainers = self.totalContainers;
	s.currentTitle = item.title;
	s.currentSubtitle = item.subtitle;
	s.currentContainerID = item.containerID;
	
	[self performSelectorOnMainThread:@selector(postNotificationWithObject:) withObject:s waitUntilDone:true];
	self.currentContainer++;
}

- (void)dealloc 
{
    NSLog(@"DEALLOC BATCH PROCESS");
}

@end
