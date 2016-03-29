//
//  ATDownloadTableViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 2/17/13.
//  Copyright (c) 2013 hong. All rights reserved.
//
#define DOWNLOAD_REPLACE_MY_SOURCE_ALERT 2
#define DOWNLOAD_AGAIN_ALERT 3
#define DOWNLOAD_CONFIRM 4
#define DELETE_INCOMING_ON_SERVER_CONFIRM 5

#import "ATDownloadTableViewController.h"
#import "ATConstants.h"
#import "ATHelper.h"
#import "ATAppDelegate.h"
#import "ATEventDataStruct.h"

@interface ATDownloadTableViewController ()

@end

@implementation ATDownloadTableViewController

NSMutableArray* filteredList;
NSMutableArray* localList;
NSString* selectedAtlasName;
NSArray* downloadedJson;
UIActivityIndicatorView* spinner;
int swipPromptCount;

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
    swipPromptCount = 0;

    /*********  here is test for test *****/
   // [userDefault removeObjectForKey:[ATConstants UserEmailKeyName]];
   // [userDefault removeObjectForKey:[ATConstants UserSecurityCodeKeyName]];
   // [userDefault synchronize];
    /**********************************/

    localList = [[NSMutableArray alloc] initWithArray:[ATHelper listFileAtPath:[ATHelper applicationDocumentsDirectory]]];

    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString *userId = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
    NSString *securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
    
    NSString* serviceUrl = [NSString stringWithFormat:@"%@/retreivelistofcontents?user_id=%@&security_code=%@",[ATConstants ServerURL], userId, securityCode];
    NSString* responseStr = [ATHelper httpGetFromServer:serviceUrl :false];
    NSArray* libraryList = nil;
    if (responseStr == nil || [responseStr isEqualToString:@""])
    {
        libraryList = [userDefault objectForKey:@"CONTENTS_LIST_FROM_SERVER"];
        if (libraryList == nil)
        {
            libraryList = @[[ATConstants defaultSourceName]];
        }
    }
    else
    {
        libraryList = [responseStr componentsSeparatedByString:@"|"];
        [userDefault setObject:libraryList forKey:@"CONTENTS_LIST_FROM_SERVER"];
    }
    filteredList = [[NSMutableArray alloc] init];
    //should use predicate to filter nil
    for (int i=0; i< [libraryList count]; i++)
    {
        NSString* item = libraryList[i];
        if (item != nil && [item length]>0)
            [filteredList addObject:libraryList[i]];
    }
    //Note: server sorted by create_date already by proc getLibraryList
    [filteredList removeObject:[ATConstants defaultSourceName]]; //"myEvents" should be always at top after sort
    [filteredList insertObject:[ATConstants defaultSourceName] atIndex:0];

    spinner = [[UIActivityIndicatorView alloc]
               initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = CGPointMake(160, 200);
    spinner.hidesWhenStopped = YES;
    [[self  view] addSubview:spinner];
   
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   // Return the number of rows in the section.
    return [filteredList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"downloadcellswap";
    bool firstRowflag = false;
    if (indexPath.row == 0)
    {
        CellIdentifier = @"downloadcelswp_firstrow";
        firstRowflag = true;
    }
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    SWTableViewCell *cell = (SWTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        NSMutableArray *rightUtilityButtons = [NSMutableArray new];
        //see action in didTriggerRightUtilityButtonWithIndex
        if (firstRowflag)
        {
            [rightUtilityButtons sw_addUtilityButtonWithColor:
             [UIColor colorWithRed:0.78f green:0.38f blue:0.5f alpha:1.0]
                                                        title:NSLocalizedString(@"Backup",nil)];
            [rightUtilityButtons sw_addUtilityButtonWithColor:
             [UIColor colorWithRed:0.6f green:0.4f blue:0.5f alpha:1.0]
                                                        title:NSLocalizedString(@"Restore",nil)];
            [rightUtilityButtons sw_addUtilityButtonWithColor:
             [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                        title:NSLocalizedString(@"Map It",nil)];
        }
        else
        {
            [rightUtilityButtons sw_addUtilityButtonWithColor:
            [UIColor colorWithRed:0.78f green:0.38f blue:0.5f alpha:1.0]
                                                    title:NSLocalizedString(@"Delete",nil)];
            [rightUtilityButtons sw_addUtilityButtonWithColor:
            [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                    title:NSLocalizedString(@"Map It",nil)];
        }
        cell = [[SWTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier
                                  containingTableView:self.tableView // For row height and selection
                                   leftUtilityButtons:nil
                                  rightUtilityButtons:rightUtilityButtons];
        cell.delegate = self;
        cell.tag = indexPath.row;
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
    }

    
    // Configure the cell...
    NSString* tmpAtlasName = filteredList[indexPath.row];
    BOOL unreadEpisode = false;
    if ([tmpAtlasName hasPrefix:@"1*"]) //1* means unreaded episode. see java serverside code
    {
        unreadEpisode = true;//so bold it as new message
        tmpAtlasName = [tmpAtlasName substringFromIndex:2]; //remove 1* when display in text, and this text will be used when download from server
    }
    
    //for episode from other user, name has * in it
    if ([tmpAtlasName rangeOfString:@"*"].location != NSNotFound)
    {
        NSArray* nameList = [tmpAtlasName componentsSeparatedByString:@"*"];
        cell.textLabel.text = nameList[0];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@    %@",nameList[2], nameList[1]];
    }
    else
    {
        if ([localList containsObject:tmpAtlasName])
        {
            
        }
        cell.textLabel.text = tmpAtlasName;
        cell.detailTextLabel.text = @"";
    }

    if ([filteredList[indexPath.row] isEqual:[ATConstants defaultSourceName]]) // for myEvents row
    {
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:19.0];
        cell.detailTextLabel.text = NSLocalizedString(@"  << Left swipe to backup/restore",nil);
    }
    else
    {
        if (unreadEpisode)
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:17.0];
        else
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0];
        //cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }

    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([tmpAtlasName isEqualToString:appDelegate.sourceName])
    {
        cell.textLabel.textColor = [UIColor blueColor];
        [ATHelper getStatsForEvent:tmpAtlasName tableCell:cell];
    }
    else
    {
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

        if (swipPromptCount >= 1)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please swipe left",nil) message:[NSString stringWithFormat:@""] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            [alert show];
            swipPromptCount = 0;
        }
        else
        {
            swipPromptCount++;
        }
}

//swapable delegate
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    int row = cell.tag;
    selectedAtlasName = filteredList[row];
    if ([selectedAtlasName hasPrefix:@"1*"])
        selectedAtlasName = [selectedAtlasName substringFromIndex:2];
    NSString* displayName = selectedAtlasName;
    if ([displayName rangeOfString:@"*"].location != NSNotFound)
    {
        NSArray* nameList = [displayName componentsSeparatedByString:@"*"];
        displayName = nameList[0];
        
    }
    switch (index) {
        case 0: //DELETE swipe (backup for first row)
        {
            if ([selectedAtlasName isEqualToString:[ATConstants defaultSourceName]])
            {
                [self.parent startExport]; //do myEvents backup
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"Delete [%@]",nil),displayName]
                                                           message: NSLocalizedString(@"Are you sure to delete it?",nil)
                                                          delegate: self
                                                 cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                 otherButtonTitles:NSLocalizedString(@"Continue",nil),nil];
                alert.tag = DELETE_INCOMING_ON_SERVER_CONFIRM;
                NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
                NSString *userId = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
                if (userId == nil)
                {
                    alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Please login first!",nil)
                                                                   message: @""
                                                                  delegate: self
                                                         cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                         otherButtonTitles:nil,nil];
                }
                [alert show];
            }

            break;
        }
        case 1: //map it
        {
            if ([selectedAtlasName isEqualToString:[ATConstants defaultSourceName]])
            {
                [self.parent startDownloadMyEventsJson];
            }
            else if (![localList containsObject:selectedAtlasName]) //selectedAtlasName may contains * suchas aaa
            {
                [self startDownload];
            }
            else
            {
                [self.delegate downloadTableViewController:self didSelectSource:selectedAtlasName];
            }

            break;
        }
        case 2: //set Active for first row myEvents
        {
            [self.delegate downloadTableViewController:self didSelectSource:selectedAtlasName];
        }
        default:
            break;
    }
}

