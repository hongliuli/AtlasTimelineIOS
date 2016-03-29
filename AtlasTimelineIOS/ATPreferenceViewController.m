//
//  ATPreferenceViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 1/25/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <DropboxSDK/DropboxSDK.h>
#import "ATDataController.h"
#import "ATPreferenceViewController.h"
#import "ATDownloadTableViewController.h"
#import "ATConstants.h"
#import "ATHelper.h"
#import "ATAppDelegate.h"
#import "ATEventDataStruct.h"
#import "ATHelpWebView.h"
#import "ATInAppPurchaseViewController.h"
#import "ATOptionsTableViewController.h"
#import "SWRevealViewController.h"

#define EVENT_TYPE_NO_PHOTO 0
#define EVENT_TYPE_HAS_PHOTO 1

#define SECTION_LOGIN_EMAIL 0
#define SECTION_CONTENT_MANAGE 1
#define SECTION_SYNC_MYEVENTS_PHOTO_TO_DROPBOX 2
#define SECTION_MISC 3

#define ROW_SYNC_TO_DROPBOX 0
#define ROW_SYNC_TO_DROPBOX_ALL 1
#define ROW_SYNC_FROM_DROPBOX 2

#define ROW_INBOX 0
#define ROW_CONTENT_MG_MY_EPISODE 1

#define ROW_OPTIONS 0
#define ROW_VIDEO_TUTORIAL 1
#define ROW_PURCHASE 2
#define ROW_RESTORE_PURCHASE 3
#define IN_APP_PURCHASED @"IN_APP_PURCHASED"
#define RESTORE_PHOTO_TITLE NSLocalizedString(@"Restore Photos",nil)

#define FOR_SHARE_MY_EVENTS 1

#define DOWNLOAD_REPLACE_MY_SOURCE_TO_MYEVENTS_ALERT 100
#define DOWNLOAD_MYEVENTS_CONFIRM 101

#define PHOTO_META_FILE_NAME @"MetaFileForOrderAndDesc"
#define PHOTO_ALREAD_IN_LOCAL_SKIP_DOWNLOAD -1;
#define PHOTO_NOT_IN_LOCAL_START_DOWNLOAD 1

@interface ATPreferenceViewController ()

@end

@implementation ATPreferenceViewController
{
    NSString* _source;
    ATInAppPurchaseViewController* purchase; //have to be "global", otherwise error
    NSString* deleteEventIdPhotoName;
    ATDataController* privateDataController;
    NSString* currentEventId;
    NSString* currentPhotoName;
    NSArray* downloadedMyEventsJsonArray;
    int uploadSuccessExcludeThumbnailCount;
    int deleteCount;
    long downloadFromDropboxStartCount;
    int downloadFromDropboxSuccessCount;
    int totalDownloadFromDropboxSuccessCount;
    int downloadFromDropboxFailCount;
    int downloadFromDropboxLoadMedadataFailCount;
    int downloadAlreadyExistCount;
    BOOL onlyShowOnceForIssueWithDropbox;
    int totalPhotoCountInDevice;
    BOOL isEventDir;
    BOOL isRemoveSourceForUploadAll;
    BOOL showDownloadAllLoadMetadataErrorAlert;
    NSMutableArray* eventIdQueueToCopyPhotoFromDropbox;
    NSMutableArray* photoNameQueueForCurrentEventIdFromDropbox;
    UIActivityIndicatorView* spinner;
    
    UIAlertView* uploadAlertView;
    UIAlertView* uploadAllToDropboxAlert;
    UIAlertView* downloadAllFromDropboxAlert;
    UIAlertView* confirmUploadAllPhotoAlertView;
    UIAlertView* confirmUploadContentAlertView;
    
    UITableViewCell* PhotoToDropboxCell;
    UITableViewCell* photoFromDropboxCell;
    
    UIButton* logoutButton;
    UILabel* loginEmailLabel;
    
    BOOL hasNewIncomingShareFlag;
    NSString* currentEventMetapath;
    UIProgressView* progressDownloadOveralView;
    UIProgressView* progressDownloadDetailView;
    int progressDownloadTotalNumberOfEvents;
    int progressDownloadTotalNumberOfPhotosInOneEvent;
    int progressDownloadEventCount;
    int progressDownloadPhotoCount;
    
    UIProgressView* progressUploadView;
    int progressUploadTotalCount;
    int progressUploadPhotoCount;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    hasNewIncomingShareFlag = false;
    spinner = [[UIActivityIndicatorView alloc]
               initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.frame = CGRectMake(0,0,60,60);
    spinner.center =  CGPointMake(160, 200); //set self.view center does not work
    //spinner.hidesWhenStopped = YES;
    [[self  view] addSubview:spinner];
    self.detailLabel.text = _source;
    
    SWRevealViewController* revealController = [self revealViewController];
    UIBarButtonItem *timelineBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"arrow-right.png"] style:UIBarButtonItemStylePlain target:revealController action:@selector(rightRevealToggle:)];
    self.navigationItem.leftBarButtonItem = timelineBarButtonItem;
    
    [self refreshDisplayStatusAndData];
    
    UISwipeGestureRecognizer *rightSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight)];
	rightSwiper.direction = UISwipeGestureRecognizerDirectionRight;
	[self.view addGestureRecognizer:rightSwiper];
}

- (void)swipeRight {
	SWRevealViewController *revealController = [self revealViewController];
    [revealController rightRevealToggle:nil];
}

- (void)refreshDisplayStatusAndData
{
    //Check if there are new incoming. This logic is duplicated from ATDownloadViewController
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString *userId = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
    NSString *securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
    if (userId == nil)
        return;
    NSString* serviceUrl = [NSString stringWithFormat:@"%@/retreivelistofcontents?user_id=%@&security_code=%@",[ATConstants ServerURL], userId, securityCode];
    NSString* responseStr = [ATHelper httpGetFromServer:serviceUrl :false];
    NSArray* libraryList = nil;
    if (responseStr == nil)
        return;
    else
        libraryList = [responseStr componentsSeparatedByString:@"|"];
    for (int i=0; i< [libraryList count]; i++)
    {
        NSString* item = libraryList[i];
        if (item != nil && [item hasPrefix:@"1*"])
        {
            hasNewIncomingShareFlag = true;
            break;
        }
    }
}


//This is delegate, will be called from ATDownloadTableView didSelect..
- (void)downloadTableViewController: (ATDownloadTableViewController *)controller
                   didSelectSource:(NSString *)source{
    //########################################
    // If user select a large period, then map may be slow if there is too many annotations. but I could not do anything to prevent it.
    //########################################
    _source = source;
    self.detailLabel.text = _source ;
    [ATHelper setSelectedDbFileName:_source];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate emptyEventList];
    [appDelegate.mapViewController cleanAnnotationToShowImageSet];
    [appDelegate.mapViewController prepareMapView];
    [appDelegate.mapViewController refreshEventListView:false];
    [self.navigationController popViewControllerAnimated:YES];
    isRemoveSourceForUploadAll = false;
    [self.tableView reloadData]; //reload so active source name will be display when back to preference view
    
    SWRevealViewController* revealController = [self revealViewController];
    [revealController rightRevealToggle:nil];
}

- (void)sourceChooseViewController: (ATSourceChooseViewController *)controller
                  didSelectEpisode:(NSString *)episodeName{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.mapViewController loadEpisode:episodeName];
    //  ???????   TODO does not work , why   ??????????
    [appDelegate.mapViewController cancelPreference];
    [self.navigationController removeFromParentViewController];
    [self dismissViewControllerAnimated:NO completion:nil]; //for iPhone case
    
    SWRevealViewController* revealController = [self revealViewController];
    [revealController rightRevealToggle:nil];
}

