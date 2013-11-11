//
//  MFLowContainerBatchItem2.h
//  MercuryCoreLib
//
//  Created by Joseph Ridenour on 11/30/10.
//  Copyright 2010 Mercury Intermedia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFlowContainerBatchStatus.h"

#ifdef NS_BLOCKS_AVAILABLE
typedef void (^BatchItemCallback)(id item, MFlowBatchPhase phase);
#endif


@protocol BatchItemDelegate;

extern NSString * const kBatchProgress2;

@interface MFLowContainerBatchItem2 : NSOperation

#ifdef NS_BLOCKS_AVAILABLE
@property (nonatomic, copy) BatchItemCallback callbackHandler;
#endif

@property (nonatomic, weak) NSObject <BatchItemDelegate> *delegate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, assign) NSInteger containerID;
@property (nonatomic, copy) NSString *imageItemPaths;
@property (nonatomic, copy) NSString *filegroup;

-(id)initWithContainerID:(NSInteger)cid title:(NSString *)t imageItemPaths:(NSString *)p filegroup:(NSString *)f;
-(NSArray *)getImageItemsFromData:(NSArray *)a withPaths:(NSString *)pString;

@end


@protocol BatchItemDelegate <NSObject>
-(void)dispatchStatusUpdateForItem:(MFlowBatchPhase)phase withObject:(MFLowContainerBatchItem2 *)item;
@end