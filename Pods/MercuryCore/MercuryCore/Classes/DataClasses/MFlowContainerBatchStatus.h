//
//  MFlowContainerBatchStatus.h
//  USAToday1
//
//  Created by Stephen Tallent on 1/8/10.
//  Copyright 2010 Mercury Intermedia. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    MFlowBatchPhaseStart,
    MFlowBatchPhaseContainerStart,
	MFlowBatchPhaseContainerImagesStart,
	MFlowBatchPhaseContainerImageStart,
	MFlowBatchPhaseContainerEnd,
	MFlowBatchPhaseEnd
} MFlowBatchPhase;

@interface MFlowContainerBatchStatus : NSObject {
	MFlowBatchPhase phase;
	NSInteger currentContainer;
	NSInteger totalContainers;
	NSInteger currentImage;
	NSInteger totalImages;
	NSString *currentTitle;
	NSString *currentSubtitle;
	NSInteger currentContainerID;
}

@property(nonatomic, assign) MFlowBatchPhase phase;
@property(nonatomic, assign) NSInteger currentContainer;
@property(nonatomic, assign) NSInteger totalContainers;
@property(nonatomic, assign) NSInteger currentImage;
@property(nonatomic, assign) NSInteger totalImages;
@property(nonatomic, copy) NSString *currentTitle;
@property(nonatomic, copy) NSString *currentSubtitle;
@property(nonatomic, assign) NSInteger currentContainerID;

@end
