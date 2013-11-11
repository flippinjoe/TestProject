//
//  MFlowFile.h
//  USAToday1
//
//  Created by Stephen Tallent on 11/7/08.
//  Copyright 2008 Mercury Intermedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import "MFlowItem.h"

#define mflowFileCleanupLastRun @"mflowFileCleanupLastRun"
#define defaultFileGroup @"GeneralFileGroup"

@protocol MFlowFileManagerDelegate

@optional

- (void)fileManagerImageReady:(NSString *)fullURL image:(UIImage *)img;
- (void)fileManagerImageError:(NSString *)fullURL;

- (void)fileManagerFileCacheReady:(NSString *)fullURL diskPath:(NSString *)diskPath;

- (void)fileManagerFileReady:(NSString *)fullURL fileContents:(NSData *)fileContents;
- (void)fileManagerFileError:(CFStreamError)error;

@end


@interface MFlowFileManager : NSObject{
	
	NSString *cacheDataPathZ;
	NSMutableDictionary *memCaches;
	NSMutableDictionary *queues;
	NSMutableDictionary *ops;
	
	NSInteger filesExpireAfterDays;
	NSInteger waitDaysBetweenCleanup;

	//-----------------
	
	NSString *documentsDirectory;
	NSString *cacheDataPath;
	
	NSMutableDictionary *cache;
	NSMutableDictionary *dirExistsCache;
	NSMutableDictionary *memCache;
	
	NSMutableArray *socketArray;
	
}

+(MFlowFileManager*) sharedMFlowFileManager;

+(id) initFileManagerWithExpirationDays:(NSInteger)days daysBetweenCleanup:(NSInteger)cleanupDays;

-(id) initFileManagerWithExpirationDays:(NSInteger)days daysBetweenCleanup:(NSInteger)cleanupDays;


/** JOE: 9/18/12
 *  Commenting out since it's declared 3 lines up
 *  
 *  -(id) initFileManagerWithExpirationDays:(NSInteger)days daysBetweenCleanup:(NSInteger)cleanupDays;
 **/

//-(void) initOldStuff;
-(void) updateCleanupTimestamp;

//--------------------

-(NSString *)getResizedImagePath:(MFlowItem *)item;
-(NSString *)imageURLWithMFlowItem:(MFlowItem *)item;

-(NSString *)getMFlowItemPath:(MFlowItem *)item __attribute__((deprecated("use imageURLWithMFlowItem instead")));

-(void) retrieveMFlowImage:(MFlowItem *)item 
			  pleaseCache:(BOOL)pleaseCache 
				  delegate:(id<MFlowFileManagerDelegate>)delegate;

-(void) retrieveMFlowImage:(MFlowItem *)item 
			   pleaseCache:(BOOL)pleaseCache  
				 filegroup:(NSString *)filegroup
				  delegate:(id<MFlowFileManagerDelegate>)delegate;

-(void) retrieveImage:(NSString *)fullURL 
		  pleaseCache:(BOOL)pleaseCache
			filegroup:(NSString *)filegroup
			 delegate:(id<MFlowFileManagerDelegate>)delegate;


-(void) retrieveImage:(NSString *)fullURL 
		  pleaseCache:(BOOL)pleaseCache 
		cacheFilename:(NSString *)cacheFilename
			filegroup:(NSString *)filegroup
			 delegate:(id<MFlowFileManagerDelegate>)delegate;


-(void) retrieveFile:(NSString *)fullURL 
		 pleaseCache:(BOOL)pleaseCache 
		   filegroup:(NSString *)filegroup
			delegate:(id<MFlowFileManagerDelegate>)delegate;

-(void) retrieveFile:(NSString *)fullURL 
		 pleaseCache:(BOOL)pleaseCache 
	   cacheFilename:(NSString *)cacheFilename
		   filegroup:(NSString *)filegroup
			 isImage:(BOOL)isImage
			delegate:(id<MFlowFileManagerDelegate>)delegate;


-(void)retrieveMFlowFileToCache:(MFlowItem *)item
					filegroup:(NSString *)grp;

-(NSString *)fileExistsInCache:(MFlowItem *)item
					 filegroup:(NSString *)grp;

-(UIImage *) retrieveMFlowImageSynchronously:(MFlowItem *)item;
-(UIImage *)imageFromCache:(MFlowItem *)item
				 filegroup:(NSString *)filegroup;

-(NSOperationQueue *)queueForFilegroup:(NSString *)name;
-(NSMutableDictionary *)memCacheForFilegroup:(NSString *)name;
-(NSString *)cacheKeyForURL:(NSString*)URL;
-(NSString *)cacheKeyForMFlowItem:(MFlowItem *)item;

-(void)freeMemCacheForFilegroup:(NSString *)group;
-(void)freeAllMemCaches;

-(void)putFileInMemCache:(id)data filegroup:(NSString *)filegroup cacheKey:(NSString *)cacheKey;
-(void)cancelMFlowImage:(MFlowItem *)item;
-(void)cancelImage:(NSString *)fullURL;
-(void)opDoneForKey:(NSString *)key;
-(void)cancelFilegroup:(NSString *)group;

-(void)notifyImageReady:(UIImage *)img url:(NSString *)url delegate:(id)delegate;
-(void)notifyFileReady:(NSData *)data url:(NSString *)url delegate:(id)delgate;
-(void)notifyCacheReady:(NSString *)url diskPath:(NSString *)dPath delegate:(id)delegate;

-(void)validateDirectory:(NSString *)path;

@property (nonatomic, assign) BOOL cacheImagesInMemory;

//--------------------

/*-(void)retrieveMFlowFile:(NSDictionary *)fileDict 
			 pleaseCache:(BOOL)pleaseCache 
				delegate:(id<MFlowFileManagerDelegate>)delegate;

-(void)retrieveMFlowFile:(NSDictionary *)fileDict 
			 pleaseCache:(BOOL)pleaseCache 
				delegate:(id<MFlowFileManagerDelegate>)delegate 
			 memCacheKey:(NSString *)memCacheKey;

-(void)retrieveFile:(NSString *)fullURL 
	  cacheFilename:(NSString *)cacheFilename 
		   cacheDir:(NSString *)cacheDir
		pleaseCache:(BOOL)pleaseCache 
		   delegate:(id<MFlowFileManagerDelegate>)delegate 
		memCacheKey:(NSString *)memCacheKey;

*/
//-(void)putGutsInMemCache:(NSString *)memCacheKey fileCacheKey:(NSString *)fileCacheKey guts:(NSData *)guts;
//-(NSData *)getGutsFromMemCache:(NSString *)memCacheKey fileCacheKey:(NSString *)fileCacheKey;
//-(void)clearMemKeyForKey:(NSString *)memCacheKey;
//-(void)saveCacheToDisk;


@end
