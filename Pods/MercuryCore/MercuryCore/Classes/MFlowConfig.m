//
//  MFlowConfig.m
//  MercuryCoreDev
//
//  Created by Stephen Tallent on 5/11/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import "MFlowConfig.h"
#import "MFlowUserManager.h"
#import "MFlowContainer.h"
#import "SFHFKeychainUtils.h"
#import "TC_NSDateExtensions.h"

const struct MFlowImpKeys MFlowImpKeys = {
    .iphone         = @"HVGA",
    .iphone2x       = @"HVGA2x",
    .iphone2x4      = @"HVGA2xh",
    .ipad           = @"IPAD",
    .ipad2x         = @"IPAD2x"
};

const struct MFlowConfigKeys MFlowConfigKeys = {
    .productKey                     = @"ProductKey",
    .stagingKey                     = @"StagingEnabled",
    .deviceIDKey                    = @"DeviceID",
    .liveAppURLKey                  = @"LiveAppURL",
    .stagingAppURLKey               = @"StagingAppURL",
    .distributionIDKey              = @"DistributionID",
    .implementationKey              = @"ImplementationKey",
    .resizedImageTypeIDKey          = @"ResizedImageTypeID"
};

const struct MFlowConfigSettingsKeys MFlowConfigSettingsKeys = {
    .clearCachesKey                 = @"HgM3ClearCachePrefKey",
    .stagingEnabledKey              = @"HgM3StagingPrefKey"
};

@interface MFlowConfig ()

@property (nonatomic, copy) NSString *productKey;

@property (nonatomic, copy) NSDictionary *classReg;     // Not sure what this is even for
@property (nonatomic, strong) NSOperationQueue *serviceOpsQueue;


+ (void)storeToken:(NSString *)tokenString;
+ (NSString *)storedToken;
+ (NSString *)generateUUID;

@end

static MFlowConfig *_instance = nil;


#define defaultResizedTypeID 1029 //ML: For backwards compatibility purposes, the resizedImageTypeID default value is 1029.
#define kTransitionedContainersToCachesStorageKey @"TransitionedContainersToCachesStorage"
#define kMFlowConfigService @"MFlowConfigService"
#define kCachedDeviceIDAccessTokenKey @"CachedDeviceIDAccessTokenKey"

@interface MFlowConfig (TC_Private)
- (void)transitionCacheStorageIfNeeded;
@end

@implementation MFlowConfig

@synthesize deviceID = _deviceID;
@synthesize stagingEnabled = _stagingEnabled;
@synthesize initialized = _initialized;


#pragma mark - Initialize

+ (MFlowConfig *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[MFlowConfig alloc] init];
        _instance.serviceOpsQueue = [[NSOperationQueue alloc] init];
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:_instance selector:@selector(handleAppWillTerminate:) name:UIApplicationWillTerminateNotification object:[UIApplication sharedApplication]];
        [center addObserver:_instance selector:@selector(handleAppBecameActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
    });
    return _instance;
}

