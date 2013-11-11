//
//  MFlowImageView.m
//  ArchTest1
//
//  Created by Stephen Tallent on 12/21/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import "MFlowImageView.h"
#import <QuartzCore/QuartzCore.h>

@implementation MFlowImageView

@synthesize item, fileGroup, delegate, previewView, useDiskCache, animate;


-(void)setItem:(MFlowItem *)itm{

	if (itm == nil && imageLoaded) {
		
		[self unloadImage];
		
		return;
	}
	
	
	if (itm == nil && imagePending) {
		
		[[MFlowFileManager sharedMFlowFileManager] cancelMFlowImage:item];
		
		[self unloadImage];
		
		return;
		
	}
	
	if (itm == nil) {
		return;
	}
	
	if (item != nil) {
		if ([item compare:itm] == NSOrderedSame) {
			return;
		}
	}
	
	
	if (imagePending && !imageLoaded) {
		[[MFlowFileManager sharedMFlowFileManager] cancelMFlowImage:item];
	}
	
	item = itm;
	
	self.image = nil;
	[self addSubview:previewView];
	
	imagePending = true;
	imageLoaded = false;
	
	if (useDiskCache) {
		UIImage *img = [[MFlowFileManager sharedMFlowFileManager] imageFromCache:item filegroup:(fileGroup != nil) ? fileGroup : defaultFileGroup];
		if (img != nil) {
			NSString *fullURL = @"";
			[self fileManagerImageReady:fullURL image:img];
			return;
		}
	}
	
	[[MFlowFileManager sharedMFlowFileManager] retrieveMFlowImage:item 
													  pleaseCache:true 
														filegroup:(fileGroup != nil) ? fileGroup : defaultFileGroup 
														 delegate:self];
	
}

-(void)unloadImage{
	
	self.image = nil;
	
	if (item != nil) {
		item = nil;
	}
	
	imagePending = false;	
	imageLoaded = false;
		
	return;
}

- (void)fileManagerImageReady:(NSString *)fullURL image:(UIImage *)img{

	imageLoaded = true;
	imagePending = false;
	self.image = img;
	
    
    if (animate) {
		[UIView animateWithDuration: 0.5 animations: ^{
			previewView.alpha = 0.0;
		} completion: ^(BOOL inFinshed) {
			[previewView removeFromSuperview];
		}];
    }
    else  {
        [previewView removeFromSuperview];
    }

	if (self.delegate != nil) {
		if ([self.delegate respondsToSelector:@selector(imageViewImageReady:image:)])
			[self.delegate imageViewImageReady: fullURL image: img];
		else if ([self.delegate respondsToSelector:@selector(imageView:loadedImage:atURL:)])
			[self.delegate imageView: self loadedImage: img atURL: fullURL];
	}
}

- (void)fileManagerImageError:(NSString *)fullURL{
	imageLoaded = false;
	imagePending = false;
	
	if (delegate != nil) {
		if ([self.delegate respondsToSelector:@selector(imageViewImageError:)])
			[delegate imageViewImageError:fullURL];
	}
}


- (void)dealloc {
	
    [self.layer removeAllAnimations];
	// TMT: 082910 releasing preview in case the image never loaded and it is still around
	
	
}


@end