//TODO not used anymore
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == DELETE_INCOMING_ON_SERVER_CONFIRM)
    {
        if (buttonIndex == 0)
            return;
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        NSString *userId = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
        NSString *securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
        if (userId == nil)
            return;
        NSString* serviceUrl = [NSString stringWithFormat:@"%@/deleteincomingepisode?user_id=%@&security_code=%@&episode_name=%@",[ATConstants ServerURL], userId, securityCode,selectedAtlasName];
        NSString* responseStr = [ATHelper httpGetFromServer:serviceUrl];
        if ([@"SUCCESS" isEqualToString:responseStr])
        {
            [filteredList removeObject:selectedAtlasName];
            [self.tableView reloadData];
        }
    }
    else
    {
        if (buttonIndex == 0)
        {
            NSLog(@"user canceled upload");
            // Any action can be performed here
        }
    }
}

//NOTE at serverside, if do not find user own this, it means user first time selected a public_share file, server will first copy it to user's row, then download, so user can modify its own copy
-(void) startDownload
{
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    [spinner startAnimating];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    Boolean successFlag = [ATHelper checkUserEmailAndSecurityCode:self];
    if (!successFlag)
    {
        //if user not login, then network not availbe case will be alert
        return;
    }
    NSString* userEmail = [userDefault objectForKey:[ATConstants UserEmailKeyName]];
    NSString* securityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
    //continues to get from server
    NSString* userId = userEmail;
    [localList addObject:selectedAtlasName];
    NSString* atlasName = [selectedAtlasName stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSString* urlString = [NSString stringWithFormat:@"%@/downloadjsoncontents?user_id=%@&security_code=%@&atlas_name=%@",[ATConstants ServerURL], userId, securityCode, atlasName];
    //NSLog(@"-- bf encoding%@",urlString);
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];//so atlasName is other language will work
    //NSLog(@"-- after encoding%@",urlString);
    NSURL* serviceUrl = [NSURL URLWithString:urlString];

    NSData* downloadedData = [NSData dataWithContentsOfURL:serviceUrl];
    
    if (downloadedData == nil)
    {
        [self displayDownloadErrorAlert];
        return;
    }
        
    NSError* error;
    downloadedJson = [NSJSONSerialization JSONObjectWithData:downloadedData options:kNilOptions error:&error];
    if (downloadedJson == nil || [downloadedJson count] == 0 ) //this will happen when network is poor. I got this when in IHOP church on 1/10/16 where air condition has been turned on because of hot whether 62+ F
    {
        [self displayDownloadErrorAlert];
        return;
    }
    
    appDelegate.sourceName = selectedAtlasName; //TODO add 12/30/15 for merge menu, not sure this is right place to add, need test. just the logically I think should add this here
    [ATHelper startReplaceDb:selectedAtlasName :downloadedJson :spinner];
    [_parent changeSelectedSource: selectedAtlasName];
    [self.delegate downloadTableViewController:self didSelectSource:selectedAtlasName];
}

- (void) displayDownloadErrorAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network is unavailable!",nil) message:NSLocalizedString(@"Network may not be available, Please try later!",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
    [alert show];
}

@end
