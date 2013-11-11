//
//  MFlowContainerBatchOperation.m
//  ArchTest1
//
//  Created by Stephen Tallent on 1/7/10.
//  Copyright 2010 Mercury Intermedia. All rights reserved.
//

#import "MFlowContainerBatchOperation.h"
#import "MFlowContainerBatchItem.h"
#import "MFlowContainerBatchStatus.h"
#import "MFlowFileManager.h"
#import "MFlowContainer.h"
#import "MFlowItem.h"

//NSString * const kBatchStarting = @"kBatchStarting";
NSString * const kBatchProgress = @"kBatchProgress";
//NSString * const kBatchComplete = @"kBatchComplete";

@implementation MFlowContainerBatchOperation


-(id)initWithBatchItems:(NSArray *)a{
	self = [super init];
	if (self)
    {
        batchItems = a;
	}
	return self;
}

-(void)main{
	
	if (batchItems == nil) {
		return;
	}
	
	totalContainers = batchItems.count;
	currentContainer = 0;
	
	[self dispatchStatusUpdateForPhase:MFlowBatchPhaseStart];
	
	for (MFlowContainerBatchItem *item in batchItems) {
			
		currentBatchItem = item;
		
		currentContainer++;
		currentImage = 0;
		totalImages = 0;
		
		[self dispatchStatusUpdateForPhase:MFlowBatchPhaseContainerStart];
		
		MFlowContainer *c = [[MFlowContainer alloc] initWithContainerID:item.containerID useDiskCache:true];
		c.compressionMode = @"";
		[c updateContentsSynchronously:nil];
		
		//NSLog(@"Container: %i has %i items",c.containerID, c.data.count);
		
		if ([self isCancelled]) {
			[self finish];
			return;
		}
		
		if (item.imageItemPaths != nil && [item.imageItemPaths compare:@""] != NSOrderedSame) {
			
			NSArray *imageItems = [self getImageItemsFromData:c.data withPaths:item.imageItemPaths];
			
			totalImages = imageItems.count;
			currentImage = 0;
			
			[self dispatchStatusUpdateForPhase:MFlowBatchPhaseContainerImagesStart];

			for (MFlowItem *image in imageItems) {
				
				currentImage++;
				
				[self dispatchStatusUpdateForPhase:MFlowBatchPhaseContainerImageStart];
				
				if (image.count > 0) {
					[[MFlowFileManager sharedMFlowFileManager] retrieveMFlowFileToCache:image filegroup:item.filegroup];
				}
				
				if ([self isCancelled]) {
					[self finish];
					return;
				}
			
			}
			
		}
		

	}
	
	[self finish];
	
}

-(void)finish{
	[self dispatchStatusUpdateForPhase:MFlowBatchPhaseEnd];
}

-(NSArray *)getImageItemsFromData:(NSArray *)a withPaths:(NSString *)pString{
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:0];
	
	NSString *pathString = [pString stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSArray *paths = [pathString componentsSeparatedByString:@","];
	
	for (NSString *path in paths) {

		NSArray *items = [a valueForKeyPath:path];
		
		for (MFlowItem *item in items) {
			if ([item isKindOfClass:[NSArray class]]) {
				[results addObjectsFromArray:(NSArray*)item];
			}
		}
		
		[results addObjectsFromArray:[a valueForKeyPath:path]];
	}
	
	return results;

}


-(void)dispatchStatusUpdateForPhase:(MFlowBatchPhase)phase{
	MFlowContainerBatchStatus *s = [[MFlowContainerBatchStatus alloc] init];
	
	s.phase = phase;
	
	s.totalContainers = totalContainers;
	s.currentContainer = currentContainer;
	s.totalImages = totalImages;
	s.currentImage = currentImage;
	
	s.currentTitle = currentBatchItem.title;
	s.currentSubtitle = currentBatchItem.subtitle;
	
	[self performSelectorOnMainThread:@selector(postNotificationWithObject:) withObject:s waitUntilDone:true];
}
	

-(void)postNotificationWithObject:(MFlowContainerBatchStatus *)statusObj{
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	
	[center postNotificationName:kBatchProgress 
						  object:self 
						userInfo:[NSDictionary dictionaryWithObject:statusObj forKey:@"statusObject"]];

}




@end

