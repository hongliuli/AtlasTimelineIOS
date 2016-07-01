//
//  ATDropboxHelper.h
//  AtlasTimelineIOS
//
//  Created by Hong on 6/30/16.
//  Copyright © 2016 hong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import "ATPreferenceViewController.h"
#import "ATEventEditorTableController.h"

@interface ATDropboxHelper : NSObject<DBRestClientDelegate>
@property (nonatomic, strong) DBRestClient *_restClient;
@property (weak, nonatomic) ATPreferenceViewController* preferenceViewController;
@property (weak, nonatomic) ATEventEditorTableController* editorController;

-(void) createFolder:(NSString*)folderName;
-(void) deletePath:(NSString*)pathName;
-(void) loadMetadata:(NSString*)pathName;
-(void) loadFile:(NSString*)pathName intoPath:(NSString*)destinationPath;
-(void) uploadFile:(NSString*)pathName toPath:(NSString*)destinationPath withParentRev:(NSString*)rev fromPath:(NSString*)localPhotoPath;
-(void) loadRevisionsForFile:(NSString*)remotePathFile limit:(int)lmt;

@end