//called by download window after downloaded a source
-(void) changeSelectedSource:(NSString*)selectedAtlasName
{
    _source = selectedAtlasName;
    self.detailLabel.text = selectedAtlasName;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//prepareForSegue() is useful for pass values to called storyboard objects
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"share_my_episode"]) {
        ATSourceChooseViewController *sourceChooseViewController = segue.destinationViewController;
        sourceChooseViewController.delegate = self;
        sourceChooseViewController.source = _source;
        sourceChooseViewController.requestType = FOR_SHARE_MY_EVENTS;
    }
    if ([segue.identifier isEqualToString:@"options_id"]) {
        ATOptionsTableViewController *optionPage = segue.destinationViewController;
        optionPage.parent = self;
    }
    if ([segue.identifier isEqualToString:@"download"]) {
        ATDownloadTableViewController *downloadTableViewController = segue.destinationViewController;
        downloadTableViewController.delegate = self;
        downloadTableViewController.parent = self;
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        _source = [ATHelper getSelectedDbFileName];
    }
    return self;
}

- (void)startExport
{
    Boolean successFlag = [ATHelper checkUserEmailAndSecurityCode:self];
    if (!successFlag)
    {
        //Need alert again?  checkUserEmailAndSecurityCode already alerted
        return;
    }
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString* sourceName = appDelegate.sourceName;
    if (![@"myEvents" isEqualToString:sourceName])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"myEvents need to be shown on map",nil) message:NSLocalizedString(@"Please pick myEvents to show on map and try again",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
        return;
    }
    NSUInteger cnt = [appDelegate.eventListSorted count];
    
    uploadAlertView = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"Sync %i events to %@ on server",nil),cnt, [ATHelper getSelectedDbFileName]]
                                                message: [NSString stringWithFormat:NSLocalizedString(@"WARNING: Export will replace existing %@ event data on server.",nil),_source]
                                               delegate: self
                                      cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                      otherButtonTitles:NSLocalizedString(@"Export & Replace",nil),nil];
    
    
    [uploadAlertView show];
    
    
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == DOWNLOAD_REPLACE_MY_SOURCE_TO_MYEVENTS_ALERT )
    {
        if (buttonIndex == 0)
            return; //user clicked cancel button
        UIAlertView* alert  = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Confirm to replace %@ contents in your device!",nil),[ATHelper getSelectedDbFileName]]
                                                         message:NSLocalizedString(@"Enter agree to continue:",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        UITextField * aa = [alert textFieldAtIndex:0];
        aa.placeholder = @"agree";
        alert.tag = DOWNLOAD_MYEVENTS_CONFIRM;
        [alert show];
    }
    if (alertView.tag == DOWNLOAD_MYEVENTS_CONFIRM)
    {
        UITextField *agree = [alertView textFieldAtIndex:0];
        if ([agree.text caseInsensitiveCompare:@"agree"] == NSOrderedSame)
        {
            [ATHelper startReplaceDb:@"myEvents" :downloadedMyEventsJsonArray :spinner];
            [self changeSelectedSource: @"myEvents"];
            downloadedMyEventsJsonArray = nil;
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You canceled replacing offline content!",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            [alert show];
        }
    }
    if (alertView == uploadAlertView)
    {
        if (buttonIndex == 0)
        {
            //NSLog(@"user canceled upload");
            // Any action can be perfhttp://www.wenxuecity.com/news/2014/05/10/3255854.htmlormed here
        }
        else if (buttonIndex == 1)
        {
            confirmUploadContentAlertView  = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Confirm to replace %@ contents on server!",nil),[ATHelper getSelectedDbFileName]]
                                                                        message:NSLocalizedString(@"Enter agree to continue:",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            [confirmUploadContentAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
            UITextField * aa = [confirmUploadContentAlertView textFieldAtIndex:0];
            aa.placeholder = @"agree";
            [confirmUploadContentAlertView show];
        }
    }
    if (alertView == confirmUploadContentAlertView)
    {
        UITextField *agree = [alertView textFieldAtIndex:0];
        if ([agree.text caseInsensitiveCompare:@"agree"] == NSOrderedSame)
        {
            [self startUploadJson];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You canceled uploading the content to server",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            [alert show];
        }
    }
    if (alertView == uploadAllToDropboxAlert)
    {
        if (buttonIndex == 0)
        {
            NSLog(@"user canceled copy all to dropbox");
            // Any action can be performed here
        }
        else if (buttonIndex == 1)
        {
            confirmUploadAllPhotoAlertView  = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Confirm to replace all %@ photos on Dropbox!",nil),[ATHelper getSelectedDbFileName]]
                                                                         message:NSLocalizedString(@"Enter agree to continue:",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            [confirmUploadAllPhotoAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
            UITextField * aa = [confirmUploadAllPhotoAlertView textFieldAtIndex:0];
            aa.placeholder = @"agree";
            [confirmUploadAllPhotoAlertView show];
        }
    }
    if (alertView == confirmUploadAllPhotoAlertView)
    {
        UITextField *agree = [alertView textFieldAtIndex:0];
        if ([agree.text caseInsensitiveCompare:@"agree"] == NSOrderedSame)
        {
            [spinner startAnimating];
            progressUploadPhotoCount = 0;
            progressUploadTotalCount = 0;
            
            progressUploadView.hidden = false;
            
            isRemoveSourceForUploadAll = true; //so if /ChronicleMap/myEvent not on dropbox yet, delete fail will know the case
            [[self myRestClient] deletePath:[NSString stringWithFormat:@"/ChronicleMap/%@", [ATHelper getSelectedDbFileName]]];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Photo upload started and [New] number is decreasing.\n If number reach 0 then full back up is done.\n If number stop at non-zero, then tap [Photo Backup] row to continue.",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You Canceled uploading all photos to Dropbox",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            [alert show];
        }
    }
    if (alertView == downloadAllFromDropboxAlert)
    {
        if (buttonIndex == 0)
        {
            return; //user canceled download all
        }
        onlyShowOnceForIssueWithDropbox = true;
        showDownloadAllLoadMetadataErrorAlert = true;
        totalDownloadFromDropboxSuccessCount = 0;
        progressDownloadEventCount = 0;

        progressDownloadOveralView.hidden = false;
        progressDownloadDetailView.hidden = false;
        
        [self dequeueEventIdAndStartDownloadPhotos];
    }
}

//dequeue one eventId. process event one by one serially, but for all photos inside one event, download them parally.
//This function dequeue one event, start download all photos in it parally, once last photos is downloaded, call this function again for next eventId
//(The initial version did everything in parall, and need manually try many times. The second version (not released but in git) do all photo of all events in one serial, and too slow)
-(void) dequeueEventIdAndStartDownloadPhotos
{
    //if local path does not exist, loadFile will not write
    NSString* localFullPath = [ATHelper getPhotoDocummentoryPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:localFullPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:localFullPath withIntermediateDirectories:YES attributes:nil error:nil];
    downloadFromDropboxStartCount = 0;
    downloadFromDropboxLoadMedadataFailCount = 0;
    
    if ([eventIdQueueToCopyPhotoFromDropbox count] == 0)
    {
        NSString* restoreMsg = [NSString stringWithFormat:NSLocalizedString(@"%d files are downloaded! (Repeat this action until [0 file is downloaded] is displayed.)",nil),totalDownloadFromDropboxSuccessCount];
        if (totalDownloadFromDropboxSuccessCount == 0)
            restoreMsg = NSLocalizedString(@"0 file is downloaded! All photo files on Dropbox have been restored to this APP.",nil);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Restore Finish!",nil)
                                                        message: restoreMsg
                                                       delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
        return;
    }
    //   [spinner startAnimating];
    currentEventId = [eventIdQueueToCopyPhotoFromDropbox firstObject];
    [eventIdQueueToCopyPhotoFromDropbox removeObjectAtIndex:0];
    
    //Progress implementation. My case is simple, so I do not use NSProgress object introduced in iOS7
    progressDownloadEventCount ++;
    float increaseRate = (float)progressDownloadEventCount/(float)progressDownloadTotalNumberOfEvents;
    progressDownloadOveralView.progress = increaseRate;
    
    totalDownloadFromDropboxSuccessCount = totalDownloadFromDropboxSuccessCount + downloadFromDropboxSuccessCount;
    downloadFromDropboxSuccessCount = 0;
    downloadFromDropboxFailCount = 0;
    downloadAlreadyExistCount = 0;
    //NSLog(@"===== eventId dequeued: %@,  remaining=%d",currentEventId, [eventIdQueueToCopyPhotoFromDropbox count]);
    //local path has to exist for loadFile to save. But local path may not exist after re-install app so need do it here
    if (![[NSFileManager defaultManager] fileExistsAtPath:[localFullPath stringByAppendingPathComponent:currentEventId]])
        [[NSFileManager defaultManager] createDirectoryAtPath:[localFullPath stringByAppendingPathComponent:currentEventId] withIntermediateDirectories:YES attributes:nil error:nil];
    [[self myRestClient] loadMetadata:[NSString stringWithFormat:@"/ChronicleMap/%@/%@", [ATHelper getSelectedDbFileName], currentEventId]]; //then see loadedMetadata delegate where we start download file
    
    //NSLog(@"---------- spinner stop %d", downloadAlreadyExistCount);
    //[spinner stopAnimating];
}

-(void)startUploadJson
{
    [spinner startAnimating];
    // [self dismissViewControllerAnimated:true completion:nil]; does not dismiss preference itself here
    
    Boolean successFlag = [ATHelper checkUserEmailAndSecurityCode:self];
    if (!successFlag)
    {
        //Need alert again?  checkUserEmailAndSecurityCode already alerted
        return;
    }
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* userEmail = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
    NSString* securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
    if (userEmail == nil || securityCode == nil)
    {
        //should never come here
        return;
    }
    
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    NSDateFormatter* usDateFormater = [appDelegate.dateFormater copy];
    //always use USLocale to save date in JSON, so always use it to read. this resolve a big issue when user upload with one local and download with another local setting.
    // See ATHelper startDownload
    [usDateFormater setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    
    NSArray *myAtlasList = appDelegate.eventListSorted;
    NSInteger eventCount = [myAtlasList count];
    NSMutableArray* dictArray = [[NSMutableArray alloc] initWithCapacity:eventCount];
    for (ATEventDataStruct* item in myAtlasList)
    {
        NSNumber* eventType = [NSNumber numberWithInt: item.eventType]; //not initialized in code, need fix
        if (eventType == nil)
            eventType = [NSNumber numberWithInt:EVENT_TYPE_NO_PHOTO];
        
        NSMutableDictionary* itemDict = [[NSMutableDictionary alloc] init];
        [itemDict setObject:item.uniqueId forKey:@"uniqueId"];
        [itemDict setObject:item.eventDesc forKey:@"eventDesc"];
        [itemDict setObject:[usDateFormater stringFromDate:item.eventDate] forKey:@"eventDate"]; //NSDate is not serializable
        [itemDict setObject:eventType forKey:@"eventType"];
        [itemDict setObject:item.address forKey:@"address"];
        [itemDict setObject:[NSNumber numberWithDouble:item.lat] forKey:@"lat"];
        [itemDict setObject:[NSNumber numberWithDouble:item.lng] forKey:@"lng"];
        
        [dictArray addObject:itemDict];
    }
    NSArray *info = [NSArray arrayWithArray:dictArray];
    NSError* error;
    NSData* eventData = [NSJSONSerialization dataWithJSONObject:info options:0 error:&error];
    
    //"application/x-www-form-urlencoded" is used, need encode % and & sign (spend long time to figure out)
    NSMutableString *longStr = [[NSMutableString alloc] initWithData:eventData encoding:NSUTF8StringEncoding];
    [longStr replaceOccurrencesOfString:@"%" withString:@"%25" options:0 range:NSMakeRange(0, [longStr length])];
    [longStr replaceOccurrencesOfString:@"&" withString:@"%26" options:0 range:NSMakeRange(0, [longStr length])];
    
    //NSString* eventStr= @"百科 abc 2012/02/34";//test post chinese
    NSString* postStr = [NSString stringWithFormat:@"user_id=%@&security_code=%@&atlas_name=%@&json_contents=%@", userEmail, securityCode
                         ,[ATHelper getSelectedDbFileName], longStr];
    //NSLog(@"============post body = %@", postStr);
    NSData *postData = [postStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSURL* serviceUrl = [NSURL URLWithString: [ATConstants ServerURL]];
    //NSLog(@"============post url = %@", serviceUrl.absoluteString);
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:serviceUrl];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    //Get Responce hear----------------------
    NSURLResponse *response;
    
    NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString* returnStatus = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
    //NSLog(@"upload response  urlData = %@", returnStatus);
    //Event Editor should exclude & char which will cause partial upload until &
    [spinner stopAnimating];
    if (![returnStatus isEqual:@"SUCCESS"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Export Failed!",nil) message:NSLocalizedString(@"Fail reason could be network issue or data issue!",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
        return;
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Export Success!",nil)
                                                        message: [NSString stringWithFormat:NSLocalizedString(@"%i %@ events have been uploaded to server successfully!",nil),eventCount,[ATHelper getSelectedDbFileName]]
                                                       delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
        return;
    }
}


#pragma mark - Table view delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    int retCount = 0;
    if (section == SECTION_LOGIN_EMAIL)
        retCount = 1;
    else if (section == SECTION_CONTENT_MANAGE)
        retCount = 2;
    else if (section == SECTION_SYNC_MYEVENTS_PHOTO_TO_DROPBOX)
        retCount = 3;
    else  //SECTION_SUPPORT...
        retCount = 4;
    
    return retCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    long section = indexPath.section;
    UITableViewCell *cell = nil;
    if (section == SECTION_CONTENT_MANAGE)
    {
        NSString* cellIdentifier = @"cell_type_mg";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if( cell == nil )
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
            cell.detailTextLabel.textColor = [UIColor grayColor];
        }
    }
    else
    {
        NSString* cellIdentifier = @"cell_type_other";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if( cell == nil )
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [cell.imageView setImage:nil];
    long row = indexPath.row;
    if (section == SECTION_CONTENT_MANAGE)
    {
        if (row == ROW_CONTENT_MG_MY_EPISODE)
        {
            cell.textLabel.text = NSLocalizedString(@"Share my Episodes to Friends",nil);
            cell.detailTextLabel.text = NSLocalizedString(@"Send episodes / Invite Friends",nil);
        }
        if (row == ROW_INBOX)
        {
            cell.textLabel.text = NSLocalizedString(@"Collection Box",nil);
            cell.detailTextLabel.text = NSLocalizedString(@"Pick an item to show; recover myEvents..",nil);
            if (hasNewIncomingShareFlag)
            {
                UIImage *img = [UIImage imageNamed:@"new-message-red-dot"];
                UIImageView *icon = [[UIImageView alloc] initWithImage:img];
                [icon setFrame:CGRectMake(0, 0, 18, 18)];
                cell.textLabel.text = [NSString stringWithFormat:@"    %@", cell.textLabel.text ];
                [cell.textLabel addSubview:icon];
            }
        }
    }
    else if (section == SECTION_LOGIN_EMAIL)
    {
        if (row == 0)
        {
            cell.textLabel.text = NSLocalizedString(@"World Top Attractions",nil);
            [cell.imageView setImage:[UIImage imageNamed:@"star-red-orig-purple.png"]];
        }
    }
    else if (section == SECTION_MISC)
        
    {
        switch (row) {
            case ROW_OPTIONS:
                cell.textLabel.text = NSLocalizedString(@"Options",nil);
                [cell.imageView setImage:nil];
                break;
            case ROW_PURCHASE:
                cell.textLabel.text = NSLocalizedString(@"Support Us",nil);
                [cell.imageView setImage:nil];
                break;
            case ROW_RESTORE_PURCHASE:
                cell.textLabel.text = NSLocalizedString(@"Restore Purchase",nil);
                break;
            case ROW_VIDEO_TUTORIAL:
                cell.textLabel.text = NSLocalizedString(@"Video Tutorial and FAQ",nil);
                break;
            default:
                break;
        }
        
        if (row == ROW_PURCHASE || row == ROW_RESTORE_PURCHASE)
        {
            NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
            if ([userDefault objectForKey:IN_APP_PURCHASED] != nil)
            {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.textColor = [UIColor lightGrayColor];
            }
        }
    }
    else if (section == SECTION_SYNC_MYEVENTS_PHOTO_TO_DROPBOX)
    {
        switch (row) {
            case ROW_SYNC_TO_DROPBOX:
                cell.textLabel.text = NSLocalizedString(@"Backup Photos (Incremental)",nil);
                break;
            case ROW_SYNC_TO_DROPBOX_ALL:
                cell.textLabel.text = NSLocalizedString(@"Backup Photos (Full)",nil);
                break;
            case ROW_SYNC_FROM_DROPBOX:
                cell.textLabel.text = RESTORE_PHOTO_TITLE;
                if (progressDownloadOveralView == nil)
                {
                    progressDownloadOveralView = [[UIProgressView alloc] initWithFrame:CGRectMake(30, 45, 200, 30)];
                    [cell.contentView addSubview:progressDownloadOveralView];
                    progressDownloadOveralView.hidden = true;
                    progressDownloadDetailView = [[UIProgressView alloc] initWithFrame:CGRectMake(30, 55, 200, 30)];
                    [cell.contentView addSubview:progressDownloadDetailView];
                    progressDownloadDetailView.hidden = true;
                }
                progressDownloadOveralView.progress = 0.0f;
                progressDownloadDetailView.progress = 0.0f;
                break;
            default:
                break;
        }
        if (row == ROW_SYNC_TO_DROPBOX )
        {
            ATDataController* dataController = [[ATDataController alloc] initWithDatabaseFileName:[ATHelper getSelectedDbFileName]];
            int numberOfNewPhotos = [dataController getNewPhotoQueueSizeExcludeThumbNail];
            int numberOfDeletedPhoto = [dataController getDeletedPhotoQueueSize];
            cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Photo Backup - New:%d  Del:%d",nil),numberOfNewPhotos,numberOfDeletedPhoto ];
            PhotoToDropboxCell = cell;
            if (progressUploadView == nil)
            {
                progressUploadView = [[UIProgressView alloc] initWithFrame:CGRectMake(30, 38, 200, 30)];
                [cell.contentView addSubview:progressUploadView];
                progressUploadView.hidden = true;
            }
            progressUploadView.progress = 0.0f;
        }
        if (row == ROW_SYNC_FROM_DROPBOX)
            photoFromDropboxCell = cell;
    }
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica-italic" size:16];//no effect to chinese
    return cell;
}

//change section font

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    //UITableView section is aleays in cap, I need to do something speicial here
    UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0, 10, tableView.bounds.size.width, 70)];
    [customView setBackgroundColor:[UIColor colorWithRed: 0.85 green: 0.85 blue: 0.85 alpha: 0.0]];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.bounds.size.width, 30)];
    label.font = [UIFont fontWithName:@"Helvetica" size:18.0];
    label.textColor = [UIColor lightGrayColor];
    label.textAlignment = NSTextAlignmentCenter;
    // create the parent view that will hold header Label
    if (section == SECTION_CONTENT_MANAGE)
    {
        /**** TODO **** add refersh button for later implement auto synch. Also see unused smartDownloadMyEvents() function
        //Show full sync button only when:
        //  1. not logged in yet
        //  2. current active contents is myEvents
        UIButton* refreshBtn =[UIButton buttonWithType:UIButtonTypeCustom];
        [refreshBtn setImage:[UIImage imageNamed:@"Refresh-icon.png"] forState:UIControlStateNormal];
        [refreshBtn addTarget:self action:@selector(fullSyncMyEvents:) forControlEvents:UIControlEventTouchUpInside];
        refreshBtn.frame = CGRectMake(10, -10, 40, 40);
        //TODO if not login, and first time, and ....... see document
        [customView addSubview:refreshBtn];
        ******/
        NSUInteger loc = [_source rangeOfString:@"*"].location;
        NSString* namePart = _source;
        if (loc != NSNotFound)
            namePart =  [_source substringToIndex:loc];
        label.text = [NSString stringWithFormat:NSLocalizedString(@"On Map: %@",nil), namePart];
    }
    if (section == SECTION_LOGIN_EMAIL)
    {
        label.textAlignment = NSTextAlignmentLeft;
        NSString* loginEmail = nil;
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        NSString* userEmail = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
        if (userEmail != nil)
            loginEmail = userEmail;
        else
            loginEmail = @"";
        
        label.text = loginEmail;
        
        if (userEmail != nil)
        {
            logoutButton = [UIButton buttonWithType:UIButtonTypeSystem];
            logoutButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:17];
            logoutButton.frame = CGRectMake(210, -10, 60, 50);
            [logoutButton setTitle:NSLocalizedString(@"Logout",nil) forState:UIControlStateNormal];
            [logoutButton.titleLabel setTextColor:[UIColor blueColor]];
            [logoutButton addTarget:self action:@selector(logoutButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            [customView addSubview:logoutButton];
        }
        else
        {
            logoutButton = [UIButton buttonWithType:UIButtonTypeSystem];
            logoutButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:17];
            logoutButton.frame = CGRectMake(210, -10, 60, 50);
            [logoutButton setTitle:NSLocalizedString(@"Login",nil) forState:UIControlStateNormal];
            [logoutButton.titleLabel setTextColor:[UIColor blueColor]];
            [logoutButton addTarget:self action:@selector(loginButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            [customView addSubview:logoutButton];
        }
    }
    if (section == SECTION_SYNC_MYEVENTS_PHOTO_TO_DROPBOX)
    {
        label.text = NSLocalizedString(@"Backup/Restore Photos to Dropbox",nil);
    }
    if (section == SECTION_MISC)
    {
        label.text = NSLocalizedString(@"Misc",nil);
    }
    [customView addSubview:label];
    return customView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section ==SECTION_SYNC_MYEVENTS_PHOTO_TO_DROPBOX &&  indexPath.row == ROW_SYNC_FROM_DROPBOX)
    {
        return 60;
    }
    else return 44; //44 is default value in object-c tablecell view
}
- (ATDataController*)getDataController
{
    if (privateDataController == nil)
        privateDataController = [[ATDataController alloc] initWithDatabaseFileName:[ATHelper getSelectedDbFileName]];
    return privateDataController;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    long section = indexPath.section;
    if (section == SECTION_CONTENT_MANAGE)
        [self handleContentManageSection:tableView :indexPath ];
    if (section == SECTION_LOGIN_EMAIL)
        [self handleLoginEmailSection:tableView :indexPath ];
    if (section == SECTION_MISC)
        [self handleMiscSection:tableView :indexPath ];
    if (section == SECTION_SYNC_MYEVENTS_PHOTO_TO_DROPBOX)
        [self handleSynchPhotoSection:tableView :indexPath];
}
-(void) handleMiscSection:(UITableView*)tableView :(NSIndexPath *)indexPath
{
    long row = indexPath.row;
    if (row == ROW_OPTIONS)
    {
        [self performSegueWithIdentifier:@"options" sender:nil];
    }
    if (row == ROW_VIDEO_TUTORIAL)
    {
        NSURL *url = [NSURL URLWithString:@"http://www.chroniclemap.com/onlinehelp"];
        if (![[UIApplication sharedApplication] openURL:url])
            NSLog(@"%@%@",@"Failed to open url:",[url description]);
    }
    if (row == ROW_PURCHASE)
    {
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        if ([userDefault objectForKey:IN_APP_PURCHASED] == nil)
        {
            purchase = [[ATInAppPurchaseViewController alloc] init];
            [purchase processInAppPurchase];
        }
    }
    if (row == ROW_RESTORE_PURCHASE)
    {
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        if ([userDefault objectForKey:IN_APP_PURCHASED] == nil)
        {
            purchase = [[ATInAppPurchaseViewController alloc] init];
            [purchase restorePreviousPurchases];
        }
        
    }
}
-(void) handleContentManageSection:(UITableView*)tableView :(NSIndexPath *)indexPath
{
    //also see prepareForSegue() where pass values
    if (indexPath.row == ROW_CONTENT_MG_MY_EPISODE)
    {
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        if ([@"myEvents" isEqualToString:appDelegate.sourceName])
            [self performSegueWithIdentifier:@"share_my_episode" sender:nil];
        else
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Please pick myEvents to show on map!",nil)
                                                           message: NSLocalizedString(@"You can share your episode only when myEvents is on map",nil)
                                                          delegate: self
                                                 cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                 otherButtonTitles:nil,nil];
            
            
            [alert show];
        }
    }
    else if (indexPath.row == ROW_INBOX)
    {
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        NSString *userId = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
        if (userId == nil) //user has not logged in yet means user has never restored myEvents since download the app
        {
            [self displayLoginForInbox];
        }
        else
            [self performSegueWithIdentifier:@"download" sender:nil];
        
    }
    
}

