//
//  CoreDataHandler.m
//  CoreDataHandler
//
//  Created by aliuekurone on 1/9/14.
//  Copyright (c) 2014 aliueKurone. All rights reserved.
//

#import "CoreDataHandler.h"
#import <CoreData/CoreData.h>
#import <OCDebugTools/OCDebugTools.h>
#import <libextobjc_OSX/EXTScope.h>


#pragma mark - directory URL to storage file


NSURL *CDApplicationSupportFolder(NSString *appDirectoryName)
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *appDirectoryURL = [appSupportURL URLByAppendingPathComponent:appDirectoryName];
    NSError *error = nil;
    if ([fileManager createDirectoryAtURL:appDirectoryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
        if (error)
            LoggingError(error);
    }
    return appDirectoryURL;
}


NSURL *CDDataStorageURLWithFileNameInAppFolder(NSString *fileName, NSString *appDirectoryName)
{
    NSURL *appFolder = CDApplicationSupportFolder(appDirectoryName);
    
    return [appFolder URLByAppendingPathComponent:fileName];
}


#pragma mark - Set up core data


NSString * const STSetupOptionsMigrationEnableKey = @"SetupOptionsMigrationEnable";
NSString * const STSetupOptionsiCouldEnableKey = @"SetupOptionsiCouldEnableKey";


static inline NSManagedObjectContext *_CDSetupCoreDataStackWithDataModelNamedWithOptions(NSString *detaModelName, NSURL *urlToSave, NSString *storeType, NSDictionary *userInfo)
{
    NSManagedObjectModel *model;
    
    if (detaModelName) {
        /* --- managedObjectContext を作成する --- */
        NSString *modelPath = [[NSBundle mainBundle] pathForResource:detaModelName ofType:@"momd"];
        if (nil == modelPath)
            modelPath = [[NSBundle mainBundle] pathForResource:detaModelName ofType:@"mom"];
        
        if (nil == modelPath) // test code
            modelPath = [[NSBundle bundleForClass:NSClassFromString(@"CoreDataHandlerTests")] pathForResource:detaModelName ofType:@"momd"];
        assert(modelPath);
        
        NSURL *urlModel = [NSURL fileURLWithPath:modelPath];
        model = [[NSManagedObjectModel alloc] initWithContentsOfURL:urlModel];
    }
    else {
        model = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    
    
    if (!model) {
        DebugLog(@"No model to generate a store from");
        return nil;
    }
    
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	model = nil;
    
	NSMutableDictionary *options = nil;
    
	if ([userInfo[STSetupOptionsMigrationEnableKey] isEqualToNumber:@YES]) {
        
        options = [[NSMutableDictionary alloc] init];
		[options setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
		[options setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];
	}
    
	NSURL *storeURL;
    
	if ([userInfo[STSetupOptionsiCouldEnableKey] isEqualToNumber:@YES]) {
        NSCAssert(NO, @"iCouldEnable is enough not to testing");
        
		NSFileManager *fm = [NSFileManager defaultManager];
		NSURL *ubContainer = [fm URLForUbiquityContainerIdentifier:nil];
        
        if (nil == options) options = [[NSMutableDictionary alloc] init];
        
		[options setObject:detaModelName forKey:NSPersistentStoreUbiquitousContentNameKey];
		[options setObject:ubContainer forKey:NSPersistentStoreUbiquitousContentURLKey];
		NSString *noSyncFileName = [detaModelName stringByAppendingString:@".nosync"];
		NSURL *noSyncDir = [ubContainer URLByAppendingPathComponent:noSyncFileName];
		[fm createDirectoryAtURL:noSyncDir withIntermediateDirectories:YES attributes:nil error:nil];
        
		NSString *dbFileName = [detaModelName stringByAppendingString:@".db"];
		storeURL = [noSyncDir URLByAppendingPathComponent:dbFileName];
	}
	else {
        storeURL = urlToSave;
	}
    
	NSError *error = nil;
    
	if (![psc addPersistentStoreWithType:storeType
	                       configuration:nil
				                     URL:storeURL
					             options:options
						           error:&error]) {
		[NSException raise:@"Open failed"
		            format:@"Reason: %@", [error localizedDescription]];
	}
    
	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	[context setPersistentStoreCoordinator:psc];
#if IPHONEOS_DEPLOYMENT_TARGET
	[context setUndoManager:nil];
#endif
    
    return context;
}




NSManagedObjectContext *CDSetupCoreDataStackWithDataModelNamed(NSString *dataModelName, NSURL *URLToSave , NSString *storeType, NSDictionary *setupOptions)
{
    return _CDSetupCoreDataStackWithDataModelNamedWithOptions(dataModelName, URLToSave, storeType,
                                                              @{STSetupOptionsMigrationEnableKey : @NO,
                                                              STSetupOptionsiCouldEnableKey : @NO});
}


NSManagedObjectContext *CDBackgroundContextAssociatedWithMainContext(NSManagedObjectContext *mainContext)
{
    NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	[backgroundContext setParentContext:mainContext];
	[backgroundContext setUndoManager:nil];
    return backgroundContext;
}



#pragma mark - Access to Core Data


id CDInsertNewObjectOfEntity(NSManagedObjectContext *context, NSString *entityName)
{
	id p = [NSEntityDescription insertNewObjectForEntityForName:entityName
	                                     inManagedObjectContext:context];
    
	return p;
}


#pragma mark - Save operation


void CDSaveChanges(NSManagedObjectContext *mainContext,
                   NSManagedObjectContext *backgroundContext,
                   void (^resultBlock)(BOOL successful, NSError *error))
{
    if ((NO == mainContext.hasChanges) &&
        (NO == backgroundContext.hasChanges)) {
        if (resultBlock) {
            resultBlock(NO, nil);
        }
    }
    
    @weakify(mainContext);
    @weakify(backgroundContext);
    
    /* --- save処理はコストがかかるのでサブスレッドで処理 --- */
    [backgroundContext performBlock:^(void){
        @strongify(mainContext);
        @strongify(backgroundContext);
        
        NSError *outError1 = nil;
        [backgroundContext save:&outError1];
        
        if (outError1) {
            DebugLog(@"Unresolved error %@", [outError1 localizedDescription]);
            resultBlock(NO, outError1);
            return;
        }
        
        [mainContext performBlock:^(void){
            
            NSError *outError2 = nil;
            [mainContext save:&outError2];
            
            if (outError2) {
                DebugLog(@"Unresolved error %@", [outError2 localizedDescription]);
                resultBlock(NO, outError2);
                return;
            }
            else {
                resultBlock(YES, nil);
                return;
            }
        }];
    }];
}


BOOL CDSaveChangesWithSynchronized(NSManagedObjectContext *mainContext,
                                   NSManagedObjectContext *backgroundContext,
                                   NSError * __autoreleasing * outError)
{
    if ((NO == mainContext.hasChanges) &&
        (NO == backgroundContext.hasChanges)) {
        return NO;
    }
    
    if (NULL == outError) {
        if ([backgroundContext save:outError] && [mainContext save:outError])
            return YES;
        else
            return NO;
    }
    else {
        if ([backgroundContext save:nil] && [mainContext save:nil])
            return YES;
        else
            return NO;
    }
}



#pragma mark - Fetch data from core data


static inline NSFetchRequest *_CDCreateFetchRequestEntityNameWithOptions(NSManagedObjectContext *context,
                                                                         NSString *entityName,
                                                                         NSUInteger fetchLimit,
                                                                         NSPredicate *(^predicationBlock)(void),
                                                                         NSSortDescriptor *(^sortingBlock)(void))
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    if (NSUIntegerMax != fetchLimit || 0 != fetchLimit)
        request.fetchLimit = fetchLimit;
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
	                                          inManagedObjectContext:context];
	[request setEntity:entity];
	
	/* ----------------
     * predicationBlock内での記述例
     * NSPredicate *predicate = [NSPredicate predicateWithFormat:@"__predicate__"];
     * ---------------- */
	if (nil != predicationBlock) {
        [request setPredicate:predicationBlock()];
    }
	
    /* -----------------
     * sortingBlock内での記述例
     * NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"photoIndex" ascending:YES];
     * [request setSortDescriptors:[NSArray arrayWithObject:sd]];
     *
     *
     * ----------------- */
    if (nil != sortingBlock) {
        [request setSortDescriptors:[NSArray arrayWithObject:sortingBlock()]];
    }
    
    return request;
}


