//
//  MFlowUserManager.h
//  MercuryCoreDev
//
//  Created by Stephen Tallent on 7/6/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kDeviceUUIDKey;

@interface MFlowUserManager : NSObject {
	
	NSNumber *userID;
	NSMutableArray *subscriptions;
	NSMutableDictionary *customFields;
	NSString *apnTokenBase64;
	
	NSString *zipcode;
	NSString *lat;
	NSString *lon;
	
	bool isInitialized;
	
	bool isDirty;
	
	bool isSaving;
	
	NSURLConnection *conn;
	NSMutableData *connData;
	
	bool isLocationSet;
}

@property(nonatomic, retain) NSNumber *userID;
@property(nonatomic, readonly) NSMutableArray *subscriptions;
@property(nonatomic, readonly) NSMutableDictionary *customFields;
@property(nonatomic, retain) NSString *apnTokenBase64;
@property(nonatomic, readonly) bool isLocationSet;
@property(nonatomic, readonly) bool isInitialized;

+(MFlowUserManager *) sharedUser;


-(void) initMFlowUser;
-(NSString*)generateRegXMLString;
-(void)setSubscriptionList:(NSArray *)list;
-(void)saveUser;
-(void)saveUserToServer;

@end
