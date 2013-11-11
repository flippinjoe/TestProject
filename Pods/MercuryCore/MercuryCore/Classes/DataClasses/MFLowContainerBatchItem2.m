//
//  MFLowContainerBatchItem2.m
//  MercuryCoreLib
//
//  Created by Joseph Ridenour on 11/30/10.
//  Copyright 2010 Mercury Intermedia. All rights reserved.
//

#import "MFLowContainerBatchItem2.h"
#import "MFlowContainer.h"
#import "MFlowFileManager.h"


NSString * const kBatchProgress2 = @"kBatchProgress";


@implementation MFLowContainerBatchItem2

#ifdef NS_BLOCKS_AVAILABLE
@synthesize callbackHandler = _callbackHandler;
#endif
@synthesize delegate = _delegate;
@synthesize title = _title;
@synthesize subtitle = _subtitle;
@synthesize containerID = _containerID;
@synthesize imageItemPaths = _imageItemPaths;
@synthesize filegroup = _filegroup;


#pragma mark - Initialize

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


- (void)main{
    
#ifdef NS_BLOCKS_AVAILABLE
    if(self.callbackHandler) {
        self.callbackHandler(self, MFlowBatchPhaseContainerStart);
    } else {
        if(self.delegate && [self.delegate respondsToSelector:@selector(dispatchStatusUpdateForItem:withObject:)]) {
            [self.delegate dispatchStatusUpdateForItem:MFlowBatchPhaseContainerStart withObject:self];
        }
    }
#else
	[self.delegate dispatchStatusUpdateForItem:MFlowBatchPhaseContainerStart withObject:self];
#endif
    
	MFlowContainer *c = [[MFlowContainer alloc] initWithContainerID:self.containerID useDiskCache:true];
	c.compressionMode = @"";
	[c updateContentsSynchronously:nil];
	
	if ([self isCancelled]) {
        NSLog(@"CANCELLED ITEM1 %@ %i", self.title, self.containerID);
		return;
	}
	
	if (self.imageItemPaths != nil && [self.imageItemPaths compare:@""] != NSOrderedSame) 
    {
		NSArray *imageItems = [self getImageItemsFromData:c.data withPaths:self.imageItemPaths];
		
		for (MFlowItem *image in imageItems) {
			
			if (image.count > 0) 
            {
				[[MFlowFileManager sharedMFlowFileManager] retrieveMFlowFileToCache:image filegroup:self.filegroup];
			}
			
			if ([self isCancelled]) 
            {
                NSLog(@"CANCELLED ITEM2 %@ %i", self.title, self.containerID);
				return;
			}
		}
	}
	

#ifdef NS_BLOCKS_AVAILABLE
    if(self.callbackHandler) 
    {
        self.callbackHandler(self, MFlowBatchPhaseContainerEnd);
        _callbackHandler = nil;
    } 
    else 
    {
        if(self.delegate && [self.delegate respondsToSelector:@selector(dispatchStatusUpdateForItem:withObject:)]) {
            [self.delegate dispatchStatusUpdateForItem:MFlowBatchPhaseContainerEnd withObject:self];
        }
    }
#else
	[self.delegate dispatchStatusUpdateForItem:MFlowBatchPhaseContainerEnd withObject:self];
#endif
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


-(void)dealloc{
    //NSLog(@"Dealloc batch operation %i", _containerID);
#ifdef NS_BLOCKS_AVAILABLE
    if(_callbackHandler) _callbackHandler = nil;
#endif
}

@end
