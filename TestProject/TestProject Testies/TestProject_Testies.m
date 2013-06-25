//
//  TestProject_Testies.m
//  TestProject Testies
//
//  Created by Joseph Ridenour on 6/25/13.
//  Copyright (c) 2013 Mercury. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface TestProject_Testies : SenTestCase

@end

@implementation TestProject_Testies

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testSucceed
{
    STAssertTrue(1!=2, @"COMPILER IS HAPPY");
}

- (void)testFail
{
    STFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
