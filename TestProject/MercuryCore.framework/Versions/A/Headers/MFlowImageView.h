//
//  MFlowImageView.h
//  ArchTest1
//
//  Created by Stephen Tallent on 12/21/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MFlowItem.h"
#import "MFlowFileManager.h"

@class MFlowImageView;

@protocol MFlowImageViewDelegate <NSObject>
@optional

- (void)imageView: (MFlowImageView *) inImageView loadedImage: (UIImage *) inImage atURL: (NSString *) inURL;
- (void)imageViewImageReady:(NSString *)fullURL image:(UIImage *)img;
- (void)imageViewImageError:(NSString *)fullURL;

@end

@interface MFlowImageView : UIImageView <MFlowFileManagerDelegate>{
	
	MFlowItem *item;
	NSString *fileGroup;
	
	BOOL imagePending;
	BOOL imageLoaded;
	BOOL animate;
	UIImage *mmm;
	
	UIView *previewView;
	
	id<MFlowImageViewDelegate> delegate;

	bool useDiskCache;
}

@property(nonatomic, assign) id<MFlowImageViewDelegate>delegate;
@property(nonatomic, retain) MFlowItem *item;
@property(nonatomic, copy) NSString *fileGroup;
@property(nonatomic, retain) UIView *previewView;
@property(nonatomic, assign) bool useDiskCache;
@property(nonatomic, assign) BOOL animate;

-(void)unloadImage;

@end
