//
//  MFlowFileOperation.h
//  ArchTest1
//
//  Created by Stephen Tallent on 12/18/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MFlowFileOperation : NSOperation {
	
	NSString *_fullURL;
	BOOL _pleaseCache;
	NSString *_cacheFilename;
	NSString *_cacheFilepath;
	NSString *_cacheFullPath;
	NSString *_filegroup;
	BOOL _isImage;
		
}

@property (weak, nonatomic, readonly) id delegate;

-(id) initWithURL:(NSString *)fullURL 
	  pleaseCache:(BOOL)pleaseCache 
	cacheFilename:(NSString *)cacheFilename
	cacheFilepath:cacheFilepath
		filegroup:(NSString *)filegroup 
		  isImage:(BOOL)isImage 
		 delegate:(id)delegate;


-(void)notifyCacheReady;

-(void)finish;

@end
