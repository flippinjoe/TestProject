//
//  MFlowFileServicesOperation.h
//  ArchTest1
//
//  Created by Stephen Tallent on 12/20/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MFlowFileServicesOperation : NSOperation {
	
	NSInteger expirationDays;
	NSString *cachePath;
}

-(id)initWithDays:(NSInteger)days cachePath:(NSString *)cPath;

@end
