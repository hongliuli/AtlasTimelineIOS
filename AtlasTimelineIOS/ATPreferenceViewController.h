//
//  ATPreferenceViewController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 1/25/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATSourceChooseViewController.h"
#import "ATDownloadTableViewController.h"
#import "ATViewController.h"
#import <DropboxSDK/DropboxSDK.h>

@interface ATPreferenceViewController : UITableViewController <SourceChooseViewControllerDelegate,DownloadTableViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) ATViewController* mapViewParent;


- (void) changeSelectedSource:(NSString*)selectedAtlasName;
- (void) refreshDisplayStatusAndData;
- (void) startDownloadMyEventsJson;
- (void) startExport;
- (void) changeDownloadCounter;

- (void) deletedPathCallback:(NSString *)path;
- (void) deletePathFailedWithErrorCallback:(NSError*)error;
- (void) createdFolderCallback:(DBMetadata*)folder;
- (void) createFolderFailedWithErrorCallback:(NSError*)error;
- (void) loadedMetadataCallback:(DBMetadata*)metadata;
- (void) loadMetadataFailedWithErrorCallback:(NSError*)error;
- (void) loadedFileCallback:(NSString*)localPath contentType:(NSString*)contentType metadata:(DBMetadata*)metadata;
- (void) loadFileFailedWithErrorCallback:(NSError*)error;
- (void) loadedRevisionsCallback:(NSArray *)revisions forFile:(NSString *)path;
- (void) loadRevisionsFailedWithErrorCallback:(NSError *)error;
- (void) uploadedFileCallback:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata;
- (void) uploadFileFailedWithErrorCallback:(NSError*)error;

@end
