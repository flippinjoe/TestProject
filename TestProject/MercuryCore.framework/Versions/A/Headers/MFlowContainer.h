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
/** THESE WERE USED IN OLD PARSING, NOW HANDLED IN MFLOWCONTAINER PARSER
@class CXMLDocument;
@class CXMLNode;
@class CXMLElement;
 */

@interface MFlowContainer : NSObject {
	
	int containerID;
//	bool useDiskCache;
    BOOL canceled;
	
	bool notifyAfterUpdate;
	
//	NSString *diskCachePath;
	NSString *compressionMode;
	
//	bool contentsChanged;
	MFlowContainerResponseStatus containerStatus;
	
	id<MFlowContainerDelegate> delegate;
	
//	MFlowContainerData* mflowData;
	
	NSInteger numNewItems;
	
	NSArray *data;
	
    /** DEPREICATED TO DECOUPLE ERROR FROM CONTAINER
	NSError *error;
	*/
    
    /** REMOVED BECAUSE THEY AREN'T EVER USED
	NSTimeInterval totalTime;
	NSTimeInterval parseTime;
     */
}

@property (nonatomic) BOOL canceled;

@property(nonatomic, assign) id<MFlowContainerDelegate>delegate;
@property(nonatomic, retain) NSString *compressionMode;
@property(nonatomic, readonly) bool dataStale;
@property(nonatomic, readonly) int containerID;
@property(nonatomic, retain) NSArray *data;
@property(nonatomic, readonly) NSDate *dataRetrievalDate;
@property(nonatomic, assign) NSInteger numNewItems;
@property(nonatomic, assign) dispatch_queue_t responseQueue;
/*
@property(nonatomic, readonly) NSTimeInterval parseTime;
@property(nonatomic, readonly) NSTimeInterval totalTime;
 */
@property (nonatomic, copy) MFlowContainerUpdatedBlock updateBlock;
@property (nonatomic, readonly) BOOL contentsChanged;

@property (nonatomic, readonly) NSString *diskCachePath;

// adding accessor for mflowData for testing
@property (nonatomic, readonly) MFlowContainerData *mflowData;

+ (NSString *)diskCachePathWithContainerID:(NSInteger)aContainerID;

+(id)containerWithContainerID:(int)containerID;
+(id)containerWithContainerID:(int)containerID useDiskCache:(bool)uc;

-(id)initWithContainerID:(int)containerID;
-(id)initWithContainerID:(int)containerID useDiskCache:(bool)uc;

-(void)getContents;

-(void)checkContents;
-(BOOL)updateContentsSynchronously:(NSError **)error;
-(void)parseData:(NSData*)containerData;

//-(MFlowContainerResponseStatus)getContainerStatus:(CXMLDocument *)doc;
//-(bool)getContainerCompressionState:(CXMLDocument *)doc;
//-(CXMLDocument*)getDocFromCompressedData:(NSString*)guts;
//-(NSArray*) getSortedRelationNodes:(CXMLNode*)doc;
//-(NSDictionary*)convertItems:(CXMLNode *)itemsDoc;
//-(MFlowItem*)convertItem:(CXMLElement *)itemNode;

/**
 Updates a container and passes success, contentsChanged and any error encountered to the handler.
 @param handler MFlowContainerUpdatedBlock to update after the update is complete or when it encounters an error.
 */
- (void)updateWithHandler:(MFlowContainerUpdatedBlock)handler;

@end
