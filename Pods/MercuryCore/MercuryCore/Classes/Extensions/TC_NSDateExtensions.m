//
//  TC_NSDateExtensions.m
//  MFlowEventManagerDev
//
//  Created by Stephen Tallent on 6/23/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import <objc/runtime.h>
#import "TC_NSDateExtensions.h"

/*
 #define minute (second * 60)
 #define minute5 (minute * 5)
 #define minute10 (minute * 10)
 #define minute15 (minute * 15)
 #define minute30 (minute * 30)
 */

#define second 1.0
#define minute (second * 60)
#define hour (minute * 60)
#define day (hour * 24)

@interface NSDate (Private)

+ (NSDate*)convertToGregorianFromDate:(NSDate*)date;

@end

@implementation NSDate (TC_NSDateExtensions)

- (NSDate *)dateRoundedDownToHour {
	
	NSTimeInterval ti = [self timeIntervalSinceReferenceDate];
	
	NSInteger totalHours = floor(ti / hour);
	
	return [NSDate convertToGregorianFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:(totalHours * hour)]];
	
}

- (NSDate *)dateRoundedDownToDay {
	
	NSTimeInterval ti = [self timeIntervalSinceReferenceDate];
	
	NSInteger totalDays = floor(ti / day);
	
	NSInteger myGMToffsetSeconds = [[NSTimeZone systemTimeZone] secondsFromGMT];

	NSInteger newTi = (totalDays * day) + (-myGMToffsetSeconds);
	
	return [NSDate convertToGregorianFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:newTi]];
	
}

- (NSDate *)dateNormalizedToCT {
	NSInteger myGMToffsetSeconds = [[NSTimeZone systemTimeZone] secondsFromGMT];
//	NSInteger ctGMToffsetSeconds = [[NSTimeZone timeZoneWithAbbreviation:@"CST"] secondsFromGMT];
	NSInteger ctGMToffsetSeconds = [[NSTimeZone timeZoneWithName:@"America/Chicago"] secondsFromGMT];
	NSInteger correctionOffset = myGMToffsetSeconds - ctGMToffsetSeconds;
	
//	NSLog(@"GMT OFFSET: %i  CT OFFSET: %i  CORRECTION OFFSET: %i", myGMToffsetSeconds, ctGMToffsetSeconds, correctionOffset);
	
	NSDate *normalizedDate = [[NSDate alloc] initWithTimeInterval:(double)correctionOffset sinceDate:self];
	return normalizedDate;
}

- (NSString *)formattedElapsedTime {
	// Calculate the minutes between the date and now
	NSTimeInterval updatedMinutes = ([[NSDate date] timeIntervalSinceDate:self] - [[NSDate date] timeIntervalSinceNow]) / 60.0;
	NSTimeInterval updatedHours = updatedMinutes / 60.0;
	
	// Format the "elapsed time" string
	NSString *formattedElapsedTime;
	if (updatedMinutes <= 60.0) {
		// Display minutes only
		if (updatedMinutes < 2.0) {
			formattedElapsedTime = @"1 minute ago";
		}
		else {
			formattedElapsedTime = [NSString stringWithFormat:@"%d minutes ago", (NSInteger)updatedMinutes];
		}
	}
	else if (updatedHours <= 4.0) {
		NSInteger leftoverMinutes = (NSInteger)updatedMinutes - ((NSInteger)updatedHours * 60);
		if (leftoverMinutes > 0) {
			// Display hours and minutes
			if (updatedHours < 2.0) {
				formattedElapsedTime = [NSString stringWithFormat:@"1 hour, %d minutes ago", leftoverMinutes];
			}
			else {
				formattedElapsedTime = [NSString stringWithFormat:@"%d hours, %d minutes ago", (NSInteger)updatedHours, leftoverMinutes];
			}
		}
		else {
			// Display hours only
			if (updatedHours < 2.0) {
                /** Joe:  9/18/12
                *   Formated String Not useing the updatedHours here.  Using regular string
                *
                *   formattedElapsedTime = [NSString stringWithFormat:@"1 hour ago", (NSInteger)updatedHours];
                 **/
                formattedElapsedTime = @"1 hour ago";
			}
			else {
				formattedElapsedTime = [NSString stringWithFormat:@"%d hours ago", (NSInteger)updatedHours];
			}
		}
	}
	else {
		// Display full date/time
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		//[dateFormatter setDateFormat:@"h:mma v, MMM d, yyyy"];
		[dateFormatter setDateFormat:@"h:mma v, MMM d, yyyy"];
		formattedElapsedTime = [dateFormatter stringFromDate:self];
	}
	
	return formattedElapsedTime;
}

+ (NSDate*)gregorianDate
{
    NSDate* result;
    
    result = [self convertToGregorianFromDate:[NSDate date]];

    return result;
}

+ (NSDate*)gregorianDateWithTimeIntervalSinceNow:(NSTimeInterval)seconds
{
    NSDate* result;
    
    result = [self convertToGregorianFromDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];
    
    return result;
}

+ (NSDate*)convertToGregorianFromDate:(NSDate*)date
{
    NSDate* result;
    @synchronized (self) {
        NSCalendar *gregorianCalendar = objc_getAssociatedObject([UIApplication sharedApplication], @"GregorianCalendar");
        NSDateFormatter *formatter = objc_getAssociatedObject([UIApplication sharedApplication], @"GregorianDateFormatter");
        
        if (gregorianCalendar == nil) {
            gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            
            // TMT: In Unit Test situations there may not be an application object, causing this to crash.
            // In that case we'll skip the association.
            if([UIApplication sharedApplication])
            {
                objc_setAssociatedObject([UIApplication sharedApplication], @"GregorianCalendar", gregorianCalendar, OBJC_ASSOCIATION_RETAIN);
            }
        }
        
        if (formatter == nil) {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setCalendar:gregorianCalendar];
            [formatter setDateStyle:NSDateFormatterFullStyle];
            [formatter setTimeStyle:NSDateFormatterFullStyle];
            // TMT: In Unit Test situations there may not be an application object, causing this to crash.
            // In that case we'll skip the association.
            if([UIApplication sharedApplication])
            {
                objc_setAssociatedObject([UIApplication sharedApplication], @"GregorianDateFormatter", formatter, OBJC_ASSOCIATION_RETAIN);
            }
        }
        
        result = [formatter dateFromString:[formatter stringFromDate:date]];
    }
    
    return result;
}

@end
