//
//  ATDataController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 1/9/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATEventEntity;
@class ATEventDataStruct;

@interface ATDataController : NSObject {
    //This set is for storing events
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSString* databaseFileName;
}
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;


- (ATDataController*) initWithDatabaseFileName: (NSString*) dbFileName;
- (NSArray*) fetchAllEventEntities;
- (ATEventEntity*) addEventEntityAddress:(NSString*)addressPar description:(NSString*)descriptionPar date:(NSDate*)datePar lat:(double)latPar lng:(double)lngPar type:(int)eventType  uniqueId:(NSString*)uniqueId;
- (ATEventEntity*) updateEvent:(NSString*)uniqueId EventData:(ATEventDataStruct*)newDate;
- (void) deleteEvent:(NSString*)uniqueId;
- (void) deleteAllEvent;

- (void) insertNewPhotoQueue:(NSString*)eventIdPhotoNamePath;
- (void) insertDeletedPhotoQueue:(NSString*)eventIdPhotoNamePath;
- (void) emptyNewPhotoQueue:(NSString*)eventIdPhotoNamePath;
- (void) emptyDeletedPhotoQueue:(NSString*)eventIdPhotoNamePath;
- (NSString*) popNewPhotoQueue;
- (NSString*) popDeletedPhototQueue;
- (int) getNewPhotoQueueSize;
- (int) getDeletedPhotoQueueSize;



@end
