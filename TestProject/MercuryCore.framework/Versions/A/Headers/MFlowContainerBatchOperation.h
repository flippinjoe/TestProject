//
//  MFlowContainerBatchOperation.h
//  ArchTest1
//
//  Created by Stephen Tallent on 1/7/10.
//  Copyright 2010 Mercury Intermedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MFlowContainerBatchStatus.h"

//extern NSString * const kBatchStarting;
extern NSString * const kBatchProgress;
//extern NSString * const kBatchComplete;

@class MFlowContainerBatchItem;

@interface MFlowContainerBatchOperation : NSOperation {
	NSArray *batchItems;
	
	NSInteger totalContainers;
	NSInteger currentContainer;
	NSInteger totalImages;
	NSInteger currentImage;
	
	MFlowContainerBatchItem *currentBatchItem;
	
}

-(id)initWithBatchItems:(NSArray *)a;

-(NSArray *)getImageItemsFromData:(NSArray *)a withPaths:(NSString *)paths;

-(void)dispatchStatusUpdateForPhase:(MFlowBatchPhase)phase;

-(void)finish;

@end
