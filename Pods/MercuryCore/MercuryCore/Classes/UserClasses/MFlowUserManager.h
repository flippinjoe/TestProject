//
//  MFlowUserManager.h
//  MercuryCoreDev
//
//  Created by Stephen Tallent on 7/6/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 An MFlowUserManager object encapsulates data about an MFlow application's user and handles registration of that user with the M3 server for the application. 
 
 User data managed includes the userID for the user in the M3 system, subscriptions to push notifications, the APN token for the user, and any custom fields needed for app specific user values.
 
 Additionally registration with the M3 server includes the current device platform, the generated UUID for the device, the distribution ID for the MFlow application, and device capabilities (camera, location).
 */
@interface MFlowUserManager : NSObject

/** @name Accessing the shared MFlowUserManager instance */

/**
 Returns the shared instance representing the MFlowUserManager for the application.
 */
+ (MFlowUserManager *)sharedUser;


/** @name User Attributes */

/**
 The user ID assigned to the user on the M3 system for the applicaiton. This property is present only after the user has been successfully registered.
 */
@property (nonatomic, strong, readonly) NSNumber *userID;

/**
 The list of template IDs representing push notifications the user has subscribed to on the M3 system.
 */
@property (nonatomic, strong, readonly) NSMutableArray *subscriptions;

/**
 A dictionary for passing app specific custom user attributes during user registration.
 */
@property (nonatomic, strong, readonly) NSMutableDictionary *customFields;

/**
 The APN token for the user.
 */
@property (nonatomic, strong, readwrite) NSString *apnTokenBase64;


/** @name Registering a User */

/**
 Calling this method registers the user with the M3 system for the application. This method will only execute once per app launch and then only if the user requires registration.
 */
- (void)initMFlowUser;

/**
 A block of code to execute when the user registration succeeds. The registeredUserID block param represents the user ID returned from the M3 system for the user.
 */
@property (nonatomic, copy, readwrite) void (^registrationSuccessBlock)(NSNumber *registeredUserID);

/**
 A block of code to execute when the user registration fails. The error block param contains a detailed error describing the failure.
 */
@property (nonatomic, copy, readwrite) void (^registrationErrorBlock)(NSError *error);


/** @name Saving the User */

/**
 Saves the user on the device.
 */
- (void)saveUser;

/**
 Saves the user to the server. Only call this method if you have changed the user data (i.e. added a subscription) and want to update the server record for the user. This method also saves the user locally.
 */
- (void)saveUserToServer;

@end