NSArray *CDFetchObjectsWithRequest(NSManagedObjectContext *context,
                                   NSFetchRequest *fetchRequest)
{
    NSError *error = nil;
    NSArray *list = [context executeFetchRequest:fetchRequest error:&error];
    
    DebugLog(@"count of list is %@", @([list count]));
    
    if (error) {
        // Error
        DebugLog(@"method : executeFetchRequest error : %@", [error localizedDescription]);
        return nil;
    }
    
    return list;
}


NSArray *CDFetchObjectEntityNameWithOptions(NSManagedObjectContext *context,
                                            NSString *entityName,
                                            NSUInteger fetchLimit,
                                            NSPredicate *(^predicationBlock)(void),
                                            NSSortDescriptor *(^sortingBlock)(void))
{
    @autoreleasepool {
        
        NSFetchRequest *request = _CDCreateFetchRequestEntityNameWithOptions(context,
                                                                             entityName,
                                                                             fetchLimit,
                                                                             predicationBlock,
                                                                             sortingBlock);
        
        CDFetchObjectsWithRequest(context, request);
        
        NSError *error = nil;
        NSArray *list;
        list = [context executeFetchRequest:request error:&error];
        request = nil;
        
        DebugLog(@"count of list is %@", @([list count]));
        
        if (error) {
            // Error
            DebugLog(@"method : executeFetchRequest error : %@", [error localizedDescription]);
            return nil;
        }
        
        return list;
    }
}


NSUInteger CDCountForObjectWithEntityName(NSManagedObjectContext *context, NSString *entityName)
{
    @autoreleasepool {
        
        NSFetchRequest *request = _CDCreateFetchRequestEntityNameWithOptions(context,
                                                                             entityName,
                                                                             NSUIntegerMax,
                                                                             nil,
                                                                             nil);        
        NSError *error = nil;
        NSUInteger countOfObject = [context countForFetchRequest:request error:&error];
        request = nil;        
        
        if (error) {
            // Error
            DebugLog(@"method : executeFetchRequest error : %@", [error localizedDescription]);
            return NSUIntegerMax;
        }
        
        return countOfObject;
    }
}


NSArray *CDAllObjectWithEntityName(NSManagedObjectContext *context, NSString *entityName, NSUInteger fetchLimit)
{
    return CDFetchObjectEntityNameWithOptions(context, entityName, fetchLimit, nil, nil);
}


void CDDeleteObject(NSManagedObjectContext *context, NSManagedObject *object)
{
    [context deleteObject:object];
}


#pragma - Other Functions


NSString * const CDGetIdentifierWithUUID(void)
{
    @autoreleasepool {
        CFUUIDRef uuid;
        uuid = CFUUIDCreate(NULL);
        NSString *identifier = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
        
        return identifier;
    }
}