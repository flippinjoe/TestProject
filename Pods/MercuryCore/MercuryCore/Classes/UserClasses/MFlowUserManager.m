//
//  MFlowUserManager.m
//  MercuryCoreDev
//
//  Created by Stephen Tallent on 7/6/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import "MFlowUserManager.h"
#import "MFlowConfig.h"
#import "TC_UIDeviceExtensions.h"
#import <CoreLocation/CoreLocation.h>
#import "base64.h"
#import "CXMLNode.h"
#import "CXMLElement.h"
#import "CXMLDocument.h"
#import "CurrentLocation.h"

NSString * const kMFlowUserID = @"MFlowUserID";
NSString * const kMFlowUserSubscriptions = @"MFlowUserSubscriptions";
NSString * const kMFlowUserIsSaving = @"MFlowUserIsSaving";
NSString * const kMFlowUserLocationIsSet = @"MFlowUserLocationIsSet";
NSString * const kMFlowUserZipcode = @"MFlowUserZipcode";
NSString * const kMFlowUserLat = @"MFlowUserLat";
NSString * const kMFlowUserLon = @"MFlowUserLon";
NSString * const kCFBundleVersion = @"CFBundleVersion";
NSString * const kCFBundleShortVersionString = @"CFBundleShortVersionString";
NSString * const kMFlowUserCustomFields = @"MFlowUserCustomFields";
NSString * const kPlatform = @"Platform";
NSString * const kOSVersion = @"OSVersion";
NSString * const kAppVersion = @"AppVersion";
NSString * const kMFlowUserApnToken = @"MFlowUserApnToken";

@interface MFlowUserManager ()
@property (nonatomic, strong, readwrite) NSNumber *userID;
@property (nonatomic, strong, readwrite) NSMutableArray *subscriptions;
@property (nonatomic, strong, readwrite) NSMutableDictionary *customFields;
@property (nonatomic, assign, readwrite) BOOL isSaving;
@property (nonatomic, assign, readwrite) BOOL isInitialized;

- (NSString*)registrationXML;

- (void)startObservingNotifications;
- (void)stopObservingNotifications;
- (void)handleApplicationWillEnterForeground:(NSNotification *)notification;

@end

@implementation MFlowUserManager


#pragma mark - Shared Instance

+ (MFlowUserManager *)sharedUser
{
    static dispatch_once_t onceToken;
    static id instance;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}


#pragma mark - Initializer

- (id)init
{
    self = [super init];
    if(nil != self)
    {
        [self loadFromDefaults];
    }
    return self;
}


#pragma mark - Saving the user to the server

- (void)initMFlowUser
{
    [self startObservingNotifications];
    
	if (!self.isInitialized) {
		if([self userNeedsSaveToServer]) [self saveUserToServer];
		self.isInitialized = YES;
	}
}

// ???: Should we be tracking device id changes. A change in device id could mean a new device, but might imply a wipe and reinstall
// ???: I think we don't need to do this because a new device isn't really a new user, but do we want to track device changes?
- (BOOL)userNeedsSaveToServer
{
    if(!self.userID) return YES;
    if(![self.customFields[kPlatform] isEqualToString:[[UIDevice currentDevice] platform]]) return YES;
    if(![self.customFields[kOSVersion] isEqualToString:[[UIDevice currentDevice] systemVersion]]) return YES;
    if(![self.customFields[kAppVersion] isEqualToString:[self appVersion]]) return YES;
    if(self.isSaving) return YES;
    return NO;
}

- (NSString *)appVersion
{
    NSDictionary *appInfo = [[NSBundle mainBundle] infoDictionary];
    return appInfo[kCFBundleShortVersionString] ?: appInfo[kCFBundleVersion];
}

/*
 NSString *sysVersion = [[UIDevice currentDevice] systemVersion];
 NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
 NSString *appVersion = [info objectForKey:@"CFBundleVersion"];
 
 customFields = [[NSUserDefaults standardUserDefaults] objectForKey:@"MFlowUserCustomFields"];
 if (customFields == nil) {
 customFields = [[NSMutableDictionary dictionaryWithCapacity:0] retain];
 [customFields setObject:sysVersion forKey:@"OSVersion"];
 [customFields setObject:appVersion forKey:@"AppVersion"];
 } else {
 NSString *prevOSVersion = [customFields objectForKey:@"OSVersion"];
 if (prevOSVersion == nil || [prevOSVersion compare:sysVersion] != NSOrderedSame) {
 [customFields setObject:sysVersion forKey:@"OSVersion"];
 isDirty = true;
 }
 NSString *prevAppVersion = [customFields objectForKey:@"AppVersion"];
 if (prevAppVersion == nil || [prevAppVersion compare:appVersion] != NSOrderedSame) {
 [customFields setObject:appVersion forKey:@"AppVersion"];
 isDirty = true;
 }
 }

 */