- (void) displayLoginForInbox
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Login for more services:",nil)
                                                                   message:NSLocalizedString(@"1. Backup/Restore myEvents\n2.  Check   shared   episodes ",nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* loginAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Login Now",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        Boolean successFlag = [ATHelper checkUserEmailAndSecurityCode:self];
        if (!successFlag)
        {
            //if user not login, then network not availbe case will be alert
            return;
        }
        else
        {
            [logoutButton setTitle:NSLocalizedString(@"Logout",nil) forState:UIControlStateNormal];
            [self performSegueWithIdentifier:@"download" sender:nil];
        }
    }];
    UIAlertAction* loginLaterAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Login Later",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self performSegueWithIdentifier:@"download" sender:nil];
    }];
    
    [alert addAction:loginAction ];
    [alert addAction:loginLaterAction];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void) handleLoginEmailSection:(UITableView*)tableView :(NSIndexPath *)indexPath
{
    //also see prepareForSeque() where pass values
    if (indexPath.row == 0)
        [self performSegueWithIdentifier:@"choose_poi" sender:nil];
}

//Unused, just created for later implement auto synch mysevnts
-(void) smartDownloadMyEvents
{
    Boolean successFlag = [ATHelper checkUserEmailAndSecurityCode:self];
    if (!successFlag)
    {
        //Need alert again?  checkUserEmailAndSecurityCode already alerted
        return;
    }
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    long localListCnt = [appDelegate.eventListSorted count];
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* userEmail = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
    NSString* securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
    //continues to get from server
    NSString* userId = userEmail;
    
    NSString* atlasName = @"myEvents";
    
    //TODO need pass LUT (last upload time) to server 
    NSURL* serviceUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/downloadjsoncontents?user_id=%@&security_code=%@&atlas_name=%@",[ATConstants ServerURL], userId, securityCode, atlasName]];
    
    NSData* downloadedData = [NSData dataWithContentsOfURL:serviceUrl];
    if (downloadedData == nil)
        return;
    NSString* displayLocalCnt = @"";
    if ([[ATHelper getSelectedDbFileName] isEqualToString :atlasName])
        displayLocalCnt = [NSString stringWithFormat:@"%ld", localListCnt];
    
    NSError* error;
    downloadedMyEventsJsonArray = [NSJSONSerialization JSONObjectWithData:downloadedData options:kNilOptions error:&error];
    
    [ATHelper startReplaceDb:@"myEvents" :downloadedMyEventsJsonArray :nil];
}

