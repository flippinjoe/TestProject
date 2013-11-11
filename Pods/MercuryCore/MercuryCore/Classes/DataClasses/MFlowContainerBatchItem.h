//
//  MFlowContainerBatchItem.h
//  ArchTest1
//
//  Created by Stephen Tallent on 1/7/10.
//  Copyright 2010 Mercury Intermedia. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MFlowContainerBatchItem : NSObject 

@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *subtitle;
@property(nonatomic, assign) NSInteger containerID;
@property(nonatomic, copy) NSString *imageItemPaths;
@property(nonatomic, copy) NSString *filegroup;

-(id)initWithContainerID:(NSInteger)cid title:(NSString *)t imageItemPaths:(NSString *)p filegroup:(NSString *)f;

@end
