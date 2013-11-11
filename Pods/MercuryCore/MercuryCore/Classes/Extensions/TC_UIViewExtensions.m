//
//  TC_UIViewExtensions.m
//  CNN
//
//  Created by Stephen Tallent on 8/27/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import "TC_UIViewExtensions.h"

#import <QuartzCore/QuartzCore.h>

@implementation UIView (TC_UIViewExtensions)


- (CGImageRef) imageRefFromView{
    CGContextRef renderContext;
    CGColorSpaceRef colorSpace;
    CGImageRef result;
    CGRect bounds;

    /* Set up the render context */
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
	bounds = self.bounds;
    
    renderContext = CGBitmapContextCreate(NULL, bounds.size.width, bounds.size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    if (renderContext == NULL) {
		 /* Clean up */
		CGColorSpaceRelease(colorSpace);
        [NSException raise: NSInternalInconsistencyException format: @"Could not create the render context"];
        return nil;
    }
    
    /* View layers are flipped by default -- reverse the transform. */
    CGAffineTransform mirrorTransform = CGAffineTransformMakeTranslation(0.0, bounds.size.height);
    mirrorTransform = CGAffineTransformScale(mirrorTransform, 1.0, -1.0);
    CGContextConcatCTM(renderContext, mirrorTransform);
    
    /* Render the view */
    [[self layer] renderInContext: renderContext];
    
    /* Output the result */
    result = CGBitmapContextCreateImage(renderContext);
    
    /* Clean up */
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(renderContext);
    
    UIImage *image = [UIImage imageWithCGImage:result];
    CGImageRelease(result);
    
    return image.CGImage;
}

@end