//this function is almost identical in ATDownloadTableViewController's startDownload functions
// (Dec, 2015: download MyEvents will be in smartDownloadMyEvents()
-(void) startDownloadMyEventsJson
{
    Boolean successFlag = [ATHelper checkUserEmailAndSecurityCode:self];
    if (!successFlag)
    {
        //Need alert again?  checkUserEmailAndSecurityCode already alerted
        return;
    }
    [spinner startAnimating];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    long localListCnt = [appDelegate.eventListSorted count];
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* userEmail = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
    NSString* securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
    //continues to get from server
    NSString* userId = userEmail;
    
    NSString* atlasName = @"myEvents";
    NSURL* serviceUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/downloadjsoncontents?user_id=%@&security_code=%@&atlas_name=%@",[ATConstants ServerURL], userId, securityCode, atlasName]];
    
    NSData* downloadedData = [NSData dataWithContentsOfURL:serviceUrl];
    if (downloadedData == nil)
        return;
    NSString* displayLocalCnt = @"";
    if ([[ATHelper getSelectedDbFileName] isEqualToString :atlasName])
        displayLocalCnt = [NSString stringWithFormat:@"%ld", localListCnt];
    
    NSError* error;
    downloadedMyEventsJsonArray = [NSJSONSerialization JSONObjectWithData:downloadedData options:kNilOptions error:&error];
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"Downloaded %@ has %i events",nil),atlasName,[downloadedMyEventsJsonArray count]]
                                                   message: [NSString stringWithFormat:NSLocalizedString(@"WARNING: Local %@'s %@ events will be replaced!",nil),@"myEvents",displayLocalCnt]
                                                  delegate: self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                         otherButtonTitles:NSLocalizedString(@"Replace",nil),nil];
    alert.tag = DOWNLOAD_REPLACE_MY_SOURCE_TO_MYEVENTS_ALERT;
    [spinner stopAnimating];
    [alert show];
}
-(void) handleSynchPhotoSection:(UITableView*)tableView :(NSIndexPath *)indexPath
{
    long row = indexPath.row;
    if (row == ROW_SYNC_TO_DROPBOX)
    {
        if (![[DBSession sharedSession] isLinked]) {
            [[DBSession sharedSession] linkFromController:self];
            return;
        }
        int dbNewPhotoCount = [[self getDataController] getNewPhotoQueueSizeExcludeThumbNail];
        int dbDeletedPhotoCount = [[self getDataController] getDeletedPhotoQueueSize];
        //set cell count again (already done in celFor...) here, is to refresh count after user clicked this row and already synched
        UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
        cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Photo Backup - New:%d  Del:%d",nil),dbNewPhotoCount,dbDeletedPhotoCount ];
        if (dbNewPhotoCount + dbDeletedPhotoCount > 0)
        {
            [spinner startAnimating]; //stop when chain complete or any error
            progressUploadView.hidden = false;
            progressUploadTotalCount = dbNewPhotoCount + dbDeletedPhotoCount;
        }
        if (dbNewPhotoCount > 0) //will process both queue
            [[self myRestClient] createFolder:@"/ChronicleMap"]; //createFolder success/alreadyExist delegate will start the chain action, which will include delete Queue
        else if (dbDeletedPhotoCount > 0) //bypass process createFolder, only delete file for more efficient
            [self processEmptyDeletedPhotoQueue];
        
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Photo backup has started!",nil)
                                                       message: NSLocalizedString(@"Photos will be uploaded to your Dropbox account one by one, please watch for the decreasing number.\n\nThe upload is done if number is decreased to 0. (Please repeat the operation if backup is interrupted)",nil)
                                                      delegate: self
                                             cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                             otherButtonTitles:nil,nil];
        [alert show];
        
    }
    else if (row == ROW_SYNC_TO_DROPBOX_ALL)
    {
        if (![[DBSession sharedSession] isLinked]) {
            [[DBSession sharedSession] linkFromController:self];
            return;
        }
        totalPhotoCountInDevice = 0;
        //get total number of photos on device
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSArray* eventList = appDelegate.eventListSorted;
        NSError *error;
        for (ATEventDataStruct* evt in eventList)
        {
            if (evt.eventType == EVENT_TYPE_HAS_PHOTO)
            {
                NSString *fullPathToFile = [[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:evt.uniqueId];
                NSArray* tmpFileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPathToFile error:&error];
                if (tmpFileList != nil && [tmpFileList count] > 0)
                {
                    for (NSString* file in tmpFileList)
                    {
                        if (![file isEqualToString:@"thumbnail"])
                            totalPhotoCountInDevice++;
                    }
                }
                
            }
        }
        if (totalPhotoCountInDevice == 0)
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"No photos to export to your Dropbox!",nil)
                                                           message: @""
                                                          delegate: self
                                                 cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                 otherButtonTitles:nil,nil];
            
            
            [alert show];
        }
        else
        {
            uploadAllToDropboxAlert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"Replace photos on Dropbox for %@",nil), [ATHelper getSelectedDbFileName]]
                                                                message: [NSString stringWithFormat:NSLocalizedString(@"WARNING: All photoes on your dropbox:/ChronicleMap/%@ will be deleted and replaced by %d photos from this device!",nil),_source, totalPhotoCountInDevice]
                                                               delegate: self
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                      otherButtonTitles:NSLocalizedString(@"Yes, Continue",nil),nil];
            [uploadAllToDropboxAlert show];
        }
    }
    else if (row == ROW_SYNC_FROM_DROPBOX)
    {
        if (![[DBSession sharedSession] isLinked]) {
            [[DBSession sharedSession] linkFromController:self];
            return;
        }
        progressDownloadTotalNumberOfEvents = 0;
        eventIdQueueToCopyPhotoFromDropbox = [[NSMutableArray alloc] initWithCapacity:10];
        //get total number of photos on device
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSArray* eventList = appDelegate.eventListSorted;
        
        for (ATEventDataStruct* evt in eventList)
        {
            if (evt.eventType == EVENT_TYPE_HAS_PHOTO)
            {
                progressDownloadTotalNumberOfEvents ++;
                [eventIdQueueToCopyPhotoFromDropbox addObject:evt.uniqueId];
                
            }
        }
        if (progressDownloadTotalNumberOfEvents == 0)
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"Content %@ is empty or do not have photos to download.",nil), [ATHelper getSelectedDbFileName]]
                                                           message: NSLocalizedString(@"This content may not have photos.",nil)
                                                          delegate: self
                                                 cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                 otherButtonTitles:nil,nil];
            
            
            [alert show];
        }
        else
        {
            [UIApplication sharedApplication].idleTimerDisabled = YES;
            downloadAllFromDropboxAlert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"Import photos from Dropbox:/ChronicleMap/%@",nil), [ATHelper getSelectedDbFileName]]
                                                                    message: [NSString stringWithFormat:NSLocalizedString(@"Download missing %@ photos from Dropbox. This operation can be repeated until all photos are downloaded.",nil),[ATHelper getSelectedDbFileName]]
                                                                   delegate: self
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                          otherButtonTitles:NSLocalizedString(@"Yes, Continue",nil),nil];
            [downloadAllFromDropboxAlert show];
        }
    }
}

