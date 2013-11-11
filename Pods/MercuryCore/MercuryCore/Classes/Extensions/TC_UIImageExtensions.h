//
//  TC_UIImageExtensions.h
//  Mercury Core
//
//  Created by Michael Morrison on 1/22/10.
//  Copyright 2010 Mercury Intermedia. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	RoundCornerImageCornerNone = 0,
	RoundCornerImageCornerUpperLeft = 1,
	RoundCornerImageCornerUpperRight = 2,
	RoundCornerImageCornerLowerLeft = 4,
	RoundCornerImageCornerLowerRight = 8,
	RoundCornerImageCornerAll = (RoundCornerImageCornerUpperLeft | RoundCornerImageCornerUpperRight | RoundCornerImageCornerLowerLeft | RoundCornerImageCornerLowerRight)
} RoundCornerImageCorner;

@interface UIImage (TC_UIImageExtensions)

+(UIImage *)imageNamed:(NSString *)name useCache:(BOOL)cache;

// Resize
- (UIImage *)croppedImage:(CGRect)bounds;
- (UIImage *)thumbnailImage:(NSInteger)thumbnailSize transparentBorder:(NSUInteger)borderSize cornerRadius:(NSUInteger)cornerRadius interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resizedImage:(CGSize)newSize interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode bounds:(CGSize)bounds interpolationQuality:(CGInterpolationQuality)quality;

// Rounded Corner
//- (UIImage *)roundedCornerImage:(NSInteger)cornerSize borderSize:(NSInteger)borderSize;
- (UIImage *)roundedCornerImageWithCorners:(RoundCornerImageCorner)corners cornerSize:(NSInteger)cornerSize borderSize:(NSInteger)borderSize;
- (UIImage *)roundedCornerImage:(NSInteger)cornerSize borderSize:(NSInteger)borderSize;

// Alpha
- (BOOL)hasAlpha;
- (UIImage *)imageWithAlpha;
- (UIImage *)transparentBorderImage:(NSUInteger)borderSize;

@end
