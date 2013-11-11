//
//  MFlowFileOperation.m
//  ArchTest1
//
//  Created by Stephen Tallent on 12/18/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import "MFlowFileOperation.h"
#import "MFlowFileManager.h"
#import "TC_NSDateExtensions.h"

#import "MFlowNetworkActivityManager.h"

@interface MFlowFileOperation ()
@property (nonatomic, weak, readwrite) id delegate;
@end

@implementation MFlowFileOperation

@synthesize delegate = _delegate;

-(id) initWithURL:(NSString *)fullURL 
	  pleaseCache:(BOOL)pleaseCache 
	cacheFilename:(NSString *)cacheFilename 
	cacheFilepath:cacheFilepath
		filegroup:(NSString *)filegroup 
		  isImage:(BOOL)isImage 
		 delegate:(id)delegate{
	
	
	_fullURL = [fullURL copy];
	_pleaseCache = pleaseCache;
	_cacheFilename = [cacheFilename copy];
	_cacheFilepath = [cacheFilepath copy];
	_cacheFullPath = [_cacheFilepath stringByAppendingPathComponent:_cacheFilename];
	_filegroup = [filegroup copy];
	_isImage = isImage;
	_delegate = delegate;
	
	return [super init];
	
}


-(void)main{
	
	if ([self isCancelled]) {
		[self finish];
		return;
	} 
    
	NSData *fileData = nil;
    UIImage *imageData = nil;
	BOOL fileOnDisk = false;
	
	// lets first see if file exists on disk
    if (_isImage)
        imageData = [UIImage imageWithContentsOfFile:_cacheFullPath];
    else
        fileData = [NSData dataWithContentsOfFile:_cacheFullPath];
	
	// if not, download
	if (fileData == nil && imageData == nil) {
		
		//NSLog(@"%@",_fullURL);
		
		fileOnDisk = false;
        
        [[MFlowNetworkActivityManager sharedInstance] incrementActivityCount];
		fileData = [NSData dataWithContentsOfURL:[NSURL URLWithString:_fullURL]];
        [[MFlowNetworkActivityManager sharedInstance] decrementActivityCount];
        
		if (fileData != nil && fileData.length > 0) {
            if (_isImage) {
                imageData = [UIImage imageWithData:fileData];
            }
		}
		
	} else {
		
		fileOnDisk = true;
		
	}
	
	
	if ([self isCancelled]) {
		
		[self finish];
		//return;
	}
	
	
	if (_pleaseCache && fileData != nil) {
        
		
		if (fileOnDisk) {
			
			//write code to touch modification date
			NSFileManager* fm = [[NSFileManager alloc] init];
			
			if ([fm fileExistsAtPath:_cacheFullPath]) {
				
				// TMT 072910 replaced deprecated method changeFileAttributes:atPath:
				
				NSError *error = nil;
				
				NSDate* modifiedDate = [NSDate gregorianDate];
				
				NSDictionary* attrs = [NSDictionary dictionaryWithObject:modifiedDate forKey:NSFileModificationDate];
				
				BOOL modified = [[NSFileManager defaultManager] setAttributes:attrs ofItemAtPath:_cacheFullPath error:&error];
				
				if (!modified){
					
					NSLog(@"failed to create cache error: %@",error);
                    
				}
                
                
			}
			
			
		} else {
			
			if (fileData != nil) {
                
				[fileData writeToFile:_cacheFullPath atomically:true];
                
			}
			
		}
		
		[self performSelectorOnMainThread:@selector(notifyCacheReady) withObject:nil waitUntilDone:true];
        
        if (_isImage) 
            [[MFlowFileManager sharedMFlowFileManager] putFileInMemCache:imageData filegroup:_filegroup cacheKey:_cacheFilename];
        else
            [[MFlowFileManager sharedMFlowFileManager] putFileInMemCache:fileData filegroup:_filegroup cacheKey:_cacheFilename];
        
	}
	
    //now lets do the notification
    // moved this to the last part of main so any caching is done first
    // DAM 041812 don't notify the delegate if we cancelled the operation.
    if (![self isCancelled]) {
        if (_isImage)
            [self performSelectorOnMainThread:@selector(notify:) withObject:imageData waitUntilDone:true];
        else
            [self performSelectorOnMainThread:@selector(notify:) withObject:fileData waitUntilDone:true];
        
        [self finish];        
    }
}

-(void) finish{
    
	[[MFlowFileManager sharedMFlowFileManager] performSelectorOnMainThread:@selector(opDoneForKey:) withObject:_cacheFilename waitUntilDone:true];
	
}

-(void)notify:(id)data{
	
	// TODO: TMT 080210 I think this isn't thread safe, should probablt be called on main thread
	// but it needs to take only one argument to use performSelectorOnMainThread:withObject:waitUntilDone:
	
	if (_isImage) {
		[[MFlowFileManager sharedMFlowFileManager] notifyImageReady:(UIImage *)data url:_fullURL delegate:_delegate];
	} else {
		[[MFlowFileManager sharedMFlowFileManager] notifyFileReady:(NSData *)data url:_fullURL delegate:_delegate];
	}
	
}

//-(void)notifyCacheReady:(NSString *)url diskPath:(NSString *)dPath delegate:(id)delegate

-(void)notifyCacheReady{
	[[MFlowFileManager sharedMFlowFileManager] notifyCacheReady:_fullURL diskPath:_cacheFullPath delegate:_delegate];
}


@end
