//
//  CoreDataHandlerTests.m
//  CoreDataHandlerTests
//
//  Created by aliuekurone on 1/9/14.
//  Copyright (c) 2014 aliueKurone. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "CoreDataHandler.h"

@interface CoreDataHandlerTests : SenTestCase

@property (nonatomic, strong) NSManagedObjectContext *ctx;
@property (nonatomic, strong) NSManagedObjectContext *bgctx;
@end

@implementation CoreDataHandlerTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)testSetupCoreDataStack
{
    // self.ctx = CDSetupCoreDataStackWithDataModelNamed(@"CoreDataModelForTest");
    // self.bgctx = CDBackgroundContextAssociatedWithMainContext(self.ctx);
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample
{
    // STFail(@"Unit tests are not implemented yet in CoreDataHandlerTests");
}

@end