- (NSString *)registrationXML
{
    // ???: Can we remove ZipCode, Latitude, and Logitude from this call?
	NSString *format = @"<root>"
    "<user %@ uuid=\"%@\" distributionID=\"%i\">"
    "<Brand>%@</Brand>"
    "<Model>%@</Model>"
    "<OS>1</OS>"
    "<OSVersion>%@</OSVersion>"
    "<AppVersion>%@</AppVersion>"
    "<ZipCode>%@</ZipCode>"
    "<Latitude>%@</Latitude>"
    "<Longitude>%@</Longitude>"
    "%@"
    "</user>"
    "%@"
    "<capabilities>%@</capabilities>"
    "</root>";
	
	// ???: Do we still care about these capabilities
	NSMutableString *capabilities = [NSMutableString stringWithCapacity:0];
	
	NSArray *a = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
	for (NSInteger i = 0; i < a.count; i++){
		NSString *o = [a objectAtIndex:i];
		if ([o compare:@"public.image"] == NSOrderedSame){
			[capabilities appendString:@"<capability id=\"1\" />"];
		} else if ([o compare:@"public.movie"] == NSOrderedSame) {
			[capabilities appendString:@"<capability id=\"2\" />"];
		}
	}
	
    // ???: Are we still wanting to track this capability?
    if ([CLLocationManager headingAvailable])
    { [capabilities appendString:@"<capability id=\"3\" />"]; }
	
	NSString *user = @"";
	if (self.userID != 0) {
		user = [NSString stringWithFormat:@"userID=\"%@\"",self.userID];
	}
	
	
	// now we gen the custom fields
	NSMutableString *cust = [NSMutableString stringWithCapacity:0];
	for (NSObject *key in [self.customFields allKeys]){
		
		[cust appendString:[NSString stringWithFormat:@"<%@>%@</%@>",key, [self.customFields objectForKey:key] ,key]];
		
	}
	
	NSMutableString *subs = [NSMutableString stringWithCapacity:0];
	if (self.apnTokenBase64 != nil) {
		[subs appendString:@"<subscriptions>"];
		
		for (NSNumber *sub in self.subscriptions){
			[subs appendString:[NSString stringWithFormat:@"<subscription templateID=\"%@\" address=\"%@\" />",sub,self.apnTokenBase64]];
		}
        
		[subs appendString:@"</subscriptions>"];
	}
	
	
	// !!!: The blank strings in the formt are for deprecated zipcode, lat and lon
	NSString *regXML = [NSString stringWithFormat:format,
                        user,
                        [[MFlowConfig sharedInstance] deviceID],
                        [[MFlowConfig sharedInstance] distributionID],
                        @"Apple 2GS",
                        [[UIDevice currentDevice] platform],
                        [[UIDevice currentDevice] systemVersion],
                        [self appVersion],
                        @"",
                        @"0",
                        @"0",
                        cust,
                        subs,
                        capabilities];
	
	
	return regXML;
    
}

- (NSData *)registrationPayload
{
    NSString *fullXML = [self registrationXML];
	NSString *payloadString = [NSString stringWithFormat:@"XML=%@",[[NSString stringWithBase64Encoding:fullXML] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]  ];
	
	payloadString = [payloadString stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
	return [payloadString dataUsingEncoding: NSASCIIStringEncoding];
}

- (NSURLRequest *)registrationURLRequest
{
    NSURL *endpoint = [self registrationEndpoint];
    NSData *payload = [self registrationPayload];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:endpoint];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:payload];

    return req;
}

- (NSURL *)registrationEndpoint
{
    NSString *appURLEndpoint = [MFlowConfig mflowAppURL];
    NSString *saveEndpoint = [NSString stringWithFormat:@"%@Tallent.MFlow.WS/REST/User.aspx?function=registration", appURLEndpoint];
    return [NSURL URLWithString:saveEndpoint];
}

