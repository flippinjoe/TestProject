//
//  HgViewController.m
//  TestProject
//
//  Created by Joseph Ridenour on 10/31/12.
//  Copyright (c) 2012 Mercury. All rights reserved.
//

#import "HgViewController.h"


@interface HgViewController ()

@property (nonatomic, strong) NSDictionary *dataMap;

@end

@implementation HgViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dataMap = [NSDictionary dictionaryWithDictionary:[[NSBundle mainBundle] infoDictionary]];
}


#pragma mark - Helper

- (BOOL)itemAtSectionHasSubItems:(NSInteger)section
{
    id item = self.dataMap[self.dataMap.allKeys[section]];
    return ([item isKindOfClass:[NSDictionary class]] || [item isKindOfClass:[NSArray class]]);
}

- (id)kvAtIndexPath:(NSIndexPath *)indexPath
{
    
    id (^ProcessedItem)(id item) = ^(id item) {
        
        if([item isKindOfClass:[NSNumber class]])
        { return (id)[item stringValue]; }
        if([item isKindOfClass:[NSURL class]])
        { return (id)[item absoluteString]; }
        
        return item;
    };

    id item = self.dataMap[self.dataMap.allKeys[indexPath.section]];
    if([item isKindOfClass:[NSArray class]] || [item isKindOfClass:[NSDictionary class]])
    {
        if([item isKindOfClass:[NSArray class]])
        { return ProcessedItem(item[indexPath.row]); }
        else
        { return ProcessedItem(item[[item allKeys][indexPath.row]]); }
    }
    return ProcessedItem(item);
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{ return [[self.dataMap allKeys] count]; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self itemAtSectionHasSubItems:section] ? [self.dataMap[self.dataMap.allKeys[section]] count] : 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{ return 50; }

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 50)];
    v.backgroundColor = [UIColor lightGrayColor];
    NSDictionary *style = @{@"borderWidth":@(1)};
    [v setValue:style forKeyPath:@"layer.style"];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectInset(v.bounds, 10, 0)];
    l.backgroundColor = [UIColor clearColor];
    l.text = self.dataMap.allKeys[section];
    
//    l.text = [self kvAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    [v addSubview:l];
    return v;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"IDA;SLDFJ";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    id value = [self kvAtIndexPath:indexPath];
cell.detailTextLabel.text = value;
return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *a = @[];
    // Make crash
    id v = a[0];
}

@end
