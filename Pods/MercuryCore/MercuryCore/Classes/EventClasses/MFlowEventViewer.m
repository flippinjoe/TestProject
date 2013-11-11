//
//  MFlowEventViewer.m
//  MFlowEventManagerDev
//
//  Created by Stephen Tallent on 6/22/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import "MFlowEventViewer.h"
#import "MFlowEventManager.h"
#import "MFlowLaunchEvent.h"
#import "MFlowSessionEvent.h"
#import	"MFlowURLClickEvent.h"
#import "MFlowAggEvent.h"
#import "TC_NSDateExtensions.h"

// TODO: Can we depricate this?  It isn't being used.

@implementation MFlowEventViewer
@synthesize targDate;

- (void)loadView {
	
	UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,320,480)];
	v.backgroundColor = [UIColor redColor];
	
	UINavigationBar *bar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0,0,320,44)];
	
	
	UINavigationItem *ii = [[UINavigationItem alloc] initWithTitle:@"Events"];
	[bar pushNavigationItem:ii animated:false];
	
	UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneClicked:)];
	
	bar.topItem.rightBarButtonItem = done;
	[v addSubview:bar];
	
	
	if (targDate == nil) {
		targDate = [NSDate gregorianDate];
	}
	/*
	launchEvents = [[NSMutableArray alloc] initWithArray:[[MFlowEventManager sharedManager] allLaunchEventsBeforeDate:targDate]];
	sessionEvents = [[NSMutableArray alloc] initWithArray:[[MFlowEventManager sharedManager] allSessionEventsBeforeDate:targDate]];
	clickEvents = [[NSMutableArray alloc] initWithArray:[[MFlowEventManager sharedManager] allUrlClickEventsBeforeDate:targDate]];
	nonAggEvents = [[NSMutableArray alloc] initWithArray:[[MFlowEventManager sharedManager] allNonAggEventsBeforeDate:targDate]];
	aggEvents = [[NSMutableArray alloc] initWithArray:[[MFlowEventManager sharedManager] allAggEvents]];
	*/
	
	table = [[UITableView alloc] initWithFrame:CGRectMake(0,44,320,436) style:UITableViewStylePlain];
	[v addSubview:table];
	
	table.dataSource = self;
	table.delegate = self;
	
	
	self.view = v;
	
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"MM/dd/yyyy HH:mm:ss"]; //MM/dd/yyyy HH:mm:ss 
	
}

-(void)doneClicked:(id)sender{
	
	[self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark table dataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	switch (section) {
		case 0:
			return launchEvents.count;
			break;
		case 1:
			return sessionEvents.count;
			break;
		case 2:
			return clickEvents.count;
			break;
		case 3:
			return nonAggEvents.count;
			break;
		case 4:
			return aggEvents.count;
			break;
		default:
			break;
	}
	return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	switch (section) {
		case 0:
			return @"Launch Events";
			break;
		case 1:
			return @"Session Events";
			break;
		case 2:
			return @"URL Click Events";
			break;
		case 3:
			return @"NonAgg Events";
			break;
		case 4:
			return @"Aggregated Events";
			break;
		default:
			break;
	}
	return @"cheese";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	
	MFlowLaunchEvent *launchEvt;
	MFlowSessionEvent *sessionEvt;
	MFlowURLClickEvent *clickEvt;
	MFlowAggEvent *aggEvt;
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"celler"];
	
	if (cell == nil){
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"celler"];
	}
	
	switch (indexPath.section) {
		case 0: //launch events
			
			launchEvt = [launchEvents objectAtIndex:indexPath.row];
			cell.textLabel.text = launchEvt.EventID;
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@",
										 [dateFormatter stringFromDate:launchEvt.LaunchStartTime], 
										 [dateFormatter stringFromDate:launchEvt.LaunchEndTime]];
			
			break;
			
		case 1: //@"Session Events";
			
			sessionEvt = [sessionEvents objectAtIndex:indexPath.row];
			cell.textLabel.text = sessionEvt.EventID;
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  paused:%@", 
										 [dateFormatter stringFromDate:sessionEvt.SessionStartTime], 
										 sessionEvt.SessionPausedSeconds];
			
			break;
			
		case 2: // @"URL Click Events";
			
			clickEvt = [clickEvents objectAtIndex:indexPath.row];
			cell.textLabel.text = clickEvt.EventID;
			cell.detailTextLabel.text = clickEvt.URL;
			
			break;
			
		case 3: // Non Agg Events
			
			aggEvt = [nonAggEvents objectAtIndex:indexPath.row];
			cell.textLabel.text = [dateFormatter stringFromDate:aggEvt.EventTimeStamp]; //aggEvt.EventID;
			cell.detailTextLabel.text = [NSString stringWithFormat:@"EventType: %@ Duration: %@ ItemID: %@", aggEvt.EventType, aggEvt.EventDuration, aggEvt.EventItemID];
			
			break;
			
		case 4: // Sample Events
			
			aggEvt = [aggEvents objectAtIndex:indexPath.row];
			
			//int ii = [aggEvt.AggType intValue];
			if ([aggEvt.AggType intValue] == MFlowEventAggregationTypeSample) {
				cell.textLabel.text = [NSString stringWithFormat:@"SAMPLE: %@",[dateFormatter stringFromDate:aggEvt.EventTimeStamp]];
			} else {
				cell.textLabel.text = [NSString stringWithFormat:@"AGG: %@",[dateFormatter stringFromDate:aggEvt.EventTimeStamp]];
			}

			cell.detailTextLabel.text = [NSString stringWithFormat:@"Type: %@ Dur: %@ IID: %@ Cnt: %@", aggEvt.EventType, aggEvt.EventDuration, aggEvt.EventItemID, aggEvt.EventCount];
			
			break;

		default:
			
			break;
	}
	
	
	return cell;
		
}

#pragma mark -
#pragma mark table delegate


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}




@end
