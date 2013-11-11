//
//  MFLowContainerBatchProcess.h
//  MercuryCoreLib
//
//  Created by Joseph Ridenour on 11/30/10.
//  Copyright 2010 Mercury Intermedia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFLowContainerBatchItem2.h"

@interface MFLowContainerBatchProcess : NSObject <BatchItemDelegate> 

@property (nonatomic, strong) NSOperationQueue *batchQueue;
@property (nonatomic, strong) NSArray *batchItems;

@property (nonatomic, assign) NSInteger currentContainer;
@property (nonatomic, assign) NSInteger totalContainers;


- (id)initWithBatchItems:(NSArray *)a;
- (id)initWithBatchItems:(NSArray *)a withMaxCCOperations:(NSInteger)max;

- (void)start;
- (void)cancel;

@end
