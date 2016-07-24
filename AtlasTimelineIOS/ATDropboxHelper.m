//
//  ATDropboxHelper.m
//  AtlasTimelineIOS
//
//  Created by Hong on 6/30/16.
//  Copyright © 2016 hong. All rights reserved.
//

#import "ATDropboxHelper.h"
#import "ATHelper.h"

@implementation ATDropboxHelper

//Because of the DBRestClient's asynch nature, I have to implement a synchronous way:
/*
 * 1. create /ChronicleMap fold. if success or fail with already-exists then create Source Folder (such as myEvents)
 * 2. if detected create Source success or already exist, then call startProcessNewPhotoQueueChainAction(), which will pop one photo entry
 * 3. in startProcessNewPhotoQueueChainAction() do:
 *      . popup one photo entry, save to a global var currentPhotoEventPath
 *      . create event dir. In createFolder delegate, if success or already exist, call restClient uploadFile(currentPhotoEnventPath)
 * 4. in uploadFile success delegate:
 *      . delete from sqlite queue
 *      . call startProcessNewPhotoQueueChainAction() which loops back to popup next photo from newAddedPhotoQueue table
 *
 * For delete should be simpler
 */

-(void) createFolder:(NSString*)folderName
{
    [[self myRestClient] createFolder:folderName];
}

-(void) deletePath:(NSString*)pathName
{
    [[self myRestClient] deletePath:pathName];
}

-(void) loadMetadata:(NSString*)pathName
{
    [[self myRestClient] loadMetadata:pathName];
}

-(void) loadFile:(NSString*)pathName intoPath:(NSString*)destinationPath
{
    [[self myRestClient] loadFile:pathName intoPath:destinationPath];
}

-(void) loadRevisionsForFile:(NSString*)remotePathFile limit:(int)lmt
{
    [[self myRestClient] loadRevisionsForFile:remotePathFile limit:lmt];
}

//this is createFolder delegate, important of my chain action
- (void)restClient:(DBRestClient*)client createdFolder:(DBMetadata*)folder{
    [self.preferenceViewController createdFolderCallback:folder];
}

- (void)restClient:(DBRestClient*)client loadedRevisions:(NSArray *)revisions forFile:(NSString *)path
{
    if (self.preferenceViewController != nil)
        [self.preferenceViewController loadedRevisionsCallback:revisions forFile:path];
    else
        [self.editorController loadedRevisionsCallback:revisions forFile:path];
    
}

-(void) uploadFile:(NSString*)pathName toPath:(NSString*)destinationPath withParentRev:(NSString*)rev fromPath:localPhotoPath
{
    [[self myRestClient] uploadFile:pathName toPath:destinationPath withParentRev:rev fromPath:localPhotoPath];
}

- (void)restClient:(DBRestClient*)client loadRevisionsFailedWithError:(NSError *)error
{
    if (self.preferenceViewController != nil)
        [self.preferenceViewController loadRevisionsFailedWithErrorCallback:error];
    else
        [self.editorController loadRevisionsFailedWithErrorCallback:error];
}

// Folder is the metadata for the newly created folder
- (void)restClient:(DBRestClient*)client createFolderFailedWithError:(NSError*)error{
    //if error is folder alrady exist, then continues our chain action
    [self.preferenceViewController createFolderFailedWithErrorCallback:error];
}

- (void)restClient:(DBRestClient*)client deletedPath:(NSString *)path
{
    [self.preferenceViewController deletedPathCallback:path];
}
- (void)restClient:(DBRestClient*)client deletePathFailedWithError:(NSError*)error
{
    [self.preferenceViewController deletePathFailedWithErrorCallback:error];
}

//following loadedMetadata delegate is for copy from dropbox to device. When it come here after loadMetaData() called with eventId
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    if (self.preferenceViewController != nil)
        [self.preferenceViewController loadedMetadataCallback:metadata];
    else
        [self.editorController loadedMetadataCallback:metadata];
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
    if (self.preferenceViewController != nil)
        [self.preferenceViewController loadMetadataFailedWithErrorCallback:error];
    else
        [self.editorController loadMetadataFailedWithErrorCallback:error];
}
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath
       contentType:(NSString*)contentType metadata:(DBMetadata*)metadata {
    if (self.preferenceViewController != nil)
        [self.preferenceViewController loadedFileCallback:localPath contentType:contentType metadata:metadata];
    else
        [self.editorController loadedFileCallback:localPath contentType:contentType metadata:metadata];
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
    if (self.preferenceViewController != nil)
        [self.preferenceViewController loadFileFailedWithErrorCallback:error];
    else
        [self.editorController loadFileFailedWithErrorCallback:error];
}

//delegate called by upload to dropbox
- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    [self.preferenceViewController uploadedFileCallback:destPath from:srcPath metadata:metadata];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    [self.preferenceViewController uploadFileFailedWithErrorCallback:error];
}

- (DBRestClient *)myRestClient {
    if (!self._restClient) {
        self._restClient =
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self._restClient.delegate = self;
    }
    return self._restClient;
}

@end
