//
//  WeatherCurrentLocation.m
//  USAToday1
//
//  Created by Stephen Tallent on 9/15/08.
//  Copyright 2008 Mercury Intermedia. All rights reserved.
//

#import "CurrentLocation.h"
#import "MFlowConfig.h"

@implementation CurrentLocation

@synthesize latitude,longitude;
@synthesize city;
@synthesize state;
@synthesize zipcode;
@synthesize cityLatitude,cityLongitude;

NSString * const kLocationUpdated = @"LocationUpdated";
NSString * const kLocationUpdateFailed = @"LocationFailedUpdated";
NSString * const MFlowLocationServicesDomain = @"MFlowLocationServicesDomain";

static CurrentLocation* _sharedCurrentLocation;

+(CurrentLocation*)sharedCurrentLocation{
	
	if (_sharedCurrentLocation == nil){
		_sharedCurrentLocation = [[CurrentLocation alloc] init];
		
	}
	
	
	return _sharedCurrentLocation;
	
}

- (void) dealloc
{
    [timeoutTimer invalidate];
}

- (id)init {
	[MyCLController sharedInstance].delegate = self;
    zipcode = nil;
	return self;
}

- (void)broadcast {
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:kLocationUpdated object:self];

}

- (void)notifyUpdateFailedWithInfo:(id)userInfo {
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationUpdateFailed object:self userInfo:userInfo];
}


- (void)getCurrentLocation {
	
	if (gettingLocation) return;
	
	gettingLocation = true;
	
	//MFLOG_MARK();
	
	[[MyCLController sharedInstance].locationManager startUpdatingLocation];
	
	if (mySocket == nil){
		mySocket = [[GTURLConnectionController alloc] initWithDelegate:self];
	}
	
}
/*
- (CGFloat)distanceToClosestCity {
	CLLocation *cityLocation = [[[CLLocation alloc] initWithLatitude:[self.cityLatitude floatValue]
														   longitude:[self.cityLongitude floatValue]] autorelease];
	CLLocation *userLocation = [[[CLLocation alloc] initWithLatitude:[self.latitude floatValue]
														   longitude:[self.longitude floatValue]] autorelease];
	CGFloat distance = [cityLocation getDistanceFrom:userLocation] * 0.0006213712;
//	NSLog(@"DISTANCE: %f  BETWEEN CITYLAT: %f  CITYLON: %f  TO USERLAT: %f  USERLON: %f", distance,
//		  [self.cityLatitude floatValue], [self.cityLongitude floatValue],
//		  [self.latitude floatValue], [self.longitude floatValue]);
	return distance;
}*/

-(void)locationTimedOut {
    //MFLOG_MARK();
	[[MyCLController sharedInstance].locationManager stopUpdatingLocation];
	[timeoutTimer invalidate];
	
	
	if (closestCurrentLocation != nil) {

		NSString *f = @"%@Tallent.MFlow.WS/REST/Utility.aspx?Function=GetZipCode&Latitude=%f&Longitude=%f";
		NSString *url = [NSString stringWithFormat:f,[MFlowConfig mflowAppURL],closestCurrentLocation.coordinate.latitude,closestCurrentLocation.coordinate.longitude];
	
		self.latitude = [NSString stringWithFormat:@"%f",closestCurrentLocation.coordinate.latitude];
		self.longitude = [NSString stringWithFormat:@"%f",closestCurrentLocation.coordinate.longitude];

		[mySocket makeRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];

	} else {
        NSError *error = [NSError errorWithDomain:MFlowLocationServicesDomain code:MFlowLocationServiceTimeoutError userInfo:nil];
        NSDictionary *info = [NSDictionary dictionaryWithObject:error forKey:@"error"];
		[self notifyUpdateFailedWithInfo:info];
	}
}

-(void)newLocationUpdate:(CLLocationManager *)manager
	 didUpdateToLocation:(CLLocation *)newLocation
			fromLocation:(CLLocation *)oldLocation {
	
	if (timeoutTimer == nil || ![timeoutTimer isValid]) {
		timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:12 target:self selector:@selector(locationTimedOut) userInfo:nil repeats:FALSE];
	}
	
    //MFLOG(@"LOCATION UPDATE: %@",newLocation);
	
	CLLocationAccuracy hAcc = newLocation.horizontalAccuracy;
	
	
	if (([newLocation.timestamp compare:[MFlowConfig sharedInstance].appStartDate] != NSOrderedAscending) && hAcc != -1)
	{
		//Go ahead and assign it to closestCurrentLocation, even if it's not the one we'll use, just in case the timer fires.
		
		closestCurrentLocation = newLocation;

		if (hAcc < 150) {
			[[MyCLController sharedInstance].locationManager stopUpdatingLocation];
			[timeoutTimer invalidate];
			
			NSString *f = @"%@Tallent.MFlow.WS/REST/Utility.aspx?Function=GetZipCode&Latitude=%f&Longitude=%f";
			NSString *url = [NSString stringWithFormat:f,[MFlowConfig mflowAppURL], newLocation.coordinate.latitude,newLocation.coordinate.longitude];
			
			self.latitude = [NSString stringWithFormat:@"%f",newLocation.coordinate.latitude];
			self.longitude = [NSString stringWithFormat:@"%f",newLocation.coordinate.longitude];
			//MFLOG(@"GET ZIP INFO FROM %@",url);
			[mySocket makeRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
			
		}
	}
}

-(void)newError:(NSString *)text {
	gettingLocation = false;
	[timeoutTimer invalidate];
	
	[self broadcast];
}

- (void)handleDataError {
    NSError *error = [NSError errorWithDomain:MFlowLocationServicesDomain code:MFlowLocationServiceSearchDataError userInfo:nil];
    NSDictionary *info = [NSDictionary dictionaryWithObject:error forKey:@"error"];
    [self notifyUpdateFailedWithInfo:info];
}

- (void)connection:(GTURLConnectionController *)connection finishedWithData:(NSData *)data{
	NSError *error = nil;
	NSArray *itemNodes;
	CXMLElement *node;
	CXMLNode *att;
	
    NSString *xml = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *trimmedXML = [xml stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(trimmedXML == nil || trimmedXML.length == 0) {
        // we got blanked data so report it and bail
        [self handleDataError];
        return;
    }
    
	CXMLDocument *resultDoc = [[CXMLDocument alloc] initWithXMLString:trimmedXML options:0 error:&error];
	
    if(error != nil) {
        // we got some unparsable stuff
        [self handleDataError];
        return;
    }
    
	itemNodes = [resultDoc nodesForXPath:@"//Geo" error:&error];
	if ([itemNodes count] != 1)
		return;
	
	node = [itemNodes objectAtIndex:0];

	att = [node attributeForName:@"City"];
	
	self.city = [att stringValue];
	
	att = [node attributeForName:@"StateCode"];
	
	self.state = [att stringValue];
	
	att = [node attributeForName:@"Zip"];
	
	self.zipcode = [att stringValue];
	
	att = [node attributeForName:@"Lat"];
	
	self.cityLatitude = [att stringValue];
	
	att = [node attributeForName:@"Lon"];
	
	self.cityLongitude = [att stringValue];
	
	gettingLocation = false;
	
	if (timeoutTimer != nil) {
		timeoutTimer = nil;
	}
	
	
	[self broadcast];
}
- (void)connection:(GTURLConnectionController *)connection receivedStatusCode:(int)code{
	
}
- (void)connection:(GTURLConnectionController *)connection failedWithMessage:(NSString *)message{
	gettingLocation = false;
    [self handleDataError];
}


@end
