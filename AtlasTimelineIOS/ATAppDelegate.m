//
//  ATAppDelegate.m
//  AtlasTimelineIOS
//
//  Created by Hong on 12/28/12.
//  Copyright (c) 2012 hong. All rights reserved.
//

#import <DropboxSDK/DropboxSDK.h>
#import "ATAppDelegate.h"
#import "ATimelineTableViewController.h"
#import "ATDataController.h"
#import "ATConstants.h"
#import "ATEventEntity.h"
#import "ATEventDataStruct.h"
#import "ATHelper.h"
#import "iRate.h"
#import "Crittercism.h"
#import "ATPreferenceViewController.h"

#import "SWRevealViewController.h"

#define EVENT_TYPE_NO_PHOTO 0
#define EVENT_TYPE_HAS_PHOTO 1

@interface ATAppDelegate ()<SWRevealViewControllerDelegate>
//TODO should add data store initialize here and pass data store to ATTimelineTableViewController, or the controller come to here to get data store
@property (nonatomic, strong) NSArray *periods;

@end

@implementation ATAppDelegate

@synthesize window=window_, periods=_periods;

SWRevealViewController *revealController;
ATimelineTableViewController* timelineViewController;
UINavigationController* preferenceViewNavController;

- (NSDateFormatter *)dateFormater {
	
    if (_dateFormater != nil) {
        return _dateFormater;
    }
    _dateFormater = [[NSDateFormatter alloc] init];
    //_dateFormater.dateStyle = NSDateFormatterMediumStyle;
    [_dateFormater setDateFormat:@"MM/dd/yyyy GG"];
    return _dateFormater;
}
- (NSString *)localizedAD {
	
    if (_localizedAD != nil) {
        return _localizedAD;
    }
    NSDate* today = [NSDate date];
    NSString* todayStr = [self.dateFormater stringFromDate:today];
    //NSLog(@"######### AD is %@",[todayStr substringFromIndex:11]);
    return [todayStr substringFromIndex:11];
}

+ (void)initialize
{
    //configure iRate
    [iRate sharedInstance].daysUntilPrompt = 5;
    [iRate sharedInstance].usesUntilPrompt = 15;
    
    //For testing
    //[iRate sharedInstance].previewMode = YES;
    
    /*
     //These ivars have the following meaning: wait 5 days before asking a review from the user and wait for at least 10 application usage. If the user tap Remind me later, then wait 3 days before asking a review again. Very nice.
    [iRate sharedInstance].appStoreID = 3333333;
    [iRate sharedInstance].applicationName=@"xxxx";
    [iRate sharedInstance].daysUntilPrompt = 5;
    [iRate sharedInstance].usesUntilPrompt = 10;
    [iRate sharedInstance].remindPeriod = 3;
    [iRate sharedInstance].message = NSLocalizedString(@"striRateMessage_KEY", striRateMessage);
    [iRate sharedInstance].NSLocalizedString(@"strrateButtonLabel_KEY", strrateButtonLabel);
    */
    
}

