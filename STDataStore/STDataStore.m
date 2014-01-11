//
//  MultiThreadingDataStore.m
//  CoreDataExperiment
//
//  Created by aliuekurone on 12/26/13.
//  Copyright (c) 2013 aliuekurone. All rights reserved.
//

#import "STDataStore.h"
#import "CoreDataHandler.h"
#import "OCDebugTools/OCDebugTools.h"
#import "libextobjc_OSX/EXTScope.h"


@interface STDataStore ()

- (void)_setupCoreDataStack;

@property(nonatomic, readonly) NSManagedObjectContext *backgroundContext;
@end

@implementation STDataStore


#pragma mark - singleton process

+ (instancetype)defaultStore
{
    static dispatch_once_t once;
    static id sharedInstance = nil;
    
    dispatch_once(&once, ^ {
        sharedInstance = [[super allocWithZone:nil] init];
    });
    
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self defaultStore];
}


- (id)init
{
    self = [super init];

    if (self) {
        [self _setupCoreDataStack];
    }
    return self;
}



- (void)awakeFromNib
{
    [super awakeFromNib];
    [self _setupCoreDataStack];
}


- (void)_setupCoreDataStack
{
    KZAssertMainThread();
    if (_mainContext) return;

    _mainContext = CDSetupCoreDataStackWithDataModelNamed(nil, [self dataStorageURL], NSSQLiteStoreType, nil);
    _backgroundContext = CDBackgroundContextAssociatedWithMainContext(_mainContext);
}


- (NSURL *)dataStorageURL
{
    return CDDataStorageURLWithFileNameInAppFolder(@"dbfile", @"appName");
}


- (id)createNewObjectOfEntity:(NSString *)entityName
{
    id p = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                         inManagedObjectContext:self.mainContext];

    return p;
}


- (void)saveChanges:(void (^)(BOOL successful, NSError *error))resultBlock
{
    CDSaveChanges(self.mainContext, self.backgroundContext, resultBlock);
}


- (BOOL)saveChangesWithSynchronized:(out NSError * __autoreleasing *)outError
{
    return CDSaveChangesWithSynchronized(self.mainContext, self.backgroundContext, outError);
}


#pragma mark - Fetch data from core data


- (NSArray *)fetchObjectEntityNameWithOptions:(NSString *)entityName
                               predicateBlock:(NSPredicate *(^)(void))predicationBlock
                                 sortingBlock:(NSSortDescriptor *(^)(void))sortingBlock
{
    return CDFetchObjectEntityNameWithOptions(self.mainContext, entityName, NSUIntegerMax, predicationBlock, sortingBlock);
}


- (NSArray *)allObjectWithEntityName:(NSString *)entityName
{    
    return [self fetchObjectEntityNameWithOptions:entityName
                                   predicateBlock:nil
                                     sortingBlock:nil];
}


- (void)deleteObject:(NSManagedObject *)object
{
    [self.mainContext deleteObject:object];
}


@end
