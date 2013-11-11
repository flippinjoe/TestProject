//
//  TC_NSDateExtensions.h
//  MFlowEventManagerDev
//
//  Created by Stephen Tallent on 6/23/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDate (TC_NSDateExtensions) 

- (NSDate *)dateRoundedDownToHour;
- (NSDate *)dateRoundedDownToDay;
- (NSString *)formattedElapsedTime;
- (NSDate *)dateNormalizedToCT;
+ (NSDate*)gregorianDate;
+ (NSDate*)gregorianDateWithTimeIntervalSinceNow:(NSTimeInterval)seconds;
+ (NSDate*)convertToGregorianFromDate:(NSDate*)date;

@end
