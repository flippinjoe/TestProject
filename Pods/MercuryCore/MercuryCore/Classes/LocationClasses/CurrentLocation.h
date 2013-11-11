//
//  WeatherCurrentLocation.h
//  USAToday1
//
//  Created by Stephen Tallent on 9/15/08.
//  Copyright 2008 Mercury Intermedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyCLController.h"
#import "CXMLNode.h"
#import "CXMLDocument.h"
#import "CXMLElement.h"
#import "TC_CXMLExtensions.h"
#import "GTURLConnectionController.h"

extern NSString * const kLocationUpdated;
extern NSString * const kLocationUpdateFailed;
extern NSString * const MFlowLocationServicesDomain;

// 2000 - 3000
enum {
    // The timeout happened befor we got a location
    MFlowLocationServiceTimeoutError = 2001,
    
    // There was something wrong with the data we got back from the zip search service.
    MFlowLocationServiceSearchDataError = 2002,
};

@interface CurrentLocation : NSObject <MyCLControllerDelegate,GTURLConnectionDelegate>{
	
	GTURLConnectionController *mySocket;
	NSString *latitude;
	NSString *longitude;
	NSString *city;
	NSString *state;
	NSString *zipcode;
	NSString *cityLatitude;
	NSString *cityLongitude;
	
	bool gettingLocation;
	
	CLLocation *closestCurrentLocation; //This is used by the timer. We try to get the closest location within 150 yards. If it times out, use the first one that was returned.
	NSTimer *timeoutTimer;
}

@property(nonatomic, strong) NSString *latitude;
@property(nonatomic, strong) NSString *longitude;
@property(nonatomic, strong) NSString *city;
@property(nonatomic, strong) NSString *state;
@property(nonatomic, strong) NSString *zipcode;
@property(nonatomic, strong) NSString *cityLatitude;
@property(nonatomic, strong) NSString *cityLongitude;


+ (CurrentLocation*)sharedCurrentLocation;
- (void)getCurrentLocation;
//- (CGFloat)distanceToClosestCity;
- (void)broadcast;
- (void)locationTimedOut;

@end
