//
//  MFlowFileServicesOperation.m
//  ArchTest1
//
//  Created by Stephen Tallent on 12/20/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import "MFlowFileServicesOperation.h"
#import "MFlowFileManager.h"
#import "TC_NSDateExtensions.h"

@implementation MFlowFileServicesOperation

-(id)initWithDays:(NSInteger)days cachePath:(NSString *)cPath{
    
	self = [super init];
	
	expirationDays = days;
	
	cachePath = [cPath copy];
	
	return self;
}

-(void)main{
	if ([self isCancelled]) {
		return;
	}
	
	// First lets check for out of date files
	NSString *filePath;
	NSDictionary *fileAttributes;
	NSString *fileType;
	NSDate *fileModDate;
	NSError *error;
	NSFileManager* fm = [[NSFileManager alloc] init];
	NSTimeInterval fileExpiredInterval = expirationDays * 24.0 * 60.0 * 60.0;
	
	NSArray *paths = [fm subpathsOfDirectoryAtPath:cachePath error:&error];
	
	
	for (NSString *p in paths) {
	
		filePath = [cachePath stringByAppendingPathComponent:p];
		
		fileAttributes = [fm attributesOfItemAtPath:filePath error:&error];

		fileType = [fileAttributes objectForKey:NSFileType];
		
		if (fileType == NSFileTypeRegular) {
			
			fileModDate = [fileAttributes objectForKey:NSFileModificationDate];
		
			if ([[NSDate gregorianDate] timeIntervalSinceDate:fileModDate] > fileExpiredInterval) {
				[fm removeItemAtPath:filePath error:&error];
			}
			
		}
		
		if ([self isCancelled]) {
			break;
		}
		
	}
	
	[[MFlowFileManager sharedMFlowFileManager] performSelectorOnMainThread:@selector(updateCleanupTimestamp) withObject:nil waitUntilDone:true];
}



@end
