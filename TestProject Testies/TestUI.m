//
//  TestUI.m
//  TestProject
//
//  Created by Joseph Ridenour on 11/11/13.
//  Copyright (c) 2013 Mercury. All rights reserved.
//

#import <KIF/KIF.h>

@interface UIApplication (Private)
- (BOOL)rotateIfNeeded:(UIDeviceOrientation)orientation;
@end



@interface TestUI : KIFTestCase @end

@implementation TestUI

- (void)beforeAll
{
    [tester waitForViewWithAccessibilityLabel:@"Main TableView"];
    [tester tapRowInTableViewWithAccessibilityLabel:@"Main TableView" atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (void)testScrolling
{
    [tester scrollViewWithAccessibilityLabel:@"Info Scroll View" byFractionOfSizeHorizontal:0 vertical:-.9f];
}

- (void)testFail
{
    [tester tapViewWithAccessibilityLabel:@"no fucking view"];
}

- (void)testScrollingRotation
{
//    [system simulateDeviceRotationToOrientation:UIDeviceOrientationLandscapeLeft];
    [[UIApplication sharedApplication] rotateIfNeeded:UIDeviceOrientationLandscapeLeft];
}

@end