//
//  MFlowContainer.h
//  MercuryCoreDev
//
//  Created by Stephen Tallent on 5/11/09.
//  Copyright 2009 Stephen. All rights reserved.
//

#import <Foundation/Foundation.h>



typedef void(^MFlowContainerUpdatedBlock)(BOOL success, BOOL contentsChanged, NSError *updateError);

extern NSString * const kMFlowContainerUpdated;
extern NSString * const kMFlowContainerError;
extern NSString * const MFlowContainerErrorDomain;

enum {
    MFlowContainerServerResponseError = 1500,
};


typedef enum {
    MFlowContainerResponseFull,
    MFlowContainerResponseUnchanged,
    MFlowContainerResponseDelta,
	MFlowContainerResponseError
} MFlowContainerResponseStatus;

@class MFlowContainer;
@class MFlowItem;

@protocol MFlowContainerDelegate <NSObject>

- (void)containerUpdated:(MFlowContainer *)container contentsChanged:(BOOL)contentsChanged;
- (void)containerErrorReceived:(MFlowContainer *)container error:(NSError *)error;

@end

@class MFlowContainerData;

@interface MFlowContainer : NSObject {
	int containerID;
    BOOL canceled;
	bool notifyAfterUpdate;
	NSString *compressionMode;
	MFlowContainerResponseStatus containerStatus;
	id<MFlowContainerDelegate> delegate;
	NSInteger numNewItems;
	NSArray *data;
}

@property (nonatomic, assign, readwrite) BOOL canceled;
@property (nonatomic, weak, readwrite) id<MFlowContainerDelegate>delegate;
@property (nonatomic, copy, readwrite) NSString *compressionMode;
@property (nonatomic, assign, readonly) bool dataStale;
@property (nonatomic, assign, readonly) int containerID;
@property (nonatomic, strong, readwrite) NSArray *data;
@property (nonatomic, strong, readonly) NSDate *dataRetrievalDate;
@property (nonatomic, assign, readonly) NSInteger numNewItems;
@property (nonatomic, assign, readonly) dispatch_queue_t responseQueue;
@property (nonatomic, copy, readwrite) MFlowContainerUpdatedBlock updateBlock;
@property (nonatomic, assign, readonly) BOOL contentsChanged;
@property (nonatomic, copy, readonly) NSString *diskCachePath;
@property (nonatomic, strong, readonly) MFlowContainerData *mflowData;

+ (NSString *)diskCachePathWithContainerID:(NSInteger)aContainerID;

+(id)containerWithContainerID:(int)containerID;
+(id)containerWithContainerID:(int)containerID useDiskCache:(bool)uc;

-(id)initWithContainerID:(int)containerID;
-(id)initWithContainerID:(int)containerID useDiskCache:(bool)uc;

-(void)getContents;

-(void)checkContents;
-(BOOL)updateContentsSynchronously:(NSError **)error;
- (BOOL)parseData:(NSData *)containerData error:(NSError * __autoreleasing *)error;

/**
 Updates a container and passes success, contentsChanged and any error encountered to the handler.
 @param handler MFlowContainerUpdatedBlock to update after the update is complete or when it encounters an error.
 */
- (void)updateWithHandler:(MFlowContainerUpdatedBlock)handler;

@end
