//
//  MFlowImageView2.h
//  ArchTest1
//
//  Created by Stephen Tallent on 12/29/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MFlowItem.h"
#import "MFlowFileManager.h"

@interface MFlowImageView2 : UIView <MFlowFileManagerDelegate> {

	MFlowItem *item;
	NSString *fileGroup;
	
	BOOL imagePending;
	BOOL imageLoaded;
	
	UIImage *mmm;

	
}

@property(nonatomic, strong) MFlowItem *item;
@property(nonatomic, copy) NSString *fileGroup;


-(void)unloadImage;

@end