- (void)saveUserToServer
{
	
	self.isSaving = true;
	
	[self saveUser];

    NSURLRequest *request = [self registrationURLRequest];
	   
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        // handle connectionError
        if(!data)
        {
            [self handleRegistrationConnectionError:connectionError];
            return;
        }
        
        // handle bad response
        NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
        if(urlResponse.statusCode != 200)
        {
            [self handleRegistrationBadURLResponse:urlResponse];
            return;
        }
        
        [self parseRegistrationResponseData:data];
        
    }];
}


#pragma mark - Parsing the server response

- (void)handleRegistrationConnectionError:(NSError *)error
{
    if(self.registrationErrorBlock) self.registrationErrorBlock(error);
    self.isSaving = NO;
}

- (void)handleRegistrationBadURLResponse:(NSHTTPURLResponse *)urlResponse
{
    if(self.registrationErrorBlock)
    {
        NSString *errorMessage = [NSString stringWithFormat:@"Unhandled response code %i",urlResponse.statusCode];
        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: errorMessage};
        NSError *statusError = [NSError errorWithDomain:@"MFlowUserDomain" code:-1001 userInfo:errorInfo];
        self.registrationErrorBlock(statusError);
    }
    self.isSaving = NO;
}

- (void)handleRegistrationServerResponseError:(NSError *)error
{
    if(self.registrationErrorBlock) self.registrationErrorBlock(error);
    self.isSaving = NO;
}

- (void)parseRegistrationResponseData:(NSData *)data
{
    // handle response with server error
    NSError *serverError;
    NSNumber *responseUserID = [self userIDFromResponseData:data error:&serverError];
    
    if(!responseUserID)
    {
        [self handleRegistrationServerResponseError:serverError];
        return;
    }
    
    [self finishRegistrationWithResponseUserID:responseUserID];
}

- (void)finishRegistrationWithResponseUserID:(NSNumber *)userID
{
    self.userID = userID;
    [self saveUser];
    self.isSaving = NO;
    if(self.registrationSuccessBlock) self.registrationSuccessBlock(self.userID);
}

- (NSNumber *)userIDFromResponseData:(NSData *)responseData error:(NSError *__autoreleasing *)error
{
    NSError *parseError;
    CXMLDocument *document = [[CXMLDocument alloc] initWithData:responseData encoding:NSUTF8StringEncoding options:0 error:&parseError];
    CXMLNode *errorAttribute = [[document rootElement] attributeForName:@"error"];
    if(errorAttribute)
    {
        if(error)
        {
            NSString *errorMessage = [[document rootElement] stringValue];
            NSDictionary *info = @{NSLocalizedDescriptionKey: errorMessage};
            *error = [NSError errorWithDomain:@"MFlowUserDomain" code:-1002 userInfo:info];
        }
        return nil;
        
    }
    
    CXMLNode *userAttribute = [[document rootElement] attributeForName:@"userID"];
    return @([[userAttribute stringValue] integerValue]);
}


#pragma mark - Saving the user locally

- (void)saveUser
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:self.userID forKey:kMFlowUserID];
	[ud setObject:self.subscriptions forKey:kMFlowUserSubscriptions];
	[ud setObject:self.customFields forKey:kMFlowUserCustomFields];
	[ud setBool:self.isSaving forKey:kMFlowUserIsSaving];
    [ud setObject:self.apnTokenBase64 forKey:kMFlowUserApnToken];
	[ud synchronize];
}


#pragma mark - Loading localy saved user attributes

- (void)loadFromDefaults
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    _userID = [ud objectForKey:kMFlowUserID];
    _subscriptions = [[ud objectForKey:kMFlowUserSubscriptions] mutableCopy] ?: [NSMutableArray array];
    _apnTokenBase64 = [ud objectForKey:kMFlowUserApnToken];
    _customFields = [[ud objectForKey:kMFlowUserCustomFields] mutableCopy] ?: [NSMutableDictionary dictionary];
    _isSaving = [ud boolForKey:kMFlowUserIsSaving];
}


#pragma mark - Notifications

- (void)startObservingNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)stopObservingNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleApplicationWillEnterForeground:(NSNotification *)notification
{
    // Retry user registration every time app enters foreground, if needed
    if ([self userNeedsSaveToServer]) {
        [self saveUserToServer];
    }
}


#pragma mark - Cleanup

- (void)dealloc
{
    [self stopObservingNotifications];
}

@end
