//
//  StorageLocationTest.m
//  OCEfficient
//
//  Created by aliuekurone on 1/9/14.
//  Copyright (c) 2014 aliueKurone. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "CoreDataHandler.h"


@interface StorageLocationTest : SenTestCase
@end


@implementation StorageLocationTest


- (void)testStorageLocation
{
    NSInteger i = 30;
    while (i--) {
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSURL *url = CDDataStorageURLWithFileNameInAppFolder(@"fileForTest", @"STDataStoreTesting");
        
        if ([fileManager fileExistsAtPath:[url path]]) {
            NSError *error = nil;
            if (NO == [fileManager removeItemAtURL:url error:&error])
                STFail(@"can't remove file");
        }
        
        NSError *error = nil;
        if (NO == [@"test writing" writeToURL:url
                                   atomically:YES
                                     encoding:NSUTF8StringEncoding
                                        error:&error])
        {
            NSLog(@"failed to write");
        }
        if (error)
            NSLog(@"error: %@", [error localizedDescription]);
        
        STAssertTrue([fileManager fileExistsAtPath:[url path]], @"strage file isn't exist");
    }
}

@end
