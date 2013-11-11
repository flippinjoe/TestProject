//
//  MFlowContainerBatchItem.m
//  ArchTest1
//
//  Created by Stephen Tallent on 1/7/10.
//  Copyright 2010 Mercury Intermedia. All rights reserved.
//

#import "MFlowContainerBatchItem.h"


@implementation MFlowContainerBatchItem

@synthesize title = _title;
@synthesize subtitle = _subtitle;
@synthesize containerID = _containerID;
@synthesize imageItemPaths = _imageItemPaths;
@synthesize filegroup = _filegroup;

-(id)initWithContainerID:(NSInteger)cid title:(NSString *)t imageItemPaths:(NSString *)p filegroup:(NSString *)f{
	self = [super init];
    if(self) {
        _containerID = cid;
        _title = [t copy];
        _imageItemPaths = [p copy];
        _filegroup = [f copy];
    }
	return self;
}


@end