//1) smart download, 2)if has local change, do merge then upload
- (void) fullSyncMyEvents: (id)sender{
    
}

- (void) logoutButtonAction: (id)sender {
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault removeObjectForKey:[ATConstants UserEmailKeyName]];
    [userDefault removeObjectForKey:[ATConstants UserSecurityCodeKeyName]];
    [logoutButton setTitle:@"" forState: UIControlStateNormal];
    [loginEmailLabel setText:NSLocalizedString(@"Not login",nil)];
}
- (void) loginButtonAction: (id)sender {
    [ATHelper checkUserEmailAndSecurityCode:self];
    [logoutButton setTitle:@"" forState: UIControlStateNormal];
}
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

//this is createFolder delegate, important of my chain action
- (void)restClient:(DBRestClient*)client createdFolder:(DBMetadata*)folder{
    //NSLog(@"+++++ Folder success Meta Data Path %@; filename %@; hasDirectory %d;",[folder path], [folder filename], [folder isDirectory]);
    if ( [@"/ChronicleMap" isEqualToString:[folder path]])
    {
        NSString *destDir = [ NSString stringWithFormat:@"/ChronicleMap/%@",  [ATHelper getSelectedDbFileName] ];
        [[self myRestClient ] createFolder:destDir]; //chain action 1: create "source" directory if not so
    }
    else if ([[folder filename] isEqualToString:[ATHelper getSelectedDbFileName]])
    {
        [self startProcessNewPhotoQueueChainAction ];
    }
    else //Part of chain: come here if this is first time create eventId directory
    {
        NSString *localPhotoPath = [ATHelper getPhotoDocummentoryPath];
        localPhotoPath = [[localPhotoPath stringByAppendingPathComponent:currentEventId] stringByAppendingPathComponent:currentPhotoName];
        //Following gives me rediculourse errors where Dropbox did not document
        // 1. get 1003 error with no description, the find fromPath must also include filename part
        // 2. then get 403 Forbidden error, then realize I have to ask dropbox to enable production mode
        if ([[NSFileManager defaultManager] fileExistsAtPath:localPhotoPath])
        {
            if (![PHOTO_META_FILE_NAME isEqualToString:currentPhotoName])
                [[self myRestClient] uploadFile: currentPhotoName toPath:[folder path] withParentRev:nil fromPath:localPhotoPath];
            else //use loadRevisions is the only way I can avoid creating mutiple revision when upload same file again and again
                [[self myRestClient] loadRevisionsForFile:[NSString stringWithFormat:@"%@/%@",[folder path], PHOTO_META_FILE_NAME] limit:1];
        }
    }
}

