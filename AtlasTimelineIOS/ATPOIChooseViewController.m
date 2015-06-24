//
//  ATPOIChooseViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 5/17/15.
//  Copyright (c) 2015 hong. All rights reserved.
//

#import "ATPOIChooseViewController.h"
#import "ATHelper.h"
#import "ATAppDelegate.h"
#import "SWRevealViewController.h"

@interface ATPOIChooseViewController ()

@end

@implementation ATPOIChooseViewController

NSArray* poiGroupList;
NSString* selectedPoiGroupName;
NSInteger selectedPoiGroupIdxForDeselect;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.delegate = appDelegate.mapViewController;
    NSString * language = [[[NSLocale preferredLanguages] objectAtIndex:0] substringToIndex:2]; //return zh for chinese
    NSString* serviceUrl = [NSString stringWithFormat:@"http://www.chroniclemap.com/resources/poi_list.html"];
    if ([@"zh" isEqualToString:language])
        serviceUrl = [NSString stringWithFormat:@"http://www.chroniclemap.com/resources/poi_list_zh.html"];
    
    NSString* responseStr  = [ATHelper httpGetFromServer:serviceUrl :false];
    poiGroupList = [[NSMutableArray alloc] init];
    //polist.html has format of :
    /*
     Asia
     Africa
     Eastern Europe
     
     */
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    selectedPoiGroupName = [userDefaults objectForKey:@"SELECTED_POI_GROUP_NAME"];
    if (responseStr == nil)
    {
        responseStr = [userDefaults objectForKey:@"GROUP_POI_SAVED"];
    }
    else
    {
        [userDefaults setObject:responseStr forKey:@"GROUP_POI_SAVED"];
    }
    if (responseStr != nil && [responseStr length] > 100)
    {
        poiGroupList = [responseStr componentsSeparatedByString:@"\n"];
        
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network is unavailable!",nil)
                                                        message:NSLocalizedString(@"You need network the first time access POI",nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [poiGroupList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier;
    // Configure the cell...
    UITableViewCell *cell;
    
    NSString* poiRowText = poiGroupList[indexPath.row];

    CellIdentifier = @"PeriodCell";
    cell = [tableView  dequeueReusableCellWithIdentifier:CellIdentifier];



    cell.textLabel.text = [self getPoiTitle:poiRowText];
    cell.detailTextLabel.text = [self getPoiSubTitle:poiRowText];

    if ([selectedPoiGroupName isEqualToString:[self getPoiTitle:poiRowText]])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        selectedPoiGroupIdxForDeselect = indexPath.row;
    }
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* poiRowText = poiGroupList[indexPath.row];
    NSString* poiGroupName = [self getPoiTitle:poiRowText];
    selectedPoiGroupName = poiGroupName;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (selectedPoiGroupIdxForDeselect != NSNotFound) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath
                                                                  indexPathForRow:selectedPoiGroupIdxForDeselect inSection:0]];
        cell.accessoryType = UITableViewCellAccessoryNone;
        selectedPoiGroupIdxForDeselect = indexPath.row;
    }
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:poiGroupName forKey:@"SELECTED_POI_GROUP_NAME"];
    [userDefaults synchronize];
    
    if (indexPath.row == 0)
    {
        NSArray* poiList = [[NSArray alloc] init];
        [self.delegate poiGroupChooseViewController:self didSelectPoiGroup:poiList]; //clean map with empty array to mapview
        return;
    }
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
    //TODO  following spinner does not work /////////
    // Get center of cell (vertically)
    int center = [cell frame].size.height / 2;
    CGSize size = [[[cell textLabel] text] sizeWithFont:[[cell textLabel] font]];
    [spinner setFrame:CGRectMake(size.width + 25, center - 25 / 2, 25, 25)];
    [[cell contentView] addSubview:spinner];
    spinner.tag = 9999;
    //UIActivityIndicatorView* spinner = (UIActivityIndicatorView*)[cell.contentView viewWithTag:9999];
    [spinner startAnimating];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]]; //Tricky: yield main loop so spinner will show progress
    NSString* serviceUrl = [NSString stringWithFormat:@"http://www.chroniclemap.com/resources/poi/%@.html", [self getPoiFileName:poiRowText]];
    //####
    //#### following may return nil if %@.html file is not utf-8 encoded (linux: file -bi filename)
    //####
    NSString* responseStr  = [ATHelper httpGetFromServer:serviceUrl :false];
    
    if (responseStr == nil)
    {
        responseStr = [userDefaults objectForKey:poiGroupName];
    }
    else
    {
        [userDefaults setObject:responseStr forKey:poiGroupName];
    }
    
    //[self dismissViewControllerAnimated:NO completion:nil]; //for iPhone case

    
    if (responseStr != nil)
    {
        //Asia.html has format of :
        /*
         [place]xxxxx
         [loc]23.22,1.222
         [Desc]
         ....
         
         [Place]xxxx
         .....
         */
        //////TODO
        
        //TODO [refer to createdEventListFromString function in Reader version]
        NSArray* poiList = [ATHelper createdPoiListFromString:responseStr];
        
        [self.delegate poiGroupChooseViewController:self didSelectPoiGroup:poiList];
        
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network is unavailable!",nil)
                                                        message:NSLocalizedString(@"You need network the first time access this POI group",nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                              otherButtonTitles:nil];
        [alert show];
        
    }

    [spinner stopAnimating];
    [spinner removeFromSuperview];
    
    SWRevealViewController* revealController = [self revealViewController];
    [revealController rightRevealToggle:nil];
}

////On server, poi_list_xx.html has format: poiDisplayText|poiFileName:.......
-(NSString*)getPoiTitle:(NSString*)poiRow
{
    NSArray* poiRowText = [poiRow componentsSeparatedByString:@":"];
    NSString* poiHeaderText = poiRowText[0];
    NSArray* textArr = [poiHeaderText componentsSeparatedByString:@"|"];
    return textArr[0];
}
-(NSString*) getPoiFileName:(NSString*)poiRow
{
    NSArray* poiRowText = [poiRow componentsSeparatedByString:@":"];
    NSString* poiHeaderText = poiRowText[0];
    NSArray* textArr = [poiHeaderText componentsSeparatedByString:@"|"];
    return textArr[1];
}
-(NSString*) getPoiSubTitle:(NSString*)poiRow
{
    NSArray* poiRowText = [poiRow componentsSeparatedByString:@":"];
    if ([poiRowText count] > 1)
        return poiRowText[1];
    else
        return @"";
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"reaching accessoryButtonTappedForRowWithIndexPath: section %d   row %d", indexPath.section, indexPath.row);
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