+ (void)initMFlowWithConfig:(NSDictionary *)config
{
    NSAssert([MFlowConfig sharedInstance].isInitialized == NO, @"You can only initMflowConfig once.  If you need to change values you may do so through the sharedInstance properties");
    
    NSString *assertFormat = @"You must set a value for %@";
    void (^CheckValuesAndTypesForKeys)(NSString*,Class) = ^(NSString *key, Class c) {
        id val = config[key];
        NSAssert(val != nil,assertFormat,key);
        NSAssert(c != [val class], @"Value for %@ does not match expected type %@",key,NSStringFromClass(c));
    };
    
    CheckValuesAndTypesForKeys(MFlowConfigKeys.productKey,[NSString class]);
    CheckValuesAndTypesForKeys(MFlowConfigKeys.liveAppURLKey,[NSString class]);
    CheckValuesAndTypesForKeys(MFlowConfigKeys.stagingAppURLKey,[NSString class]);
    CheckValuesAndTypesForKeys(MFlowConfigKeys.distributionIDKey,[NSNumber class]);
    
    
    MFlowConfig *instance = [MFlowConfig sharedInstance];
    instance.productKey = config[MFlowConfigKeys.productKey];
    instance.distributionID = [config[MFlowConfigKeys.distributionIDKey] integerValue];
    if(config[MFlowConfigKeys.deviceIDKey])
    { [instance setDeviceID:config[MFlowConfigKeys.deviceIDKey]]; }
    
    NSString *implementation = IS_IPAD?MFlowImpKeys.ipad:MFlowImpKeys.iphone;
    
    if(IS_RETINA)
    { implementation = IS_IPAD?MFlowImpKeys.ipad2x:(IS_4IN?MFlowImpKeys.iphone2x4:MFlowImpKeys.iphone2x); }
    
    instance.impKey = config[MFlowConfigKeys.implementationKey]?:implementation;
    
    instance.resizedImageTypeID = config[MFlowConfigKeys.resizedImageTypeIDKey]?[config[MFlowConfigKeys.resizedImageTypeIDKey] intValue]:defaultResizedTypeID;
	instance.appStartDate = [NSDate gregorianDate];
    
    if(config[MFlowConfigKeys.stagingKey])
    { instance.stagingEnabled = [config[MFlowConfigKeys.stagingKey] boolValue]; }
    else if([[NSUserDefaults standardUserDefaults] valueForKey:MFlowConfigSettingsKeys.stagingEnabledKey])
    { instance.stagingEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:MFlowConfigSettingsKeys.stagingEnabledKey]; }
    
    NSString *format = @"%@/%@/";
    NSString *pKey = config[MFlowConfigKeys.productKey];
	instance.mflowProdAppURL = [NSString stringWithFormat:format,config[MFlowConfigKeys.liveAppURLKey],pKey];
    instance.mflowStagingAppURL = [NSString stringWithFormat:format,config[MFlowConfigKeys.stagingAppURLKey],pKey];
    
    instance->_initialized = YES;
}


#pragma mark -
#pragma mark Cache Changes