- (void)restClient:(DBRestClient*)client loadedRevisions:(NSArray *)revisions forFile:(NSString *)path
{
    DBMetadata *file = revisions[0];
    NSString *localPhotoPath = [ATHelper getPhotoDocummentoryPath];
    localPhotoPath = [[localPhotoPath stringByAppendingPathComponent:currentEventId] stringByAppendingPathComponent:PHOTO_META_FILE_NAME];
    [[self myRestClient] uploadFile: PHOTO_META_FILE_NAME toPath:[path stringByDeletingLastPathComponent] withParentRev:file.rev fromPath:localPhotoPath]; //path included file nm, need special treat
    
}
- (void)restClient:(DBRestClient*)client loadRevisionsFailedWithError:(NSError *)error
{
    //If file not exist before
    NSString *localPhotoPath = [ATHelper getPhotoDocummentoryPath];
    localPhotoPath = [[localPhotoPath stringByAppendingPathComponent:currentEventId] stringByAppendingPathComponent:PHOTO_META_FILE_NAME];
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPhotoPath])
    {
        NSString* pathFileStr = (NSString*)[error.userInfo objectForKey:@"path"];
        [[self myRestClient] uploadFile:PHOTO_META_FILE_NAME toPath:[pathFileStr stringByDeletingLastPathComponent] withParentRev:nil fromPath:localPhotoPath];
    }
}