//this will easy to change database file name by just set eventListSorted to null
- (NSArray*) eventListSorted {
    if (_eventListSorted != nil)
        return _eventListSorted;
    ATDataController* dataController = [[ATDataController alloc] initWithDatabaseFileName:[ATHelper getSelectedDbFileName]];
    //sort from latest to past, so it is good for timeline view to group by year (could not do inplace sort use sortUseSelector etc)
    NSArray *sortedArray;
    sortedArray = [[dataController fetchAllEventEntities] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSDate *first = [(ATEventEntity*)a eventDate];
        NSDate *second = [(ATEventEntity*)b eventDate];
        return [first compare:second]== NSOrderedAscending;
    }];
    _eventListSorted =[[NSMutableArray alloc] initWithCapacity:100];
    //IMPORTANT: replace appDelegate's managed obj with pure object. without this, ATEventEntity fields will have nil value after pass to caller (changed for iOS7 )
    for (ATEventEntity* ent in sortedArray) {
 
        ATEventDataStruct* entData = [[ATEventDataStruct alloc] init];
        entData.address = ent.address;
        entData.eventDate = ent.eventDate;
        entData.eventDesc = ent.eventDesc;
        if ([ent.eventType intValue] == EVENT_TYPE_HAS_PHOTO)
            entData.eventType = EVENT_TYPE_HAS_PHOTO;
        //NSLog(@"event date=%@   eventType=%i",entData.eventDate, entData.eventType);
        entData.uniqueId = ent.uniqueId;
        entData.lat = [ent.lat doubleValue];
        entData.lng = [ent.lng doubleValue];
        [_eventListSorted addObject:entData];
    }
    if (self.uniqueIdToEventMap == nil)
    {
        self.uniqueIdToEventMap = [[NSMutableDictionary alloc] init];
        for (ATEventDataStruct* event in _eventListSorted)
        {
            [self.uniqueIdToEventMap setObject:event forKey:event.uniqueId];
        }
    }
    return _eventListSorted;
}


-(void) emptyEventList
{
    //used in ATPreferenceViewController when switch offline source
    [_eventListSorted removeAllObjects];
    _eventListSorted = nil;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window = window;

    
    
    [Crittercism enableWithAppID:@"548f983d51de5e9f042ec3f3"];
    ATViewController *controller;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        self.storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
    }
    else
    {
        self.storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    }
    controller = [self.storyBoard instantiateViewControllerWithIdentifier:@"map_view_id"];
    //controller = [self.storyBoard instantiateInitialViewController];
    
    timelineViewController = [self.storyBoard instantiateViewControllerWithIdentifier:@"timeline_view"];
    preferenceViewNavController = [self.storyBoard instantiateViewControllerWithIdentifier:@"preference_nav_id"];
    UINavigationController *mapViewNavigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    
    
    revealController = [[SWRevealViewController alloc] initWithRearViewController:nil frontViewController:mapViewNavigationController];
    revealController.delegate = self;
    revealController.rearViewRevealWidth = [ATConstants revealViewTimeLineViewWidth];
    revealController.rightViewRevealWidth = [ATConstants revealViewPreferenceWidth];
    revealController.rightViewRevealOverdraw = 0.0f; //important, default is 60
    [self setTimelineControllerAsRearController];
    revealController.rightViewController = preferenceViewNavController;
    self.viewController = revealController;
	
	self.window.rootViewController = self.viewController;
    
    //NSLog(@" -------dropbox root is %@", kDBRootDropbox);
    DBSession* dbSession =[[DBSession alloc] initWithAppKey:@"vmngs8cprefdyi3"
                                                  appSecret:@"o9ct42rr0696dzq" root:kDBRootDropbox]; // either kDBRootAppFolder or kDBRootDropbox;
    [DBSession setSharedSession:dbSession];
    
    [[DBSession sharedSession] unlinkAll];//IMPORTANT: so each restart will ask user login to drobox. Without this, once login to dropbox from app, even reinstall app will not ask to login again, there is no way to switch dropbox account
    
    return YES;
}

-(void) setTimelineControllerAsRearController
{
    UINavigationController *rearNavigationController = [[UINavigationController alloc] initWithRootViewController:timelineViewController]; //rear view is left side view
    revealController.rearViewController = rearNavigationController;
}
-(UINavigationController*) getPreferenceViewNavController
{
    return preferenceViewNavController;
}

//SWRevealViewController delegate method
//   from https://github.com/John-Lluch/SWRevealViewController/issues/92
- (void)revealController:(SWRevealViewController *)revealController willMoveToPosition:(FrontViewPosition)position
{
    if (position == FrontViewPositionLeftSide) {      // right side will get revealed
        self.rightSideMenuRevealedFlag = true;
    }
    else if (position == FrontViewPositionLeft){      // right side will close
        self.rightSideMenuRevealedFlag = false;
    }
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully!");
            // At this point you can start making API calls
        }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