- (void)transitionCacheStorageIfNeeded
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if(![ud boolForKey:kTransitionedContainersToCachesStorageKey])
    {
        // find the old files
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *docsDirectory = [[fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *cachesDirectory = [[fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
        NSArray *filesInDocs = [fm contentsOfDirectoryAtURL:docsDirectory includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
        // put them in the caches directory
        if(filesInDocs)
        {
            // match for the format
            NSPredicate *filter = [NSPredicate predicateWithFormat:@"%K BEGINSWITH[cd] %@",@"lastPathComponent",@"containerV2"];
            NSArray *containerCacheFiles = [filesInDocs filteredArrayUsingPredicate:filter];
            for(NSURL *containerCacheURL in containerCacheFiles)
            {
                NSURL *newCacheURL = [cachesDirectory URLByAppendingPathComponent:[containerCacheURL lastPathComponent]];
                [fm copyItemAtURL:containerCacheURL toURL:newCacheURL error:nil]; 
                NSError *removeError = nil;
                [fm removeItemAtURL:containerCacheURL error:&removeError];
            }
        }
        
        [ud setBool:YES forKey:kTransitionedContainersToCachesStorageKey];
        [ud synchronize];
    }
}


#pragma mark - Getters

+ (NSString *)mflowAppURL
{ return _instance.usingStaging ? _instance.mflowStagingAppURL : _instance.mflowProdAppURL; }

- (NSString*)deviceID
{
    if (_deviceID == nil) {
        
        // PF - 1/10/12
        // For the short term, continue to use actual device ID
        
        // PF - 3/27/12
        // For Ole Miss - override and use new (preferred) method below as apps using device ID are now being rejected
        //   and as Ole Miss is being newly released there is no concern with generating new user IDs
        
        //        deviceID = [[UIDevice currentDevice].uniqueIdentifier stringByReplacingOccurrencesOfString:@"-" withString:@""];
        
        // The following is the preferred method, but will need to wait on a server side change
        //  to prevent new user id being generated when new device id is detected
        _deviceID = [[self class] storedToken];
        
        if (_deviceID == nil) {
            
            NSString *uuid = [[self class] generateUUID];
            _deviceID = [uuid stringByReplacingOccurrencesOfString:@"-" withString:@""];
            
            [[self class] storeToken:_deviceID];
        }
    }
	return _deviceID;
}


#pragma mark - Setters

- (void)setStagingEnabled:(BOOL)stagingEnabled
{
    if(_stagingEnabled == stagingEnabled) return;
    _stagingEnabled = stagingEnabled;
    if(stagingEnabled != [[NSUserDefaults standardUserDefaults] boolForKey:MFlowConfigSettingsKeys.stagingEnabledKey])
    {
        [[NSUserDefaults standardUserDefaults] setBool:stagingEnabled forKey:MFlowConfigSettingsKeys.stagingEnabledKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


#pragma mark - Notifications

- (void)handleAppWillTerminate:(NSNotification *)note
{
	[self.serviceOpsQueue cancelAllOperations];
}

- (void)handleAppBecameActive:(NSNotification *)note
{
    [self checkCache];
    if([[NSUserDefaults standardUserDefaults] valueForKey:MFlowConfigSettingsKeys.stagingEnabledKey])
    { [self setStagingEnabled:[[NSUserDefaults standardUserDefaults] boolForKey:MFlowConfigSettingsKeys.stagingEnabledKey]]; }
}


#pragma mark - Settings Bundle 

- (void)checkCache
{
    if([NSThread isMainThread])
    { return [self performSelectorInBackground:_cmd withObject:nil]; }
    
    // This is a new function that is now in the Settings.bundle for every app that's built through jenkins.
    // If this box is checked then we should clear our cache
    BOOL clearCache = [[NSUserDefaults standardUserDefaults] boolForKey:@"HgM3ClearCachePrefKey"];
    if(clearCache)
    {
        NSString *cacheDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];
        [[NSFileManager defaultManager] removeItemAtPath:cacheDir error:nil];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"HgM3ClearCachePrefKey"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark -
#pragma mark Remove containers.

+ (void)removeMFlowContainerCaches:(NSArray *)containerIDs
{
	NSFileManager *fm = [NSFileManager defaultManager];
	for(NSNumber *containerID in containerIDs)
    {
		NSString *path = [MFlowContainer diskCachePathWithContainerID:[containerID intValue]];
		NSError *error = nil;
		if([fm fileExistsAtPath:path])
        {
			BOOL removed = [fm removeItemAtPath:path error:&error];
			if(!removed)
            {
				//MFLOG(@"Error removing cache file: %@",error);
			}
		}
	}
}

+ (void)dump
{
    NSLog(@"Config: %@", @{
                           MFlowConfigKeys.productKey:_instance.productKey,
                           MFlowConfigKeys.stagingAppURLKey:_instance.mflowStagingAppURL,
                           MFlowConfigKeys.liveAppURLKey:_instance.mflowProdAppURL,
                           MFlowConfigKeys.stagingKey:@(_instance.stagingEnabled),
                           MFlowConfigKeys.distributionIDKey:@(_instance.distributionID),
                           MFlowConfigKeys.deviceIDKey:_instance.deviceID,
                           MFlowConfigKeys.implementationKey:_instance.impKey?:@""
                           });
}

#pragma mark -
#pragma mark Keychain access

+ (void)storeToken:(NSString *)tokenString {
	NSError *error = nil;

	[SFHFKeychainUtils storeUsername:kCachedDeviceIDAccessTokenKey andPassword:tokenString forServiceName:kMFlowConfigService updateExisting:1 error:&error];
	
	if(error != nil) {
		NSLog(@">>> there was a problem storing the access key %@", kCachedDeviceIDAccessTokenKey);
	}
}

+ (NSString *)storedToken {
	NSError *error = nil;
	
    NSString *accessTokenString = [SFHFKeychainUtils getPasswordForUsername:kCachedDeviceIDAccessTokenKey andServiceName:kMFlowConfigService error:&error];
	
	if(error != nil) {
		NSLog(@">>> there was a problem getting the access key %@", kCachedDeviceIDAccessTokenKey);
	}
	
	return accessTokenString;	
}

#pragma mark -
#pragma mark Guid generator

+ (NSString *)generateUUID{
    
    CFUUIDRef r = CFUUIDCreate(NULL);
    NSString *guid = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL,r));
    CFRelease(r);
    
    return guid;
}

@end



@implementation MFlowConfig (Deprecated)

+ (void)initMFlow:(NSString *)pKey
       stagingURL:(NSString *)sURL
          liveURL:(NSString *)lURL
     distribution:(NSInteger)dist
           impKey:(NSString *)ik
{ [self initMFlow:pKey stagingURL:sURL liveURL:lURL distribution:dist impKey:ik resizedImageTypeID:defaultResizedTypeID]; }

+ (void)initMFlow:(NSString *)pKey
       stagingURL:(NSString *)sURL
          liveURL:(NSString *)lURL
     distribution:(NSInteger)dist
           impKey:(NSString *)ik
       useStaging:(BOOL)useStaging
{ [self initMFlow:pKey stagingURL:sURL liveURL:lURL distribution:dist impKey:ik resizedImageTypeID:defaultResizedTypeID useStaging:useStaging]; }

+ (void)initMFlow:(NSString *)pKey
       stagingURL:(NSString *)sURL
          liveURL:(NSString *)lURL
     distribution:(NSInteger)dist
           impKey:(NSString *)ik
resizedImageTypeID:(NSInteger)riTypeID
{ [self initMFlow:pKey stagingURL:sURL liveURL:lURL distribution:dist impKey:ik resizedImageTypeID:riTypeID useStaging:NO]; }

+ (void)initMFlow:(NSString *)pKey
       stagingURL:(NSString *)sURL
          liveURL:(NSString *)lURL
     distribution:(NSInteger)dist
           impKey:(NSString *)ik
resizedImageTypeID:(NSInteger)riTypeID
       useStaging:(BOOL)useStaging
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[MFlowConfigKeys.productKey]            = pKey;
    dict[MFlowConfigKeys.distributionIDKey]     = @(dist);
    dict[MFlowConfigKeys.deviceIDKey]           = [[MFlowConfig sharedInstance] deviceID];
    if(ik != nil)
    { dict[MFlowConfigKeys.implementationKey]   = ik; }
    dict[MFlowConfigKeys.resizedImageTypeIDKey] = @(riTypeID);
    dict[MFlowConfigKeys.stagingAppURLKey]      = sURL;
    dict[MFlowConfigKeys.liveAppURLKey]         = lURL;
    
	[MFlowConfig initMFlowWithConfig:dict];
}

+ (NSString *)deviceID
{ return [_instance deviceID]; }

+ (NSString *)impKey
{ return [self sharedInstance].impKey; }

+ (NSDate*)appStartDate
{ return _instance.appStartDate; }

+ (NSInteger)distributionID
{ return _instance.distributionID; }

+ (NSInteger)resizedImageTypeID
{ return [self sharedInstance].resizedImageTypeID; }

+ (BOOL)usingStaging
{ return [MFlowConfig sharedInstance].usingStaging; }

+ (NSString *)getMFlowClassNameByID:(NSString *)clsID {
	if ([self sharedInstance].classReg == nil){
		return nil;
	} else {
		return [[self sharedInstance].classReg objectForKey:clsID];
	}
}

+ (void)addOpToServicesQueue:(NSOperation *)op
{ [[self sharedInstance].serviceOpsQueue addOperation:op]; }

+ (void)setMaxConcurrentOperationsForQueue:(NSInteger)num
{ [[self sharedInstance].serviceOpsQueue setMaxConcurrentOperationCount:num]; }

@end