// Folder is the metadata for the newly created folder
- (void)restClient:(DBRestClient*)client createFolderFailedWithError:(NSError*)error{
    //if error is folder alrady exist, then continues our chain action
    [spinner stopAnimating];
    if ([self dropboxFolderAlreadyExist:error])
    {
        if ( [@"/ChronicleMap" isEqualToString:(NSString*)[error.userInfo objectForKey:@"path"]]) //TODO
        {
            NSString *destDir = [ NSString stringWithFormat:@"/ChronicleMap/%@",  [ATHelper getSelectedDbFileName]];
            [[self myRestClient ] createFolder:destDir]; //delegate come back with following if
        }
        else if ([[NSString stringWithFormat:@"/ChronicleMap/%@", [ATHelper getSelectedDbFileName]] isEqualToString:(NSString*)[error.userInfo objectForKey:@"path"]])
        {
            [self startProcessNewPhotoQueueChainAction ]; //start upload the 1st file
        }
        else //Part of chain: come here if eventId directory already created before
        {
            NSString *localPhotoPath = [ATHelper getPhotoDocummentoryPath];
            localPhotoPath = [[localPhotoPath stringByAppendingPathComponent:currentEventId] stringByAppendingPathComponent:currentPhotoName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:localPhotoPath])
            {
                NSString* remotePath = (NSString*)[error.userInfo objectForKey:@"path"];
                NSString* remotePathFile = [NSString stringWithFormat:@"%@/%@",remotePath,PHOTO_META_FILE_NAME];
                if (![PHOTO_META_FILE_NAME isEqualToString:currentPhotoName])
                    [[self myRestClient] uploadFile: currentPhotoName toPath:remotePath withParentRev:nil fromPath:localPhotoPath];
                else
                    [[self myRestClient] loadRevisionsForFile:remotePathFile limit:1];
            }
        }
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Could not copy to Dropbox",nil)
                                                       message: NSLocalizedString(@"May be the network is not available",nil)
                                                      delegate: self
                                             cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                             otherButtonTitles:nil,nil];
        
        
        [alert show];
    }
}


- (void) startProcessNewPhotoQueueChainAction
{
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
    }
    //When this is called, destDir is already successfully created on dropbox before
    NSString *destDir = [ NSString stringWithFormat:@"/ChronicleMap/%@",  [ATHelper getSelectedDbFileName]];
    
    NSString* file = [[self getDataController] popNewPhotoQueue];
    if (file != nil )
    {
        NSArray* tmpArray = [file componentsSeparatedByString:@"/"];
        currentEventId = tmpArray[0];
        currentPhotoName = tmpArray[1];
        //part of chain action: createFolder delegate will do uploadFile to dropbox when success or fail with 403 (folder already exist
        [[self myRestClient] createFolder:[ NSString stringWithFormat:@"%@/%@", destDir, tmpArray[0] ]];
    }
    else
    {
        [self processEmptyDeletedPhotoQueue]; //start process deletedPhotoQueue chain action after finish process newPhotoQueue
    }
}
//will be a implicit loop by delete success delegate
- (void) processEmptyDeletedPhotoQueue
{
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
    }
    //When this is called, destDir is already successfully created on dropbox before
    NSString *destDir = [ NSString stringWithFormat:@"/ChronicleMap/%@",  [ATHelper getSelectedDbFileName]];
    isEventDir = false;
    NSString* file = [[self getDataController] popDeletedPhototQueue];
    if (file == nil)
    {
        file = [[self getDataController] popDeletedEventPhototQueue];
        isEventDir = true;
    }
    
    if (file != nil )
    {
        if (!isEventDir)
        {
            NSArray* tmpArray = [file componentsSeparatedByString:@"/"];
            currentEventId = tmpArray[0];
            currentPhotoName = tmpArray[1];
            //part of chain action: createFolder delegate will do uploadFile to dropbox when success or fail with 403 (folder already exist
            [[self myRestClient] deletePath:[ NSString stringWithFormat:@"%@/%@/%@", destDir, tmpArray[0], tmpArray[1] ]];
        }
        else
        {
            currentEventId = file;
            [[self myRestClient] deletePath:[ NSString stringWithFormat:@"%@/%@", destDir, file ]];
        }
    }
    else if (uploadSuccessExcludeThumbnailCount > 0 || deleteCount > 0)
    {
        [spinner stopAnimating];
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Copy to Dropbox completed!",nil)
                                                       message: [NSString stringWithFormat:NSLocalizedString(@"Add:%d/Delete:%d files in Dropbox succesfully.",nil),uploadSuccessExcludeThumbnailCount,deleteCount]
                                                      delegate: self
                                             cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                             otherButtonTitles:nil,nil];
        
        
        [alert show];
        uploadSuccessExcludeThumbnailCount = 0;
        deleteCount = 0;
    }
}

//delegate called by upload to dropbox
- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    [[self getDataController] emptyNewPhotoQueue:[NSString stringWithFormat:@"%@/%@" ,currentEventId, currentPhotoName]];
    int dbNewPhotoCount = [[self getDataController] getNewPhotoQueueSizeExcludeThumbNail];
    int dbDeletedPhotoCount = [[self getDataController] getDeletedPhotoQueueSize];
    progressUploadPhotoCount ++;
    if (![currentPhotoName isEqualToString:@"thumbnail"])
    {
        uploadSuccessExcludeThumbnailCount++;
        PhotoToDropboxCell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Photo Backup - New:%d  Del:%d",nil),dbNewPhotoCount, dbDeletedPhotoCount];
    }
    progressUploadView.progress = (float)progressUploadPhotoCount/(float)progressUploadTotalCount;
    [self startProcessNewPhotoQueueChainAction]; //start upload next file until
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    [spinner stopAnimating];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Could not copy file to Dropbox",nil)
                                                   message: NSLocalizedString(@"May be the network is not available",nil)
                                                  delegate: self
                                         cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                         otherButtonTitles:nil,nil];
    
    
    [alert show];
}
- (BOOL) prepareUploadAllToDropbox //call this after remove ChronicleMap/myEvent on dropbox successfully
{
    BOOL hasFileToUpload = false;
    //empty queues
    NSString* file = [[self getDataController] popNewPhotoQueue];
    while (file != nil)
    {
        [[self getDataController] emptyNewPhotoQueue:file];
        file = [[self getDataController] popNewPhotoQueue];
    }
    file = [[self getDataController] popDeletedEventPhototQueue];
    while (file != nil)
    {
        [[self getDataController] emptyDeletedEventPhotoQueue:file];
        file = [[self getDataController] popDeletedEventPhototQueue];
    }
    file = [[self getDataController] popDeletedPhototQueue];
    while (file != nil)
    {
        [[self getDataController] emptyDeletedPhotoQueue:file];
        file = [[self getDataController] popDeletedPhototQueue];
    }
    
    //fill up newPhotoQueues
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray* eventList = appDelegate.eventListSorted;
    NSError *error;
    for (ATEventDataStruct* evt in eventList)
    {
        if (evt.eventType == EVENT_TYPE_HAS_PHOTO)
        {
            NSString *fullPathToFile = [[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:evt.uniqueId];
            NSArray* tmpFileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPathToFile error:&error];
            if (tmpFileList != nil && [tmpFileList count] > 0)
            {
                for (NSString* file in tmpFileList)
                {
                    [[self getDataController] insertNewPhotoQueue:[evt.uniqueId stringByAppendingPathComponent:file]];
                    hasFileToUpload = true;
                }
            }
            
        }
    }
    return hasFileToUpload;
}
- (void)restClient:(DBRestClient*)client deletedPath:(NSString *)path
{
    if (isRemoveSourceForUploadAll)
    {
        if (![self prepareUploadAllToDropbox])
            return; //return if no file to upload
        NSString *destDir = [ NSString stringWithFormat:@"/ChronicleMap/%@",  [ATHelper getSelectedDbFileName] ];
        [[self myRestClient ] createFolder:destDir]; //this will start chain action for copy all in the queue to dropbox
        isRemoveSourceForUploadAll = false;
        return;
    }
    
    [[self getDataController] emptyDeletedPhotoQueue:[NSString stringWithFormat:@"%@/%@", currentEventId, currentPhotoName]];
    int dbNewPhotoCount = [[self getDataController] getNewPhotoQueueSizeExcludeThumbNail];
    int dbDeletedPhotoCount = [[self getDataController] getDeletedPhotoQueueSize];
    if (![currentPhotoName isEqualToString:@"thumbnail"])
    {
        [spinner stopAnimating]; //TODO? seems weired here. but need it when only have item in deleteQueue
        deleteCount++;
        PhotoToDropboxCell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Photo Backup - New:%d  Del:%d",nil),dbNewPhotoCount, dbDeletedPhotoCount];
    }
    [self processEmptyDeletedPhotoQueue];
}
- (void)restClient:(DBRestClient*)client deletePathFailedWithError:(NSError*)error
{
    if ([self dropboxDeleteFileNotExist:error]) //if not in dropbox, continues the chain. Dropbox can cleaned anyway if user select
    {
        if (isRemoveSourceForUploadAll)
        {
            if (![self prepareUploadAllToDropbox])
                return; //return if no file to upload
            NSString *destDir = [ NSString stringWithFormat:@"/ChronicleMap/%@",  [ATHelper getSelectedDbFileName] ];
            [[self myRestClient ] createFolder:destDir]; //this will start chain action for copy all to dropbox
            isRemoveSourceForUploadAll = false;
            return;
        }
        if (!isEventDir)
            [[self getDataController] emptyDeletedPhotoQueue:[NSString stringWithFormat:@"%@/%@", currentEventId, currentPhotoName]];
        else
            [[self getDataController] emptyDeletedEventPhotoQueue:currentEventId];
        [self processEmptyDeletedPhotoQueue];
    }
    else
    {
        [spinner stopAnimating];
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Could not access Dropbox",nil)
                                                       message: NSLocalizedString(@"May be the network is not available",nil)
                                                      delegate: self
                                             cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                             otherButtonTitles:nil,nil];
        
        
        [alert show];
    }
}

