//
//  MFlowEventViewer.h
//  MFlowEventManagerDev
//
//  Created by Stephen Tallent on 6/22/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MFlowEventViewer : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	
	UITableView *table;
	
	NSMutableArray *launchEvents;
	NSMutableArray *sessionEvents;
	NSMutableArray *clickEvents;
	NSMutableArray *nonAggEvents;
	NSMutableArray *aggEvents;
	
	NSDateFormatter *dateFormatter;
	
	NSDate *targDate;
}

@property(nonatomic, copy)NSDate *targDate;

@end
