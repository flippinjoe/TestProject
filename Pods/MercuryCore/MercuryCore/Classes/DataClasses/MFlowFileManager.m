//
//  MFlowFile.m
//  USAToday1
//
//  Created by Stephen Tallent on 11/7/08.
//  Copyright 2008 Mercury Intermedia. All rights reserved.
//

#import "MFlowFileManager.h"
#import "MFlowConfig.h"
#import "MFlowFileOperation.h"
#import "MFlowFileServicesOperation.h"
#import "TC_NSDateExtensions.h"
#import "MFlowNetworkActivityManager.h"

#define kBaseFilegroup @"mflowBaseGroup"
#define numConcurrentThreads 6
#define defaultExpirationDays 7
#define defaultCleanupDays 3

@interface MFlowFileManager ()
@property (nonatomic, strong) NSOperationQueue *fileDownloadOperationQueue;
@end

@implementation MFlowFileManager

@synthesize cacheImagesInMemory = _cacheImagesInMemory;
@synthesize fileDownloadOperationQueue = _fileDownloadOperationQueue;

static MFlowFileManager *_instance;


+(MFlowFileManager*) sharedMFlowFileManager {
		
	if (_instance == nil){
		
		[NSException raise:@"MFlowFileManager not initialized" format:@"please init filemanager before use"];
		return nil;
	
	}
	
	return _instance;

}

+(id) init{
	
	return [MFlowFileManager initFileManagerWithExpirationDays:defaultExpirationDays daysBetweenCleanup:defaultCleanupDays];
}


+(id) initFileManagerWithExpirationDays:(NSInteger)days daysBetweenCleanup:(NSInteger)cleanupDays{
	
	_instance = [[MFlowFileManager alloc] initFileManagerWithExpirationDays:days daysBetweenCleanup:cleanupDays];
	
	//[_instance initOldStuff];
	
	return _instance;

}


-(id) initFileManagerWithExpirationDays:(NSInteger)days daysBetweenCleanup:(NSInteger)cleanupDays{
	
	self = [super init];
	
	filesExpireAfterDays = days;
	waitDaysBetweenCleanup = cleanupDays;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, 
														 NSUserDomainMask, YES); 
	NSString *docs = [paths objectAtIndex:0]; 
	
	cacheDataPathZ = [docs stringByAppendingPathComponent:@"mflowImageCache2"];

	[self validateDirectory:cacheDataPathZ];
	
	queues = [NSMutableDictionary dictionaryWithCapacity:0];
	memCaches = [NSMutableDictionary dictionaryWithCapacity:0];
	ops = [NSMutableDictionary dictionaryWithCapacity:0];
	
	
	// Lets see if its been long enough to run the cleanup script
	
	NSDate *lastCheck = [[NSUserDefaults standardUserDefaults] objectForKey:mflowFileCleanupLastRun];
	if (lastCheck != nil) {
		
		//NSLog(@"checking interval...");
		NSTimeInterval intervalSinceLastCleanup = [[NSDate gregorianDate] timeIntervalSinceDate:lastCheck];
		
		if (intervalSinceLastCleanup > (waitDaysBetweenCleanup * 24 * 60 * 60)){
			
			MFlowFileServicesOperation *op = [[MFlowFileServicesOperation alloc] initWithDays:filesExpireAfterDays cachePath:cacheDataPathZ];
			//[serviceOpsQueue addOperation:op];
			[[MFlowConfig sharedInstance].serviceOpsQueue addOperation:op];
		
		}
											
	} else {
		//NSLog(@"interval never set.  lets set it");
		// this will only be nil the first time the app runs, so lets stamp it so it can do a time check on subsequent runs
		[self updateCleanupTimestamp];
	}

	//--
	
	return self;
	
}

- (NSString *)getResizedImagePath:(MFlowItem *)item{
	
	NSString *tags = [item objectForKey:@"Tags"];
    
    NSArray *allTags = [[tags lowercaseString] componentsSeparatedByString:@"|"];
    
    
    BOOL foundTag = NO;
    for(NSString *tag in allTags)
    {
        if([tag isEqualToString:[[[MFlowConfig sharedInstance] impKey] lowercaseString]])
        {
            foundTag = YES;
            break;
        }
    }
    
    if(foundTag) {
        return [NSString stringWithFormat:@"%@%@/%@",[item objectForKey:@"BaseURL"],[MFlowConfig sharedInstance].impKey,[item objectForKey:@"Filename"]];
    }
    else {
        return [item objectForKey:@"FullURL"];
    }
}