//following loadedMetadata delegate is for copy from dropbox to device. When it come here after loadMetaData() called with eventId
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    if (metadata.isDirectory) {
        if (metadata.contents == nil || [metadata.contents count] == 0)
        {
            [self dequeueEventIdAndStartDownloadPhotos];
            return;
        }
        photoNameQueueForCurrentEventIdFromDropbox = [[NSMutableArray alloc] initWithArray:metadata.contents];
        currentEventMetapath = metadata.path;
        downloadFromDropboxStartCount = [photoNameQueueForCurrentEventIdFromDropbox count];
        //Following loop will be block waiting if has photo
        progressDownloadDetailView.progress = 0.0f;
        progressDownloadTotalNumberOfPhotosInOneEvent = 0;
        progressDownloadPhotoCount = 0;
        for (DBMetadata* file in photoNameQueueForCurrentEventIdFromDropbox)
        {
            NSString* partialPath = [currentEventMetapath substringFromIndex:14]; //metadata.path is "/ChronicleMap/myEvents/eventid"
            NSString* localPhotoPath = [[[ATHelper getRootDocumentoryPath]  stringByAppendingPathComponent:partialPath] stringByAppendingPathComponent:file.filename];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:localPhotoPath]){
                //NSLog(@"    --- local %@ already=%d  success=%d   fail=%d",[localPhotoPath substringFromIndex:85], downloadAlreadyExistCount,downloadFromDropboxSuccessCount,downloadFromDropboxFailCount);
                [[self myRestClient] loadFile:[NSString stringWithFormat:@"%@/%@", currentEventMetapath, file.filename ] intoPath:localPhotoPath];
                progressDownloadTotalNumberOfPhotosInOneEvent ++;
            }
            else
            {
                downloadAlreadyExistCount ++;
                if (downloadFromDropboxStartCount == downloadAlreadyExistCount)
                    [self dequeueEventIdAndStartDownloadPhotos]; //call back also call this, but should not be duplicated. Remember callback is much behind in timeframe
            }
        }
        
    }
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"loadMetaFail",nil) message:error.description delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
    [alert show];
     */
    [self dequeueEventIdAndStartDownloadPhotos];
    if (showDownloadAllLoadMetadataErrorAlert)
    {
        [spinner stopAnimating];
        showDownloadAllLoadMetadataErrorAlert = false;
        NSString* path = (NSString*)[error.userInfo objectForKey:@"path"] ;
        NSString* eventId = nil;
        if (path != nil)
            eventId = [[path componentsSeparatedByString:@"/"] lastObject];
        if (error.code == 404 && [(NSString*)[error.userInfo objectForKey:@"error"] rangeOfString:@"not found" options:NSCaseInsensitiveSearch].location != NSNotFound )
        {  //If come here because of newAdded photo not uploaded yet, then do nothting except .... following ...
            if (![[self getDataController] isItInNewPhotoQueue:eventId])
            {
                //come here if directory in Dropbox cannot be found while we think it should. It may happen if /ChronicleMap/xxsourcexx is not in dropbox, Or it may also happen if we manually remove some directory from dropbox for this content
                downloadFromDropboxLoadMedadataFailCount ++;
            }
            return;
        }

        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Could not import from Dropbox",nil)
                                                       message: NSLocalizedString(@"May be the network is not available",nil)
                                                      delegate: self
                                             cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                             otherButtonTitles:nil,nil];
        
        
        [alert show];
    }
}
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath
       contentType:(NSString*)contentType metadata:(DBMetadata*)metadata {
    if (![localPath hasSuffix:@"thumbnail" ])
    {
        photoFromDropboxCell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Downloading .. %d success, %d warnings",nil), totalDownloadFromDropboxSuccessCount, downloadFromDropboxFailCount];
    }
	//[self promptCopyFromDropboxStatus];
    downloadFromDropboxSuccessCount++;
    progressDownloadPhotoCount ++;
    progressDownloadDetailView.progress = (float)progressDownloadPhotoCount/(float)progressDownloadTotalNumberOfPhotosInOneEvent;
    if (downloadFromDropboxSuccessCount + downloadAlreadyExistCount + downloadFromDropboxFailCount >= downloadFromDropboxStartCount)
        [self dequeueEventIdAndStartDownloadPhotos];
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
    downloadFromDropboxFailCount++;
    if (downloadFromDropboxSuccessCount + downloadAlreadyExistCount + downloadFromDropboxFailCount >= downloadFromDropboxStartCount)
        [self dequeueEventIdAndStartDownloadPhotos];
    photoFromDropboxCell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Downloading ... %d success, %d warnings",nil), totalDownloadFromDropboxSuccessCount, downloadFromDropboxFailCount];
    //[self promptCopyFromDropboxStatus];
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"loadFileFail",nil) message:error.description delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
    [alert show];
     */
}



- (BOOL) dropboxFolderAlreadyExist:(NSError*)error
{
    if (error.code == 403 && [(NSString*)[error.userInfo objectForKey:@"error"] rangeOfString:@"already exists" options:NSCaseInsensitiveSearch].location != NSNotFound)
        return true;
    else
        return false;
}
- (BOOL) dropboxDeleteFileNotExist:(NSError*)error
{
    if (error.code == 404 && [(NSString*)[error.userInfo objectForKey:@"error"] rangeOfString:@"not found" options:NSCaseInsensitiveSearch].location != NSNotFound)
        return true;
    else
        return false;
}

-(void) helpClicked:(id)sender //Only iPad come here. on iPhone will be frome inside settings and use push segue
{
    ATHelpWebView *helpView = [[ATHelpWebView alloc] init];//[storyboard instantiateViewControllerWithIdentifier:@"help_webview_id"];
    
    [self.navigationController pushViewController:helpView animated:true];
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
