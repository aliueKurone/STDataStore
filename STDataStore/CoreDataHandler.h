//
//  CoreDataHandler.h
//  CoreDataHandler
//
//  Created by aliuekurone on 1/9/14.
//  Copyright (c) 2014 aliueKurone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCDebugTools/OCDebugTools.h>
@class NSManagedObjectContext, NSManagedObject;


extern NSString * const STSetupOptionsMigrationEnableKey;
extern NSString * const STSetupOptionsiCouldEnableKey;

// データベースファイルを新規作成/開くためのメソッド
extern NSManagedObjectContext *CDSetupCoreDataStackWithDataModelNamed(NSString *dataModelName, NSURL *URLToSave , NSString *storeType, NSDictionary *setupOptions);

extern NSManagedObjectContext *CDBackgroundContextAssociatedWithMainContext(NSManagedObjectContext *mainContext);

/* --- 新しいエンティティを生成する --- */
extern id CDInsertNewObjectOfEntity(NSManagedObjectContext *context, NSString *entityName);

// データの保存処理をする
extern void CDSaveChanges(NSManagedObjectContext *mainContext,
                          NSManagedObjectContext *backgroundContext,
                          void (^resultBlock)(BOOL successful, NSError *error));

extern BOOL CDSaveChangesWithSynchronized(NSManagedObjectContext *mainContext,
                                          NSManagedObjectContext *backgroundContext,
                                          NSError * __autoreleasing * outError);

/* --- データベース内のデータを取得 --- */
extern NSArray *CDAllObjectWithEntityName(NSManagedObjectContext *context, NSString *entityName, NSUInteger fetchLimit);

extern NSArray *CDFetchObjectsWithRequest(NSManagedObjectContext *context, NSFetchRequest *fetchRequest);
extern NSArray *CDFetchObjectEntityNameWithOptions(NSManagedObjectContext *context,
                                                   NSString *entityName,
                                                   NSUInteger fetchLimit,
                                                   NSPredicate *(^predicationBlock)(void),
                                                   NSSortDescriptor *(^sortingBlock)(void));


extern NSUInteger CDCountForObjectWithEntityName(NSManagedObjectContext *context, NSString *entityName);

// 保存されているエンティティを削除する。
extern void CDDeleteObject(NSManagedObjectContext *context, NSManagedObject *object);

// ディレクトリ
extern NSURL *CDDataStorageURLWithFileNameInAppFolder(NSString *fileName, NSString *appDirectoryName);
extern NSURL *CDApplicationSupportFolder(NSString *appDirectoryName) DeprecatedWithMessage("Using CDApplicationFileDirectoryWithName instead");
extern NSURL *CDApplicationFileDirectoryWithName(NSString *directoryName);

#pragma - Options

// UUIDを返却する。
extern NSString * const CDGetIdentifierWithUUID(void);