-(NSString *)imageURLWithMFlowItem:(MFlowItem *)item
{
	NSString *url = nil;
	
	if ([item.TypeID integerValue] == [[MFlowConfig sharedInstance] resizedImageTypeID]) {
		url = [self getResizedImagePath:item];
	} else {
		url = [item objectForKey:@"FullURL"];
	}
	
	if (url != nil) {
		NSString	*testURL = [url stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
		
		if ([testURL isEqualToString: url])		// test to see if string needs escaping
			url = [url stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	}
	
	return url;
}

-(NSString *)getMFlowItemPath:(MFlowItem *)item 
{
	NSString *url = nil;
	
	if ([item.TypeID integerValue] == [MFlowConfig resizedImageTypeID]) {
		url = [self getResizedImagePath:item];
	} else {
		url = [item objectForKey:@"FullURL"];
	}
	
	if (url != nil)
		url = [url stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	
	return url;
}

-(void) retrieveMFlowImage:(MFlowItem *)item 
			  pleaseCache:(BOOL)pleaseCache 
				 delegate:(id<MFlowFileManagerDelegate>)delegate{
	
	[self retrieveMFlowImage:item pleaseCache:pleaseCache filegroup:kBaseFilegroup delegate:delegate];
}

-(void) retrieveMFlowImage:(MFlowItem *)item 
			   pleaseCache:(BOOL)pleaseCache  
				 filegroup:(NSString *)filegroup
				  delegate:(id<MFlowFileManagerDelegate>)delegate {
	
	if (![item isKindOfClass:[MFlowItem class]]) {
		return;
	}

	NSString *cacheKey = [self cacheKeyForMFlowItem:item];
	NSString *url = [self imageURLWithMFlowItem: item];
	
	[self retrieveImage:url
			pleaseCache:pleaseCache
		  cacheFilename:cacheKey
			  filegroup:filegroup
			   delegate:delegate];
	
}


-(UIImage *) retrieveMFlowImageSynchronously:(MFlowItem *)item {
    if (![item isKindOfClass:[MFlowItem class]]) {
		return nil;
	}
	
	NSString *url = [self imageURLWithMFlowItem: item];

    if(url) {
        [[MFlowNetworkActivityManager sharedInstance] incrementActivityCount];
        NSData *fileData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
		[[MFlowNetworkActivityManager sharedInstance] decrementActivityCount];
        
        if (fileData != nil && fileData.length > 0) {
            return [UIImage imageWithData:fileData] != nil ? [UIImage imageWithData:fileData] : nil;
		}
    }
    return nil;
}

-(void) retrieveImage:(NSString *)fullURL 
		  pleaseCache:(BOOL)pleaseCache
			filegroup:(NSString *)filegroup
			 delegate:(id<MFlowFileManagerDelegate>)delegate {
	
	[self retrieveImage:fullURL 
			pleaseCache:pleaseCache 
		  cacheFilename:[self cacheKeyForURL: fullURL] 
			  filegroup:filegroup 
			   delegate:delegate];
	
}

-(void) retrieveImage:(NSString *)fullURL 
		  pleaseCache:(BOOL)pleaseCache 
		cacheFilename:(NSString *)cacheFilename
			filegroup:(NSString *)filegroup
			 delegate:(id<MFlowFileManagerDelegate>)delegate {
	
	[self retrieveFile:fullURL 
		   pleaseCache:pleaseCache 
		 cacheFilename:cacheFilename 
			 filegroup:filegroup 
			   isImage:true 
			  delegate:delegate];
	
}

-(void) retrieveFile:(NSString *)fullURL 
		 pleaseCache:(BOOL)pleaseCache 
		   filegroup:(NSString *)filegroup
			delegate:(id<MFlowFileManagerDelegate>)delegate{
	
	[self retrieveFile:fullURL 
		   pleaseCache:pleaseCache 
		 cacheFilename:[self cacheKeyForURL:fullURL]
			 filegroup:filegroup
			   isImage:false 
			  delegate:delegate];
	
}

-(void) retrieveFile:(NSString *)fullURL 
		 pleaseCache:(BOOL)pleaseCache 
	   cacheFilename:(NSString *)cacheFilename
		   filegroup:(NSString *)filegroup
			 isImage:(BOOL)isImage
			delegate:(id<MFlowFileManagerDelegate>)delegate {

	NSMutableDictionary *c = [self memCacheForFilegroup:filegroup];
	
	id cacheData = [c objectForKey:cacheFilename];
    
	if (cacheData != nil) {
		if (isImage) {
			[self notifyImageReady:(UIImage *)cacheData url:fullURL delegate:delegate];
		} else {
			[self notifyFileReady:(NSData *)cacheData url:fullURL delegate:delegate];
		}
		return;
	}

    
    // so this is kind of nuts, if you have say 10 file groups, and you spin up a thread for 6 each everything slows down.
    // I'd like to take this down to one queue so we don't have a thread explosion, but that is causing delays in image loading
    
    NSOperationQueue *q = [self queueForFilegroup:filegroup];
    
//    if(self.fileDownloadOperationQueue == nil)
//    {
//        self.fileDownloadOperationQueue = [[[NSOperationQueue alloc] init] autorelease];
//        [self.fileDownloadOperationQueue setMaxConcurrentOperationCount:numConcurrentThreads];
//    }
    
	MFlowFileOperation *op = [[MFlowFileOperation alloc] initWithURL:fullURL 
														  pleaseCache:pleaseCache 
														cacheFilename:cacheFilename
														cacheFilepath:[cacheDataPathZ stringByAppendingPathComponent:filegroup]
															filegroup:filegroup
															  isImage:isImage 
															 delegate:delegate];
	    
	[ops setObject:op forKey:cacheFilename];
	
//	[self.fileDownloadOperationQueue addOperation:op];
    [q addOperation:op];
	

}

-(void)retrieveMFlowFileToCache:(MFlowItem *)item
					filegroup:(NSString *)grp{

	if (![item isKindOfClass:[MFlowItem class]]) {
		return;
	}
	
	NSString *cacheKey = [self cacheKeyForMFlowItem:item];
	NSString *filegroup = (grp == nil) ? kBaseFilegroup : grp;
	NSString *fullPathToDir = [cacheDataPathZ stringByAppendingPathComponent:filegroup];
	NSString *fullPathToFile =[fullPathToDir stringByAppendingPathComponent:cacheKey];
	NSString *url = [self imageURLWithMFlowItem: item];

	NSFileManager* fm = [[NSFileManager alloc] init];
	
	[self validateDirectory:fullPathToDir];
	
	if ([fm fileExistsAtPath:fullPathToFile]) {
		
		return;
		
	} else {
		
        [[MFlowNetworkActivityManager sharedInstance] incrementActivityCount];
		NSData *fileData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
		[[MFlowNetworkActivityManager sharedInstance] decrementActivityCount];
        [fileData writeToFile:fullPathToFile atomically:true];
	}

	
}

-(NSString *)fileExistsInCache:(MFlowItem *)item
					 filegroup:(NSString *)grp{
	
	if (![item isKindOfClass:[MFlowItem class]]) {
		return nil;
	}
	
	NSString *cacheKey = [self cacheKeyForMFlowItem:item];
	NSString *filegroup = (grp == nil) ? kBaseFilegroup : grp;
	NSString *fullPathToDir = [cacheDataPathZ stringByAppendingPathComponent:filegroup];
	NSString *fullPathToFile =[fullPathToDir stringByAppendingPathComponent:cacheKey];
	
	NSFileManager* fm = [[NSFileManager alloc] init];
	
	[self validateDirectory:fullPathToDir];
	
	if ([fm fileExistsAtPath:fullPathToFile]) {
		
		return fullPathToFile;
		
	} else {
		
		return nil;
	}

	
}

-(UIImage *)imageFromCache:(MFlowItem *)item
				 filegroup:(NSString *)filegroup{
	
	// lets first verify its a real image
	bool is = [item isKindOfClass:[MFlowItem class]];
	if (!is ||!self.cacheImagesInMemory) {
		return nil;
	}
	
	NSString *cacheKey = [self cacheKeyForMFlowItem:item];
	
	NSMutableDictionary *c = [self memCacheForFilegroup:filegroup];
	
	id cacheData = [c objectForKey:cacheKey];

	if (cacheData != nil) { 
		return (UIImage *)cacheData;
	}
	
	NSString *path = [self fileExistsInCache:item filegroup:filegroup];
	
	if (path == nil) return nil;
	
	UIImage *img = [UIImage imageWithContentsOfFile:path];
	
	if (img != nil) {
		[self putFileInMemCache:img filegroup:filegroup cacheKey:cacheKey];	
	} else {
		//TODO : add some code that will delete this corrupted file from disk
		// if img happens to be null
	}

	
	return img;
}


-(void)cancelMFlowImage:(MFlowItem *)item{
	
	if (![item isKindOfClass:[MFlowItem class]]) {
		return;
	}
	
	NSString *key = [self cacheKeyForMFlowItem:item];
	NSOperation *op = [ops objectForKey:key];
	if (op != nil) {
		[op cancel];
		//NSLog(@"cancelMFlowImage: %@, isReady:%i isExecuting%i isFinished:%i", item.ItemName, [op isReady], [op isExecuting], [op isFinished]);
	}
}

-(void)cancelImage:(NSString *)fullURL{
	NSString *key = [self cacheKeyForURL:fullURL];
	NSOperation *op = [ops objectForKey:key];
	if (op != nil) {
		[op cancel];
		//NSLog(@"cancelMFlowImage: isReady:%i isExecuting%i isFinished:%i", [op isReady], [op isExecuting], [op isFinished]);
	}
}

-(void)cancelFilegroup:(NSString *)group{
	
	NSOperationQueue *q = [self queueForFilegroup:group];
	if (q != nil) {
		[q cancelAllOperations];
	}
}

-(void)opDoneForKey:(NSString *)key{

	[ops removeObjectForKey:key];

}

-(void)putFileInMemCache:(id)data filegroup:(NSString *)filegroup cacheKey:(NSString *)cacheKey{
	
	if(nil == data || !self.cacheImagesInMemory) {
		return;
	}
	
	NSMutableDictionary *c = [self memCacheForFilegroup:filegroup];
	
	if ([c objectForKey:cacheKey] != nil) {
		return;
	}
	
	@synchronized(c){
		[c setObject:data forKey:cacheKey];
	}
    
}

-(void)notifyImageReady:(UIImage *)img url:(NSString *)url delegate:(id)delegate{

	if (delegate != nil && img != nil && [delegate respondsToSelector:@selector(fileManagerImageReady:image:)]){
		[delegate fileManagerImageReady:url image:img];
		return;
	}
	
	if (delegate != nil && img == nil && [delegate respondsToSelector:@selector(fileManagerImageError:)]) {
		[delegate fileManagerImageError:url];
	}
	
}

-(void)notifyFileReady:(NSData *)data url:(NSString *)url delegate:(id)delegate{
	
	if (delegate != nil && [delegate respondsToSelector:@selector(fileManagerFileReady:fileContents:)]){
		[delegate fileManagerFileReady:url fileContents:data];
	}
	
}

-(void)notifyCacheReady:(NSString *)url diskPath:(NSString *)dPath delegate:(id)delegate{
	if (delegate != nil && [delegate respondsToSelector:@selector(fileManagerFileCacheReady:diskPath:)]){
		[delegate fileManagerFileCacheReady:url diskPath:dPath];
	}

}


-(void)freeMemCacheForFilegroup:(NSString *)group{

	[memCaches removeObjectForKey:group];

}

-(void)freeAllMemCaches{
	
	for (NSString *k in [memCaches allKeys]){
		[self freeMemCacheForFilegroup:k];
	}
	
	
}

-(NSString *)cacheKeyForMFlowItem:(MFlowItem *)item{
	
	return [NSString stringWithFormat:@"%@_%@",item.ItemID,[item objectForKey:@"ExpressedVersionNumber"]];
	
}

- (NSString *)cacheKeyForURL:(NSString*)URL {
	const char* str = [URL UTF8String];	
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5(str, strlen(str), result);

	return [NSString stringWithFormat:
			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
  ];
}



-(NSOperationQueue *)queueForFilegroup:(NSString *)name{
    
	NSOperationQueue *q = [queues objectForKey:name];
	
	if (q == nil) {
		q = [[NSOperationQueue alloc] init];
		[q setMaxConcurrentOperationCount:numConcurrentThreads];
		[queues setObject:q forKey:name];
	}
	
	return q;
  
}

-(NSMutableDictionary *)memCacheForFilegroup:(NSString *)name{
	
	NSMutableDictionary *d = [memCaches objectForKey:name];
	
	if (d == nil) {
		d = [NSMutableDictionary dictionaryWithCapacity:0];
		[memCaches setObject:d forKey:name];
		[self validateDirectory:[cacheDataPathZ stringByAppendingPathComponent:name]];
	}
	
	return d;
}


-(void)updateCleanupTimestamp{
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate gregorianDate] forKey:mflowFileCleanupLastRun];
}




-(void)validateDirectory:(NSString *)path{
	
	if ([dirExistsCache objectForKey:path] != nil){
		return;
	}

	if (![[NSFileManager defaultManager] fileExistsAtPath:path]){
		
		// TMT 072710 replaced deprecated method createDirectoryAtPath:attributes:
		
		NSError *error = nil;
		
		BOOL created = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
		
		if (!created){
			
			NSLog(@"failed to create cache directory error: %@",error);
			
		}
	}
	
	[dirExistsCache setObject:@"there" forKey:path];
	
}


-(void)dealloc{
    [_fileDownloadOperationQueue cancelAllOperations];
}

@end
