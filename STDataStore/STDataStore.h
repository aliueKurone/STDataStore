//
//  MultiThreadingDataStore.h
//  CoreDataExperiment
//
//  Created by aliuekurone on 12/26/13.
//  Copyright (c) 2013 aliuekurone. All rights reserved.
//

#import <Cocoa/Cocoa.h>



@interface STDataStore : NSObject

+ (instancetype)defaultStore;

- (NSURL *)dataStorageURL;

@property(nonatomic, readonly) NSManagedObjectContext *mainContext;

- (id)createNewObjectOfEntity:(NSString *)entityName;

- (void)saveChanges:(void (^)(BOOL successful, NSError *error))resultBlock;
- (BOOL)saveChangesWithSynchronized:(out NSError * __autoreleasing *)outError;

- (NSArray *)allObjectWithEntityName:(NSString *)entityName;
- (void)deleteObject:(NSManagedObject *)object;




// for debug
// - (void)insertDummyRecordOfCount:(NSInteger)count;
@end
