//
//  MFlowImageView2.m
//  ArchTest1
//
//  Created by Stephen Tallent on 12/29/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import "MFlowImageView2.h"


@implementation MFlowImageView2

@synthesize item, fileGroup;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
		self.clearsContextBeforeDrawing = true;
    }
    return self;
}

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
	
	
	if (item != nil) {
		if ([item compare:itm] == NSOrderedSame) {
			return;
		}
	}
	
	
	if (imagePending && !imageLoaded) {
		[[MFlowFileManager sharedMFlowFileManager] cancelMFlowImage:item];
	}
	
	item = itm;
	
	
	mmm = nil;
	[self setNeedsDisplay];
	
	imagePending = true;
	imageLoaded = false;
	
	[[MFlowFileManager sharedMFlowFileManager] retrieveMFlowImage:item 
													  pleaseCache:false 
														filegroup:(fileGroup != nil) ? fileGroup : defaultFileGroup 
														 delegate:self];
	
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
	if (mmm != nil) {
		[mmm drawInRect:rect];
	} else {
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextClearRect(context, rect);
	}

}

-(void)unloadImage{
	
	if (mmm != nil) {
		mmm = nil;
	}
	
	if (item != nil) {
		item = nil;
	}
	
	imagePending = false;	
	imageLoaded = false;
	
	[self setNeedsDisplay];
	
	return;
}


- (void)fileManagerImageReady:(NSString *)fullURL image:(UIImage *)img{

	//NSLog(@"fileManagerImageReady");
	imageLoaded = true;
	imagePending = false;
	mmm = img;
	[self setNeedsDisplay];

}

- (void)fileManagerImageError:(NSString *)fullURL{
	imageLoaded = false;
	imagePending = false;
}





@end
