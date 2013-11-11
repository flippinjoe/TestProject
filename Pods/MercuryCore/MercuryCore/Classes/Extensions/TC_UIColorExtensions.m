//
//  TC_UIColorExtensions.m
//  MercuryCoreDev
//
//  Created by Stephen Tallent on 8/21/08.
//  Copyright 2008 Mercury Intermedia. All rights reserved.
//

#import "TC_UIColorExtensions.h"


@implementation UIColor (TC_UIColorExtensions)

+ (UIColor *) colorFromHexRGB:(NSString *) inColorString
{
	UIColor *result = nil;
	unsigned int colorCode = 0;
	unsigned char redByte, greenByte, blueByte;
	
	if (nil != inColorString)
	{
		NSScanner *scanner = [NSScanner scannerWithString:inColorString];
		(void) [scanner scanHexInt:&colorCode];	// ignore error
	}
	redByte		= (unsigned char) (colorCode >> 16);
	greenByte	= (unsigned char) (colorCode >> 8);
	blueByte	= (unsigned char) (colorCode);	// masks off high bits
	result = [UIColor
			  colorWithRed:		(float)redByte	/ 0xff
			  green:	(float)greenByte/ 0xff
			  blue:	(float)blueByte	/ 0xff
			  alpha:1.0];
	return result;
}

+ (UIColor *) colorFromHexRGBValue: (NSInteger) inColorValue
{
	double			redVal, greenVal, blueVal;

	redVal = (inColorValue >> 16) & 0xff;
	greenVal = (inColorValue >> 8) & 0xff;
	blueVal = inColorValue & 0xff;

	return [UIColor colorWithRed: redVal / 255.0 green:	greenVal / 255.0 blue: blueVal / 255.0 alpha: 1.0];
}

@end
