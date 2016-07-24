//
//  ATEventEditorTableController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 1/16/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATEventAnnotation.h"
#import "ATViewImagePickerController.h"
#import "ATPhotoScrollView.h"
#import <DropboxSDK/DropboxSDK.h>

@protocol EventEditorDelegate ;

@class ATViewController;
@class ATEventEntity;
@class ATEventDataStruct;

@interface ATEventEditorTableController : UITableViewController <UITextFieldDelegate, ATImagePickerDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
{
    ATEventAnnotation * annotation;
}
@property int hasPhotoFlag;
@property int eventType;
@property ATPhotoScrollView* photoScrollView;
@property (strong, nonatomic) UIImageView* selectedPhoto; //set by ATPhotoScrollView didRowSelected
@property CLLocationCoordinate2D coordinate;
@property (strong, nonatomic) NSString* eventId;

@property (weak, nonatomic) IBOutlet UITextView *description;
@property (weak, nonatomic) IBOutlet UITextView *address;
@property (weak, nonatomic) IBOutlet UITextField *dateTxt;

@property(strong, nonatomic) UIDatePicker *datePicker;
@property(strong, nonatomic) UIToolbar *toolbar;

@property (weak) id<EventEditorDelegate> delegate;

//following button outlet is for disable/enable programly
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property BOOL isFirstTimeAddPhoto;
@property BOOL photoDescChangedFlag;

@property ATEventDataStruct* eventData;

- (IBAction)saveAction:(id)sender;
- (IBAction)deleteAction:(id)sender;
- (IBAction)cancelAction:(id)sender;


- (void)changeDateInLabel:(id)sender;
- (void)datePicked:(id)sender;
- (void)createPhotoScrollView:(NSString*) photoDirName eventDesc:(NSString*)descText;
- (void)showPhotoView:(int)photoFileName image:(UIImage*)image;
- (void)deleteCallback:(NSString*) photoFileName;
- (void)resetEventEditor;
- (void)setShareCount;
- (void)updatePhotoCountLabel;

//these can easily be assigne to BasePhotoViewController, but ImageScrollView also need, so make them static
+ (NSArray*) photoList;
+ (NSString*) eventId;
+ (void)setEventId:(NSString*)eventId;
+ (int) selectedPhotoIdx;
+ (void) setSelectedPhotoIdx:(int)idx;

- (void) loadedMetadataCallback:(DBMetadata*)metadata;
- (void) loadMetadataFailedWithErrorCallback:(NSError*)error;
- (void) loadedFileCallback:(NSString*)localPath contentType:(NSString*)contentType metadata:(DBMetadata*)metadata;
- (void) loadFileFailedWithErrorCallback:(NSError*)error;
- (void) loadedRevisionsCallback:(NSArray *)revisions forFile:(NSString *)path;
- (void) loadRevisionsFailedWithErrorCallback:(NSError *)error;

@end

// I can save/delete Core Data here, but I will let these to be done in mapview by delegate since we have pass info back to update annotation view when save/delete
//ATViewController is designed to conform to this protocal, so it need implement
@protocol EventEditorDelegate <NSObject>
@required
- (void)deleteEvent; //ATViewController will delete the selectedAnnotation, so no need to pass parameter
- (void)updateEvent:(ATEventDataStruct*)newData newAddedList:(NSArray *)newAddedList deletedList:(NSArray*)deletedList photoMetaData:(NSDictionary *)photoMetaData;
- (void)cancelEvent;
- (void)restartEditor;
- (void)addToEpisode;
- (BOOL)isInEpisode;

@end

@interface APActivityProvider : UIActivityItemProvider <UIActivityItemSource>
@property ATEventEditorTableController* eventEditor;
@end