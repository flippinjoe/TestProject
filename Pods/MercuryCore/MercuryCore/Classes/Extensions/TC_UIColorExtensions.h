//
//  TC_UIColorExtensions.h
//  MercuryCoreDev
//
//  Created by Stephen Tallent on 8/21/08.
//  Copyright 2008 Mercury Intermedia. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIColor (TC_UIColorExtensions)

+ (UIColor *) colorFromHexRGB:(NSString *) inColorString;
+ (UIColor *) colorFromHexRGBValue:(NSInteger) inColorValue;

@end
