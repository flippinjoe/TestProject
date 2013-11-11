//
//  TestProject_Testies.m
//  TestProject Testies
//
//  Created by Joseph Ridenour on 6/25/13.
//  Copyright (c) 2013 Mercury. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface TestProject_Testies : XCTestCase

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
    XCTAssertTrue(1!=2, @"COMPILER IS HAPPY");
}

- (void)testPassed
{
//    STFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
