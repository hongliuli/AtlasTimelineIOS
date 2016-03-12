//
//  ATViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 12/28/12.
//  Copyright (c) 2012 hong. All rights reserved.
//


#define IN_APP_PURCHASED @"IN_APP_PURCHASED"
#define ALERT_FOR_SAVE 1
#define ALERT_FOR_POPOVER_ERROR 2
#define ALERT_FOR_DIRECTION_MODE 3
#define ALERT_FOR_NEW_APP 4
#define MAX_NUMBER_OF_POI_IN_EVENT_VIEW 20

#define POI_DISPLAY_TYPE_RED_DOT 99
#define POI_DISPLAY_TYPE_STAR 5
#define POI_DISPLAY_TYPE_ORANGE 50

#define PHOTO_META_FILE_NAME @"MetaFileForOrderAndDesc"
#define ALERT_FOR_SYNC_PROMPT_DISABLE 999

#import <QuartzCore/QuartzCore.h>

#import "ATViewController.h"
#import "ATDefaultAnnotation.h"
#import "ATAnnotationSelected.h"
#import "ATAnnotationPoi.h"
#import "ATAnnotationFocused.h"
#import "ATDataController.h"
#import "ATEventEntity.h"
#import "ATEventDataStruct.h"
#import "ATEventEditorTableController.h"
#import "ATAppDelegate.h"
#import "ATConstants.h"
#import "ATTimeZoomLine.h"
#import "ATHelper.h"
#import "ATPreferenceEntity.h"
#import "ATTimeScrollWindowNew.h"
#import "ATTutorialView.h"
#import "ATInAppPurchaseViewController.h"
#import "ATEventListWindowView.h"
#import "UIView+Toast.h"

#import "SWRevealViewController.h"

#define EVENT_TYPE_NO_PHOTO 0
#define EVENT_TYPE_HAS_PHOTO 1

#define MERCATOR_OFFSET 268435456
#define MERCATOR_RADIUS 85445659.44705395
#define ZOOM_LEVEL_TO_HIDE_DESC 4
#define ZOOM_LEVEL_TO_HIDE_DESC_IN_MAP_MODE 7
#define ZOOM_LEVEL_TO_HIDE_EVENTLIST_VIEW 6
#define ZOOM_LEVEL_TO_HIDE_POI_IN_EVENTLIST_VIEW 7
#define ZOOM_LEVEL_TO_SEND_WHITE_FLAG_BEHIND_IN_REGION_DID_CHANGE 9
#define ZOOM_LEVEL_POI_11 11
#define ZOOM_LEVEL_POI_7 7
#define ZOOM_LEVEL_POI_4 4

#define DISTANCE_TO_HIDE 80

#define RESIZE_WIDTH 600
#define RESIZE_HEIGHT 450
#define THUMB_WIDTH 120
#define THUMB_HEIGHT 70
#define JPEG_QUALITY 1.0

#define FREE_VERSION_QUOTA 50

#define EDITOR_PHOTOVIEW_WIDTH 190
#define EDITOR_PHOTOVIEW_HEIGHT 160
#define NEWEVENT_DESC_PLACEHOLD NSLocalizedString(@"Write notes here",nil)
#define NEW_NOT_SAVED_FILE_PREFIX @"NEW"

#define TIME_LINK_DASH_LINE_STYLE_FOR_SAME_DEPTH 1
#define TIME_LINK_SOLID_LINE_STYLE 2

//TODO Following should be in configuration settings
#define TIME_LINK_DEPTH 6
#define TIME_LINK_MAX_NUMBER_OF_DAYS_BTW_TWO_EVENT 30
#define MAX_NUMBER_OF_TIME_LINKS_IN_SAME_DEPTH_GROUP 10 //Must be even number. the purpose is to reduce too many line if too may events in same group

#define MAPVIEW_HIDE_ALL 1
#define MAPVIEW_SHOW_PHOTO_LABEL_ONLY 2
#define MAPVIEW_SHOW_ALL 3

#define HAVE_IMAGE_INDICATOR 100

#define EPISODE_VIEW_WIDTH 320
#define EPISODE_VIEW_HIGHT_LARGE 410
#define EPISODE_VIEW_HIGHT_SMALL 140
#define EPISODE_ROW_HEIGHT 30

#define PHOTO_META_FILE_NAME @"MetaFileForOrderAndDesc"
#define PHOTO_META_SORT_LIST_KEY @"sort_key"
#define PHOTO_META_DESC_MAP_KEY @"desc_key"

@interface MFTopAlignedLabel : UILabel

@end

/*
@interface UIWindow (AutoLayoutDebug)
+ (UIWindow*)keyWindow;
-(NSString*)_autolayoutTrace;
@end
*/

@implementation ATViewController
{
    NSString* selectedAnnotationIdentifier;
    int debugCount;
    CGRect focusedLabelFrame;
    NSMutableArray* timeScaleArray;
    
    NSMutableArray* selectedAnnotationNearestLocationList; //do not add to annotationToShowImageSet if too close
    NSMutableDictionary* annotationToShowImageSet;//hold uilabels for selected annotation's description
    NSMutableDictionary* tmpLblUniqueIdMap;
    int tmpLblUniqueMapIdx;
    NSMutableSet* selectedAnnotationViewsFromDidAddAnnotation;
    NSDate* regionChangeTimeStart;
    ATDefaultAnnotation* newAddedPin;
    UIButton *locationbtn;
    UIButton *switchEventListViewModeBtn;
    CGRect timeScrollWindowFrame;
    ATTutorialView* tutorialView;
    UIView* episodeView; //we do not need to have a ATEpisodeView as ATTutorialView because ATTutorialView has to implement drawRect for some customised graph draw
    UILabel* lblEpisode1;
    NSString* episodeNameforUpdating; //if user picked a episode to update
    UITextView* txtNewEpisodeName;
    
    ATInAppPurchaseViewController* purchase; // have to be global because itself has delegate to use it self
    NSMutableDictionary* timeLinkOverlayDepthColorMap; // latlngTimeLinkDepthMapForOverlay;
    NSInteger timeLinkDepthDirectionFuture;
    NSInteger timeLinkDepthDirectionPast;
    NSMutableArray* timeLinkOverlaysToBeCleaned ;
    NSMutableArray* eventEpisodeList;
    NSString* loadedEpisodeName; //if an episode is loaded from setting -> outgoing modify
    ATAnnotationFocused* focusedAnnotationIndicator;
    int currentTapTouchKey;
    bool currentTapTouchMove;
    UIButton *btnLess;
    ATEventListWindowView* eventListView;
    
    ATEventDataStruct* currentSelectedEvent;
    MKAnnotationView* selectedEventAnnInEventListView;
    MKAnnotationView* selectedEventAnnOnMap;
    ATEventAnnotation* selectedEventAnnDataOnMap;
    
    BOOL switchEventListViewModeToVisibleOnMapFlag;
    NSMutableArray* eventListInVisibleMapArea;
    
    NSMutableArray* animationCameras;
    NSMutableArray* _directionOverlayArray;
    ATEventAnnotation   *_destAnnForDirection;
    UIView* _directionInfoView;
    NSArray* _directionRouteColorResultSet;
    NSMutableArray* _directionRouteDistanceResultSet;
    int _directionCurrentDistanceIndex;
    UILabel* _lblDirectionDistance;
    NSArray* _topDistanceLblCon; //will animated on this
    NSTimer* _timerDirectionRouteDisplay;
    CLLocationCoordinate2D currentCenterCoordinate;

    NSMutableDictionary* poiAnnViewDic; //uniqueId->annView, need this because select an poi from event list view will not refresh poi ann (for regualar event, refresh occurs every time select)
    MKAnnotationView* prevSelectedPoiAnnView;
    NSMutableArray *prevSearchResult;
    BOOL onlyRunViewDidAppearOnce;
    
    NSString* prevSelectedEventId;
    
    NSMutableArray* orangePoiOnMap;
    
    BOOL firstTimeShowFlag;
    
    CSToastStyle *tutorialStyle;
    int prevZoomLevel;
}

@synthesize mapView = _mapView;

- (ATDataController *)dataController { //initially I want to have a singleton of dataController here, but not good if user change database file source, instance it ever time. It is ok here because only called every time user choose to delete/insert
    dataController = [[ATDataController alloc] initWithDatabaseFileName:[ATHelper getSelectedDbFileName]];
    return dataController;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.rightSideMenuRevealedFlag = FALSE;
    onlyRunViewDidAppearOnce = FALSE;
    /////switchEventListViewModeToVisibleOnMapFlag = false; //eventListView for timewheel is more reasonable, so make it as default always, even not save to userDefault
    [ATHelper createPhotoDocumentoryPath];
    [ATHelper createWebCachePhotoDocumentoryPath];
    _directionRouteColorResultSet = @[[UIColor blueColor],[UIColor orangeColor],[UIColor greenColor],[UIColor purpleColor]];
    self.locationManager = [[CLLocationManager alloc] init];
    //add for ios8
    self.locationManager.delegate = self;
    if ([ATHelper isAtLeastIOS8]) {
        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager requestAlwaysAuthorization];
    }
    
    /*
    NSDate* poiDate = [fmt dateFromString:@"12/31/9999 AD"];
    if (poiList == nil)
        poiList = [[NSMutableArray alloc] init];
    for (int i = 0; i<=1000; i ++)
    {
        ATEventDataStruct* evt = [[ATEventDataStruct alloc] init];
        int r = arc4random() % 100000000;
        evt.uniqueId = [NSString stringWithFormat:@"%d", r];
        evt.eventDate = poiDate;
        evt.eventDesc = [NSString stringWithFormat:@"title %d\ndesc for %d",r,r];
        evt.eventType = arc4random() % 5; //used i for star rating
        evt.lat = arc4random() % 90;
        evt.lng = arc4random() % 180;
        [poiList addObject:evt];
    }
     */
    self.mapViewShowWhatFlag = MAPVIEW_SHOW_ALL;
    int searchBarHeight = [ATConstants searchBarHeight];
    int searchBarWidth = [ATConstants searchBarWidth];
    [self.navigationItem.titleView setFrame:CGRectMake(0, 0, searchBarWidth, searchBarHeight)];
    
    //Find this spent me long time: searchBar used titleView place which is too short, thuse tap on searchbar right side keyboard will not show up, now it is good
	[self calculateSearchBarFrame];
    
    SWRevealViewController *revealController = [self revealViewController];
    [revealController panGestureRecognizer];
    [revealController tapGestureRecognizer];
    UIBarButtonItem *timelineBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"List/Search"
                                                                         style:UIBarButtonItemStyleBordered target:revealController action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = timelineBarButtonItem;
    
    
    // create a custom navigation bar button and set it to always says "Back"
	UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
	temporaryBarButtonItem.title = NSLocalizedString(@"Back",nil);
	self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    
    //add two button at right (can not do in storyboard for multiple button): setting and Help, available in iOS5
    //   if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    //   {
    
  UIBarButtonItem *settringButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"ios-menu-icon-star.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]  style:UIButtonTypeCustom target:self action:@selector(settingsClicked:)];
    
    //NOTE the trick to set background image for a bar buttonitem
    UIButton *helpbtn = [UIButton buttonWithType:UIButtonTypeCustom];
    helpbtn.frame = CGRectMake(0, 0, 30, 30);
    [helpbtn setImage:[UIImage imageNamed:@"help.png"] forState:UIControlStateNormal];
    [helpbtn addTarget:self action:@selector(tutorialClicked:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithCustomView:helpbtn];
    //if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        self.navigationItem.rightBarButtonItems = @[settringButton, helpButton];
    //else
      //  self.navigationItem.rightBarButtonItems = @[settringButton];
    
    /*
    UIButton *poiLoadViewBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    poiLoadViewBtn.frame = CGRectMake(0, 0, 20, 20);
    [poiLoadViewBtn setImage:[UIImage imageNamed:@"star-red-orig.png"] forState:UIControlStateNormal];
    [poiLoadViewBtn addTarget:self action:@selector(choosePoiClicked:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *poiButton = [[UIBarButtonItem alloc] initWithCustomView:poiLoadViewBtn];
     */

    
    //   }
    
    
	// Do any additional setup after loading the view, typically from a nib.
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPressGesture:)];
    lpgr.minimumPressDuration = 0.3;  //user must press for 0.5 seconds
    [_mapView addGestureRecognizer:lpgr];
    // tap to show/hide timeline navigator
    UITapGestureRecognizer *tapgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [_mapView addGestureRecognizer:tapgr];
    
    annotationToShowImageSet = [[NSMutableDictionary alloc] init];
    tmpLblUniqueIdMap = [[NSMutableDictionary alloc] init];
    tmpLblUniqueMapIdx = 1;
    selectedAnnotationNearestLocationList = [[NSMutableArray alloc] init];
    regionChangeTimeStart = [[NSDate alloc] init];
    [self prepareMapView];
    
    if (switchEventListViewModeBtn == nil)
        switchEventListViewModeBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    else
        [switchEventListViewModeBtn removeFromSuperview];
    switchEventListViewModeBtn.frame = CGRectMake(10, 73, 100, 30);
    [switchEventListViewModeBtn.titleLabel setFont:[UIFont fontWithName:@"Arial-Bold" size:25]];
    [[switchEventListViewModeBtn layer] setBorderWidth:2.0f];
    
    [self setSwitchButtonMapMode];

    [switchEventListViewModeBtn addTarget:self action:@selector(switchEventListViewMode:) forControlEvents:UIControlEventTouchUpInside];
    [switchEventListViewModeBtn.layer setCornerRadius:7.0f];
    [self.mapView addSubview:switchEventListViewModeBtn];
    eventListInVisibleMapArea = nil;
    [self refreshEventListView:false];
}
-(void) viewDidAppear:(BOOL)animated
{
    firstTimeShowFlag = true;
    [self displayTimelineControls]; //MOTHER FUCKER, I struggled long time when I decide to put timescrollwindow at bottom. Finally figure out have to put this code here in viewDidAppear. If I put it in viewDidLoad, then first time timeScrollWindow will be displayed in other places if I want to display at bottom, have to put it here
    [self.timeZoomLine showHideScaleText:false];
    [ATHelper setOptionDateFieldKeyboardEnable:false]; //always set default to not allow keyboard
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self.navigationItem.leftBarButtonItem setTitle:NSLocalizedString(@"Find",nil)];
    [self.searchBar setPlaceholder:NSLocalizedString(@"Poi or Address", nil)];
    tutorialStyle = [[CSToastStyle alloc] initWithDefaultStyle];
    tutorialStyle.imageSize = CGSizeMake(300, 600); //for iPad
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        if (UIDeviceOrientationIsPortrait(orientation))
            tutorialStyle.imageSize = CGSizeMake(80, 160);
        else
            tutorialStyle.imageSize = CGSizeMake(150, 300);
    }
    if ([appDelegate.eventListSorted count] == 0)
    {
        /*
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add your first event",nil) message:NSLocalizedString(@"Add event by long press on a map location, or search an address. You can also import [TestEvents] in [Settings->My Collections] to learn more.",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
         */
        //[self addFirstDemoEvent]
        
        void (^tutorialOtherFeaturesBlock)(UIView*, CSToastStyle*) = ^(UIView* parentView, CSToastStyle* style) {
            [ATHelper tutorialToastOtherFeatures:parentView style:style nextToToast:nil];
        };
        void (^tutorialCreateEventBlock)(UIView*, CSToastStyle*) = ^(UIView* parentView, CSToastStyle* style) {
            [ATHelper tutorialToastCreateEditEvent:parentView style:style nextToToast:tutorialOtherFeaturesBlock];
        };
        
        [ATHelper startTutorialToasts:self.view style:tutorialStyle nextToToast:tutorialCreateEventBlock];

    }
    if (eventListView == nil) //viewDidAppear will be called when navigate back (such as from timeline/search view and full screen event editor, so need to check. Always be careful of viewDidAppear to not duplicate instances
    {
        eventListView = [[ATEventListWindowView alloc] initWithFrame:CGRectMake(0,100, 0, 0)];
        [eventListView.tableView setBackgroundColor:[UIColor clearColor] ];// colorWithRed:1 green:1 blue:1 alpha:0.7]];
        [self.mapView addSubview:eventListView];
    }
    [self refreshEventListView:false];
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* lastOpenedPoiGroupName = [userDefaults objectForKey:@"SELECTED_POI_GROUP_NAME"];
    if (lastOpenedPoiGroupName != nil && !onlyRunViewDidAppearOnce)
    {
        //add poi (first remove existing poi if exists)
        NSMutableArray * annotationsToRemove = [ self.mapView.annotations mutableCopy ] ;
        for (ATEventAnnotation* ann in self.mapView.annotations)
        {
            if (![ann isKindOfClass:[ATAnnotationPoi class]])
                [annotationsToRemove removeObject:ann];
        }
        [[self mapView] removeAnnotations:annotationsToRemove];
        NSString* poiStr = [userDefaults objectForKey:lastOpenedPoiGroupName];
        if (poiStr != nil)
        {
            NSArray* poiList = [ATHelper createdPoiListFromString:poiStr];
            for (ATEventDataStruct* ent in poiList)
            {
                CLLocationCoordinate2D coord = CLLocationCoordinate2DMake((CLLocationDegrees)ent.lat, (CLLocationDegrees)ent.lng);
                ATAnnotationPoi *eventAnnotation = [[ATAnnotationPoi alloc] initWithLocation:coord];
                eventAnnotation.uniqueId = ent.uniqueId;
                eventAnnotation.address = ent.address;
                eventAnnotation.description=ent.eventDesc;
                eventAnnotation.eventDate=ent.eventDate;
                eventAnnotation.eventType = ent.eventType;
                [self.mapView addAnnotation:eventAnnotation];
                if (orangePoiOnMap == nil)
                    orangePoiOnMap = [[NSMutableArray alloc] init];
                if (ent.eventType == POI_DISPLAY_TYPE_ORANGE)
                    [orangePoiOnMap addObject:eventAnnotation];
            }
        }
        onlyRunViewDidAppearOnce = TRUE;
    }
}


-(void)setSwitchButtonTimeMode
{
    switchEventListViewModeToVisibleOnMapFlag = false;
    [switchEventListViewModeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [switchEventListViewModeBtn setTitle:NSLocalizedString(@"By Time",nil) forState:UIControlStateNormal];
    [[switchEventListViewModeBtn layer] setBorderColor:[UIColor redColor].CGColor];
    [self refreshAnnotations];
}
-(void)setSwitchButtonMapMode
{
    switchEventListViewModeToVisibleOnMapFlag = true;
    [switchEventListViewModeBtn setTitleColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    [switchEventListViewModeBtn setTitle:NSLocalizedString(@"By Map",nil) forState:UIControlStateNormal];
    [[switchEventListViewModeBtn layer] setBorderColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor];
    [self refreshAnnotations];
}

- (void)addFirstDemoEvent {
    ATEventDataStruct *ent = [[ATEventDataStruct alloc] init];
    [self currentLocationClicked:nil];
    ent.lat = currentCenterCoordinate.latitude;
    ent.lng = currentCenterCoordinate.longitude;
    ent.eventDesc = NSLocalizedString(@"To add your own event, long press on a map location, or search an address.\nThis is a demo event/album we created for you. To learn more, please tap on any photos in this demo event.",nil);
    ent.uniqueId = nil;
    ent.address=@"Unknown";
    NSDate* dt = [NSDate date];
    ent.eventDate = dt;
    ent.eventType = 1;

    NSArray* photoNewAddedList = @[PHOTO_META_FILE_NAME, @"demoPhoto1.png",@"demoPhoto2.png",@"demoPhoto3.png",@"demoPhoto4.png",@"demoPhoto5.png"];
    UIImage *demoPhoto1 = [UIImage imageNamed:photoNewAddedList[1]];
    UIImage *demoPhoto2 = [UIImage imageNamed:photoNewAddedList[2]];
    UIImage *demoPhoto3 = [UIImage imageNamed:photoNewAddedList[3]];
    UIImage *demoPhoto4 = [UIImage imageNamed:photoNewAddedList[4]];
    UIImage *demoPhoto5 = [UIImage imageNamed:photoNewAddedList[5]];
    

    NSMutableDictionary* finalPhotoMetaDataMap = [[NSMutableDictionary alloc] init];

    NSMutableDictionary* photoDescMap = [[NSMutableDictionary alloc] init];
    
    NSString* photo1Desc =NSLocalizedString(@"Swipe time wheel, the events in the selected period will be:\n  - listed on the left\n  - colored darker on map\nIf switch map mode to [By Map], swipe map and the events occur on screen will be listed instead.\n(Note: red/green dots above the time wheel indicate the existence of events in that period)",nil);
    NSString* photo2Desc =NSLocalizedString(@"Create your own event or Album:\n  - Long press on a map location, or search address, then tap (!) icon to start event editor as shown in the photo\n  - Enter date, descriptions and optionally add photos, then tap save button\nNote:   To add photos from other sources such Flickr, Google Drive or Dropbox, please install related APP and save photos to your device first",nil);
    NSString* photo3Desc =NSLocalizedString(@"View photos: Tap a photo in event editor to view photo in large size. Things can be done in this view:\n  - Add description to each photo\n  - Order photo display sequence\n    \nPick photos to attach to event sharing\n  - Delete the photo (The real deletion happen when save event change)",nil);
    NSString* photo4Desc =NSLocalizedString(@"There are some useful features in Menu:\n  - Backup/Restore event data – data will be saved in our cloud and you can restore to any devices\n  - Backup/Restore photo files on Dropbox – Never lost photos\n  - Share episodes amount friends who have installed this APP",nil);
    
    [photoDescMap setObject:photo1Desc forKey:photoNewAddedList[1]];
    [photoDescMap setObject:photo2Desc forKey:photoNewAddedList[2]];
    [photoDescMap setObject:photo3Desc forKey:photoNewAddedList[3]];
    [photoDescMap setObject:photo4Desc forKey:photoNewAddedList[4]];
    [photoDescMap setObject:NSLocalizedString(@"Share event and selected photos to social network.",nil) forKey:photoNewAddedList[5]];
    
    [finalPhotoMetaDataMap setObject:photoDescMap forKey:PHOTO_META_DESC_MAP_KEY];
    
    [self copyDemoEventPhoto:demoPhoto1 :photoNewAddedList[1]];
    [self copyDemoEventPhoto:demoPhoto2 :photoNewAddedList[2]];
    [self copyDemoEventPhoto:demoPhoto3 :photoNewAddedList[3]];
    [self copyDemoEventPhoto:demoPhoto4 :photoNewAddedList[4]];
    [self copyDemoEventPhoto:demoPhoto5 :photoNewAddedList[5]];
    
    [self updateEvent:ent newAddedList:photoNewAddedList deletedList:nil photoMetaData:finalPhotoMetaDataMap];

}

- (void)copyDemoEventPhoto:(UIImage*)newPhoto :(NSString*)photoName
{
    if (newPhoto == nil)
        return;

    int imageWidth = RESIZE_WIDTH;
    int imageHeight = RESIZE_HEIGHT;
    
    if (newPhoto.size.height > newPhoto.size.width)
    {
        imageWidth = RESIZE_HEIGHT;
        imageHeight = RESIZE_WIDTH;
    }
    UIImage *newImage = newPhoto;
    NSData* imageData = nil;
    if (newPhoto.size.height > imageHeight || newPhoto.size.width > imageWidth)
    {
        newImage = [ATHelper imageResizeWithImage:newPhoto scaledToSize:CGSizeMake(imageWidth, imageHeight)];
    }
    //NSLog(@"widh=%f, height=%f",newPhoto.size.width, newPhoto.size.height);
    imageData = UIImageJPEGRepresentation(newImage, JPEG_QUALITY); //quality should be configurable?
    NSString* tmpFileNameForNewPhoto = [NSString stringWithFormat:@"%@%@", NEW_NOT_SAVED_FILE_PREFIX,photoName];
    NSString *fullPathToNewTmpPhotoFile = [[ATHelper getNewUnsavedEventPhotoPath] stringByAppendingPathComponent:tmpFileNameForNewPhoto];
    NSError *error;
    [imageData writeToFile:fullPathToNewTmpPhotoFile options:nil error:&error];
 
}

- (void)poiGroupChooseViewController: (ATPOIChooseViewController *)controller
                  didSelectPoiGroup:(NSArray *)poiList{
    NSMutableArray * annotationsToRemove = [ self.mapView.annotations mutableCopy ] ;
    //remove POI events
    for (ATEventAnnotation* ann in self.mapView.annotations)
    {
        if (![ann isKindOfClass:[ATAnnotationPoi class]])
            [annotationsToRemove removeObject:ann];
    }
    [[self mapView] removeAnnotations:annotationsToRemove];
    for (ATEventDataStruct* ent in poiList)
    {
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake((CLLocationDegrees)ent.lat, (CLLocationDegrees)ent.lng);
        ATAnnotationPoi *eventAnnotation = [[ATAnnotationPoi alloc] initWithLocation:coord];
        eventAnnotation.uniqueId = ent.uniqueId;
        //if (ent.eventDate == nil)
            //NSLog(@"---- nil date in poiGroupChooseViewController");
        eventAnnotation.address = ent.address;
        eventAnnotation.description=ent.eventDesc;
        eventAnnotation.eventDate=ent.eventDate;
        eventAnnotation.eventType = ent.eventType;
        [self.mapView addAnnotation:eventAnnotation];
        if (orangePoiOnMap == nil)
            orangePoiOnMap = [[NSMutableArray alloc] init];
        if (ent.eventType == POI_DISPLAY_TYPE_ORANGE)
            [orangePoiOnMap addObject:eventAnnotation];
    }
    if ([poiList count] > 0)
    {
        ATEventDataStruct* evt = poiList[0];
        CLLocationCoordinate2D coord;
        coord.latitude = evt.lat;
        coord.longitude = evt.lng;
        MKCoordinateSpan span = [self coordinateSpanWithMapView:self.mapView centerCoordinate:coord andZoomLevel:5];
        MKCoordinateRegion region = MKCoordinateRegionMake(coord, span);
        
        // set the region like normal
        [self.mapView setRegion:region animated:YES];
    }
}

-(void)choosePoiClicked:(id)sender
{
    [self performSegueWithIdentifier:@"choose_attractions" sender:nil];
}

-(void) settingsClicked:(id)sender  //IMPORTANT only iPad will come here, iPhone has push segue on storyboard
{
    /*
    NSString* currentVer = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    currentVer = [NSString stringWithFormat:@"Current Version: %@",currentVer ];
    
    NSString* link = @"http://www.chroniclemap.com/";
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:link] cachePolicy:0 timeoutInterval:2];
    NSURLResponse* response=nil;
    NSError* error=nil;
    NSData* data=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString* returnStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if(error == nil && returnStr != nil && [returnStr rangeOfString:@"Current Version:"].length > 0)
    {
        if ([returnStr rangeOfString:currentVer].length == 0)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"There is a new version!",nil)
                                                            message:NSLocalizedString(@"Please update from App Store",nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
    */
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    SWRevealViewController *revealController = [self revealViewController];
    UIViewController* controller = revealController.rightViewController;
    if (appDelegate.rightSideMenuRevealedFlag && ![controller isKindOfClass:[ATEventEditorTableController class]])
    { //if right side is preference already, just toggle it
        [revealController rightRevealToggle:nil];
        return;
    }

    //any other case need to reload preference
    revealController.rightViewRevealWidth = [ATConstants revealViewPreferenceWidth];
    UINavigationController* prefNavController = [appDelegate getPreferenceViewNavController];
    revealController.rightViewController = prefNavController;
    ATPreferenceViewController* prefController = prefNavController.childViewControllers[0];
    [prefController refreshDisplayStatusAndData];
    [[prefController tableView] reloadData];
    
    if (!appDelegate.rightSideMenuRevealedFlag)
    { //if was not shown (but not preference, which is eventEditor

        [revealController rightRevealToggle:nil];
    }

    
   // if (!appDelegate.rightSideMenuRevealedFlag)
    //    [revealController rightRevealToggle:nil];
}

-(void) currentLocationClicked:(id)sender
{
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [self.locationManager startUpdatingLocation];
    
    CLLocation *newLocation = [self.locationManager location];
    currentCenterCoordinate.latitude = newLocation.coordinate.latitude;
    currentCenterCoordinate.longitude = newLocation.coordinate.longitude;
    MKCoordinateSpan span = [self coordinateSpanWithMapView:self.mapView centerCoordinate:currentCenterCoordinate andZoomLevel:14];
    MKCoordinateRegion region = MKCoordinateRegionMake(currentCenterCoordinate, span);
    
    // set the region like normal
    [self.mapView setRegion:region animated:YES];
}

-(void) switchEventListViewMode:(id)sender
{
    int toastXPos = 340;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        toastXPos = 200;
    if (switchEventListViewModeToVisibleOnMapFlag)
    {
        eventListInVisibleMapArea = nil; //IMPORTANT: refreshEventListView will use this is nil or not to decide if in map event list view mode, do not refresh if scroll timewheel
        [self setSwitchButtonTimeMode];
        [self.mapView makeToast:NSLocalizedString(@"Scroll timewheel to list events in the selected period",nil) duration:4.0 position:[NSValue valueWithCGPoint:CGPointMake(toastXPos, 77)]];
        [self refreshEventListView:false];
    }
    else
    {
        [self setSwitchButtonMapMode];
        [self.mapView makeToast:NSLocalizedString(@"Scroll map to list events moving into the screen",nil) duration:4.0 position:[NSValue valueWithCGPoint:CGPointMake(toastXPos, 77)]];
        [self updateEventListViewWithEventsOnMap];
    }
}


#pragma mark - CLLocationManagerDelegate

-(void) tutorialClicked:(id)sender //Only iPad come here. on iPhone will be frome inside settings and use push segue
{
    void (^tutorialLargeBlock)(UIView*, CSToastStyle*) = ^(UIView* parentView, CSToastStyle* style) {
        [self startLargeTutorial];
    };
    void (^tutorialOtherFeaturesBlock)(UIView*, CSToastStyle*) = ^(UIView* parentView, CSToastStyle* style) {
        [ATHelper tutorialToastOtherFeatures:parentView style:style nextToToast:tutorialLargeBlock];
    };
    void (^tutorialCreateEventBlock)(UIView*, CSToastStyle*) = ^(UIView* parentView, CSToastStyle* style) {
        [ATHelper tutorialToastCreateEditEvent:parentView style:style nextToToast:tutorialOtherFeaturesBlock];
    };
    
    [ATHelper startTutorialToasts:self.view style:tutorialStyle nextToToast:tutorialCreateEventBlock];
    
}
-(void) startLargeTutorial
{
    if (tutorialView != nil)
    {
        [self closeTutorialView];
    }
    else
    {
        tutorialView = [[ATTutorialView alloc] initWithFrame:CGRectMake(940,0,0,0)];
        [UIView transitionWithView:self.mapView
                          duration:0.5
                           options:UIViewAnimationTransitionFlipFromRight //any animation
                        animations:^ {
                            [tutorialView setFrame:self.view.frame];
                            tutorialView.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
                            [self.mapView addSubview:tutorialView];
                        }
                        completion:nil];
        
        // Do any additional setup after loading the view, typically from a nib.
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                       initWithTarget:self action:@selector(handleTapOnTutorial:)];
        [tutorialView addGestureRecognizer:tap];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake([ATConstants screenWidth] - 120, 65, 110, 30);
        
        [button.layer setCornerRadius:7.0f];
        //[button.layer:YES];
        [button setTitle:NSLocalizedString(@"Online Help",nil) forState:UIControlStateNormal];
        button.titleLabel.backgroundColor = [UIColor blueColor];
        button.backgroundColor = [UIColor blueColor];
        [button addTarget:self action:@selector(onlineHelpClicked:) forControlEvents:UIControlEventTouchUpInside];
        [tutorialView addSubview: button];
        [[self.timeScrollWindow superview] bringSubviewToFront:self.timeScrollWindow];
        [[self.timeZoomLine superview] bringSubviewToFront:self.timeZoomLine];
    }
}

- (void) closeTutorialView
{
    if (tutorialView != nil)
    {
        [UIView transitionWithView:self.mapView
                          duration:0.5
                           options:UIViewAnimationTransitionCurlDown
                        animations:^ {
                            [tutorialView setFrame:CGRectMake(940,0,0,0)];
                        }
                        completion:^(BOOL finished) {
                            [tutorialView removeFromSuperview];
                            tutorialView = nil;
                        }];
    }
}

-(void) onlineHelpClicked:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://www.chroniclemap.com/onlinehelp"];
    
    if (![[UIApplication sharedApplication] openURL:url])
        
        NSLog(@"%@%@",@"Failed to open url:",[url description]);
}
-(void) saveEpisodeClicked:(id)sender
{
    if (episodeNameforUpdating == nil)
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter Name for the new episode",nil)
                                                        message:@"  "
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                              otherButtonTitles:NSLocalizedString(@"OK",nil), nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        alert.tag = ALERT_FOR_SAVE;
        [alert show];
    }
    else
    {
        [self saveEpisodeWithName:episodeNameforUpdating renameIfDuplicate:FALSE];
    }
}
-(void) cancelEpisodeClicked:(id)sender
{
    if (eventEpisodeList != nil)
        [eventEpisodeList removeAllObjects];
    [self refreshAnnotations];
    [self closeEpisodeView];
}
-(void) allEpisodeClicked:(id)sender
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (eventEpisodeList == nil)
        eventEpisodeList = [[NSMutableArray alloc] initWithCapacity:[appDelegate.eventListSorted count]];
    else
        [eventEpisodeList removeAllObjects];
    for (ATEventDataStruct* evt in appDelegate.eventListSorted)
    {
        [eventEpisodeList addObject:evt.uniqueId];
    }
    NSUInteger cnt = [appDelegate.eventListSorted count];
    if (episodeNameforUpdating == nil)
        lblEpisode1.text = [NSString stringWithFormat:NSLocalizedString(@"%d event(s) are picked for new episode",nil), cnt];
    else
        lblEpisode1.text = [NSString stringWithFormat:NSLocalizedString(@"%d event(s) are in episode [%@]",nil), cnt, episodeNameforUpdating];
    [self refreshAnnotations];
    ATEventDataStruct* evt = appDelegate.eventListSorted[0];
    CLLocationCoordinate2D centerCoordinate;
    centerCoordinate.latitude = evt.lat;
    centerCoordinate.longitude = evt.lng;
    MKCoordinateSpan span = [self coordinateSpanWithMapView:self.mapView centerCoordinate:centerCoordinate andZoomLevel:2];
    MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
    
    // set the region like normal
    [self.mapView setRegion:region animated:YES];
}
-(void) lessEpisodeClicked:(id)sender
{
    NSString* lessMoreTxt = btnLess.titleLabel.text;
    CGRect frame = episodeView.frame;
    BOOL flag = false;
    if ([NSLocalizedString(@"Less",nil) isEqualToString:lessMoreTxt])
    {
        frame.size.height = EPISODE_VIEW_HIGHT_SMALL;
        btnLess.titleLabel.text = NSLocalizedString(@"More",nil);
        flag = false;
    }
    else
    {
        frame.size.height = EPISODE_VIEW_HIGHT_LARGE;
        btnLess.titleLabel.text = NSLocalizedString(@"More",nil);
        flag = true;
    }
    [episodeView setFrame:frame];
    [self partialInitEpisodeView:flag];
}

-(void) saveEpisodeWithName: (NSString*)episodeName renameIfDuplicate:(BOOL)renameFlag
{
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* episodeDictionary = [[userDefault objectForKey:[ATConstants EpisodeDictionaryKeyName]] mutableCopy];
    if (episodeDictionary == nil)
        episodeDictionary = [[NSMutableDictionary alloc] init];
    if (renameFlag)
    {
        NSArray* nameList = [episodeDictionary allKeys];
        if ([nameList containsObject:episodeName])
            episodeName = [NSString stringWithFormat:NSLocalizedString(@"%@ (Copy)",nil),episodeName];//not need check if this dupicated again.
    }
    [episodeDictionary setObject:eventEpisodeList forKey:episodeName];
    [userDefault setObject:episodeDictionary forKey:[ATConstants EpisodeDictionaryKeyName]];
    
    if (eventEpisodeList != nil)
        [eventEpisodeList removeAllObjects];
    [self refreshAnnotations];
    [self closeEpisodeView];
    
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == ALERT_FOR_NEW_APP)
    {
        if (buttonIndex == 0) //OK
        {
            return;
        }
        if (buttonIndex == 1) //Flickrface
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/flickrface-flickr-on-timeline/id962157378?ls=1&mt=8"]];
        }
        if (buttonIndex == 2) //Picasaface
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/picasaface-chronicle-your/id973202980?ls=1&mt=8"]];
        }
        if (buttonIndex == 3) //Facebook
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Coming Soon!",nil)
                                                            message:NSLocalizedString(@"",nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                  otherButtonTitles:nil];
            [alert show];
            
        }
        if (buttonIndex == 4) //No reminder
        {
            NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
            [userDefault setObject:@"dummy" forKey:@"ALERT_FOR_SYNC_PROMPT_DISABLE"];
        }
        return;
    }
    if (alertView.tag == ALERT_FOR_DIRECTION_MODE)
    {
        if (buttonIndex == 0)
            return;
        else if (buttonIndex == 1)
            [self drawDirectionWithMode:MKDirectionsTransportTypeAutomobile];
        else
            [self drawDirectionWithMode:MKDirectionsTransportTypeWalking];;
    }
    if (buttonIndex == 1 && alertView.tag == ALERT_FOR_SAVE) {
        NSString *episodeName = [alertView textFieldAtIndex:0].text;
        episodeName =[episodeName stringByTrimmingCharactersInSet:
                      [NSCharacterSet whitespaceCharacterSet]];
        if (![episodeName isEqual:@""] //remember episode Name is saved in saver as xxx|email|date
                                        // and may passed to here with prefix 1* if not readed yet
                                        // so should not conttains * | etc
            && [episodeName rangeOfString:@"*"].location == NSNotFound
            && [episodeName rangeOfString:@"@"].location == NSNotFound
            && [episodeName rangeOfString:@"&"].location == NSNotFound
            && [episodeName rangeOfString:@"|"].location == NSNotFound )
            [self saveEpisodeWithName:episodeName renameIfDuplicate:TRUE];
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Episode name is empty or contains some special char",nil)
                                                            message:NSLocalizedString(@"Episode name should not be empty, and should not contains '@', '*','&' or '|'. Tap Create Episode again to enter valid name!",nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
    if (buttonIndex == 0 && alertView.tag == ALERT_FOR_POPOVER_ERROR)
    {
        NSLog(@"----- refreshAnn after popover error");
        [self refreshAnnotations];
    }
}
- (void)handleTapOnTutorial:(UIGestureRecognizer *)gestureRecognizer
{
    [self closeTutorialView];
}
//// called it after switch database
- (void) prepareMapView
{
    //remove annotation is for switch db scenario
    NSArray * annotationsToRemove =  self.mapView.annotations;
    [ self.mapView removeAnnotations:annotationsToRemove ] ;
    
    
    //NSLog(@"=============== Map View loaded");
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.searchBar.delegate = self;
    self.mapView.delegate = self; //##### HONG #####: without this, vewForAnnotation() will not be called, google it
    
    //get data from core data and added annotation to mapview
    // currently start from the first one, later change to start with latest one
    NSArray * eventList = appDelegate.eventListSorted;
    int bookmarkedTimeZoomLevel = -1;
    if ([eventList count] > 0)
    {
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        NSString* bookmarkIdxStr = [userDefault valueForKey:@"BookmarkEventIdx"];
        unsigned long eventListSize = [eventList count];
        ATEventDataStruct* entStruct = eventList[eventListSize -1]; //if no bookmark, always use earlist
        if (bookmarkIdxStr != nil)
        {
            long bookmarkIdx = [bookmarkIdxStr intValue];
            if (bookmarkIdx >= eventListSize)
                bookmarkIdx = eventListSize - 1;
            if (bookmarkIdx < 0)
                bookmarkIdx = 0;
            entStruct = eventList[bookmarkIdx];
        }
        appDelegate.focusedDate = entStruct.eventDate;
        appDelegate.focusedEvent = entStruct;  //appDelegate.focusedEvent is added when implement here
        
        NSString* bookmarkedMapZoomLevelStr = [userDefault valueForKey:@"BookmarkMapZoomLevel"];
        int bookmarkedMapZoomLevel = 4;
        if (bookmarkedMapZoomLevelStr != nil)
        {
            bookmarkedMapZoomLevel = [bookmarkedMapZoomLevelStr intValue];
        }
        
        NSString* bookmarkedTimeZoomLevelStr = [userDefault valueForKey:@"BookmarkTimeZoomLevel"];

        if (bookmarkedTimeZoomLevelStr != nil)
        {
            bookmarkedTimeZoomLevel = [bookmarkedTimeZoomLevelStr intValue];
        }
        
        [self setNewFocusedDateAndUpdateMapWithNewCenter : entStruct :bookmarkedMapZoomLevel]; //do not change map zoom level
        [self showTimeLinkOverlay];
    }
    
    //add annotation. ### this is the loop where we can adding NSLog to print individual items
    for (ATEventDataStruct* ent in eventList) {
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake((CLLocationDegrees)ent.lat, (CLLocationDegrees)ent.lng);
        ATAnnotationSelected *eventAnnotation = [[ATAnnotationSelected alloc] initWithLocation:coord];
        eventAnnotation.uniqueId = ent.uniqueId;
        if (ent.eventDate == nil)
            NSLog(@"---- nil date in prepareMapView");
        eventAnnotation.address = ent.address;
        eventAnnotation.description=ent.eventDesc;
        eventAnnotation.eventDate=ent.eventDate;
        eventAnnotation.eventType = ent.eventType;
        [self.mapView addAnnotation:eventAnnotation];
    }
    
    appDelegate.mapViewController = self; //my way of share object, used in ATHelper
    [self setTimeScrollConfiguration:bookmarkedTimeZoomLevel]; //I misplaced before above loop and get strange error
    [self displayTimelineControls]; //put it here so change db source will call it, but have to put in viewDidAppear as well somehow
}


//should be called when app start, add/delete ends events, zooming time
//Need change zoom level if need, focused date no change
- (void) setTimeScrollConfiguration:(int)bookmarkedPeriodInDays
{
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSArray * eventList = appDelegate.eventListSorted;
    unsigned long eventCount = [eventList count];
    //IMPORTANT  startDate's date part should always start as year's start day 01/01,so event count in each bucket will be accurate
    if (eventCount == 0) //startDate be this year's start date, end day is today
    {
        NSDate* today = [[NSDate alloc] init];
        self.startDate = [ATHelper getYearStartDate:today];
        dayComponent.day=15;
        self.endDate = [theCalendar dateByAddingComponents:dayComponent toDate:today options:0];
        appDelegate.focusedDate = today;
        appDelegate.selectedPeriodInDays = 30;
    }
    else if (eventCount == 1) //start date is that year's start day, end day is that day
    {
        ATEventDataStruct* event = eventList[0];
        NSDate* curentDate = event.eventDate;
        self.startDate = [ATHelper getYearStartDate:curentDate];
        dayComponent.day=15;
        self.endDate = [theCalendar dateByAddingComponents:dayComponent toDate:curentDate options:0];
        appDelegate.focusedDate = curentDate;
        appDelegate.selectedPeriodInDays = 30;
    }
    else
    {
        
        ATEventDataStruct* eventStart = eventList[eventCount -1];
        ATEventDataStruct* eventEnd = eventList[0];
        //add 5 year
        dayComponent.year = 0;
        dayComponent.month = -5;
        
        NSDate* newStartDt = [theCalendar dateByAddingComponents:dayComponent toDate:eventStart.eventDate options:0];

        self.startDate = [ATHelper getYearStartDate: newStartDt];
        self.endDate = eventEnd.eventDate;
        
        // following is to set intial time period based on event distribution after app start or updated edge events, but has exception, need more study (Studied and may found the bug need test)
        NSDateComponents *components = [theCalendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                                      fromDate:self.startDate
                                                        toDate:self.endDate
                                                       options:0];
        if (appDelegate.selectedPeriodInDays == 0) //for add/delete ending events, do not change time zoom level, following is for when app start
        {
            if (components.year > 1000)
                appDelegate.selectedPeriodInDays = 36500;
            else if (components.year > 100)
                appDelegate.selectedPeriodInDays = 3650;
            else if (components.year >= 2)
                appDelegate.selectedPeriodInDays = 365;
            else
                appDelegate.selectedPeriodInDays = 30;
        }
        if (bookmarkedPeriodInDays > 0)
            appDelegate.selectedPeriodInDays = bookmarkedPeriodInDays;
        
    }
    if (self.timeZoomLine != nil)
        [self displayTimelineControls];//which one is better: [self.timeZoomLine changeScaleLabelsDateFormat:self.startDate :self.endDate ];
    //NSLog(@"   ############## setConfigu startDate=%@    endDate=%@   startDateFormated=%@", self.startDate, self.endDate, [appDelegate.dateFormater stringFromDate:self.startDate]);
}

- (void) cleanAnnotationToShowImageSet
{
    if (annotationToShowImageSet != nil)
    {
        for (id key in annotationToShowImageSet) {
            UILabel* tmpLbl = [annotationToShowImageSet objectForKey:key];
            [tmpLbl removeFromSuperview];
        }
        [annotationToShowImageSet removeAllObjects];
        [selectedAnnotationNearestLocationList removeAllObjects];
    }
    [tmpLblUniqueIdMap removeAllObjects];
    tmpLblUniqueMapIdx = 1;
}
- (void)setMapCenter:(ATEventDataStruct*)ent :(int)zoomLevel
{
    // clamp large numbers to 28
    CLLocationCoordinate2D centerCoordinate= [self.mapView centerCoordinate];
    centerCoordinate.latitude=ent.lat;
    centerCoordinate.longitude=ent.lng;
    zoomLevel = MIN(zoomLevel, 28);
    
    if ([ATHelper isPOIEvent:ent])
    {
        CLLocationCoordinate2D coord;
        coord.latitude = ent.lat;
        coord.longitude = ent.lng;
        [self.mapView setCenterCoordinate:coord animated:YES];
        return; //if clicke on POI in event list view, just change center, no zoomin
    }
    if (!switchEventListViewModeToVisibleOnMapFlag) //time mode, fly the map
    {
        CLLocationCoordinate2D coord;
        coord.latitude = ent.lat;
        coord.longitude = ent.lng;
        [self goToCoordinate:coord];
    }
    else
    {
        // use the zoom level to compute the region
        if ([ent.uniqueId isEqualToString:prevSelectedEventId]) //if select same event, them zoom in one step for better user experience
            zoomLevel++;
        MKCoordinateSpan span = [self coordinateSpanWithMapView:self.mapView centerCoordinate:centerCoordinate andZoomLevel:zoomLevel];
        MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
        
        // set the region like normal
        [self.mapView setRegion:region animated:YES];
        
        prevSelectedEventId = ent.uniqueId;
    }
}

//orientation change will call following, need to removeFromSuperview when call addSubview
- (void)displayTimelineControls
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDate* existingFocusedDate = appDelegate.focusedDate;
    
    
    
    int timeWindowWidth = [ATConstants timeScrollWindowWidth];
    int timeWindowX = [ATConstants timeScrollWindowX];
    
    int timeWindowY = self.view.bounds.size.height - [ATConstants timeScrollWindowHeight];
    
    focusedLabelFrame = CGRectMake(timeWindowX - 43 + timeWindowWidth/2, timeWindowY, 50, 30);
    
    timeScrollWindowFrame = CGRectMake(timeWindowX,timeWindowY, timeWindowWidth,[ATConstants timeScrollWindowHeight]);
    
    
    //Add scrollable time window
    [self addTimeScrollWindow];
    
    
    

    //add focused Label. it is invisible most time, only used for animation effect when click left callout on annotation
    if (appDelegate.focusedDate == nil)
        appDelegate.focusedDate = [[NSDate alloc] init];
    if (self.focusedEventLabel != nil)
        [self.focusedEventLabel removeFromSuperview];
    self.focusedEventLabel = [[UILabel alloc] initWithFrame:focusedLabelFrame];
    self.focusedEventLabel.text = [NSString stringWithFormat:@" %@",[appDelegate.dateFormater stringFromDate: appDelegate.focusedDate]];
    //NSLog(@"%@",self.focusedEventLabel.text);
    [self.focusedEventLabel setFont:[UIFont fontWithName:@"Arial" size:13]];
    self.focusedEventLabel.textColor = [UIColor blackColor];
    self.focusedEventLabel.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:1.0f];
    self.focusedEventLabel.layer.cornerRadius=5;
    [self.focusedEventLabel setHidden:true];
    [self.view addSubview:self.focusedEventLabel];
    
    //Following is to focused on today when start the apps
    if (existingFocusedDate != nil)
        appDelegate.focusedDate = existingFocusedDate;
    else
        appDelegate.focusedDate = [[NSDate alloc] init];
    [self.timeScrollWindow setNewFocusedDateFromAnnotation:appDelegate.focusedDate needAdjusted:FALSE];
    
    int tmpXcode5ScreenWidth = [ATConstants screenWidth];
    
    //NOTE the trick to set background image for a bar buttonitem
    if (locationbtn == nil)
        locationbtn = [UIButton buttonWithType:UIButtonTypeCustom];
    else
        [locationbtn removeFromSuperview];
    //locationbtn.frame = CGRectMake([ATConstants screenWidth] - 50, 90, 30, 30);
    locationbtn.frame = CGRectMake(tmpXcode5ScreenWidth - 50, 90, 30, 30);
    [locationbtn setImage:[UIImage imageNamed:@"currentLocation.png"] forState:UIControlStateNormal];
    [locationbtn addTarget:self action:@selector(currentLocationClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.mapView addSubview:locationbtn];
    

    
    [self displayZoomLine];
}

//called by above displayTimeLineControls, as well as when zoom time
- (void) displayZoomLine
{
    CGRect timeZoomLineFrame;
    int timeWindowWidth = [ATConstants timeScrollWindowWidth];
    int timeWindowX = [ATConstants timeScrollWindowX];
    timeZoomLineFrame = CGRectMake(timeWindowX - 15,self.view.bounds.size.height - [ATConstants timeScrollWindowHeight], timeWindowWidth + 30,30);
    if (self.timeZoomLine != nil)
    [self.timeZoomLine removeFromSuperview]; //incase orientation change
    self.timeZoomLine = [[ATTimeZoomLine alloc] initWithFrame:timeZoomLineFrame];
    self.timeZoomLine.userInteractionEnabled = false;
    self.timeZoomLine.backgroundColor = [UIColor clearColor];
    self.timeZoomLine.mapViewController = self;
    [self.view addSubview:self.timeZoomLine];
    [self.timeZoomLine changeScaleLabelsDateFormat:self.startDate :self.endDate ];
    [self changeTimeScaleState];
}

- (void) addTimeScrollWindow
{
    if (self.timeScrollWindow != nil)
        [self.timeScrollWindow removeFromSuperview];
    self.timeScrollWindow = [[ATTimeScrollWindowNew alloc] initWithFrame:timeScrollWindowFrame];
    self.timeScrollWindow.parent = self;
    [self.view addSubview:self.timeScrollWindow];
    if (self.timeZoomLine != nil)
    {
        self.timeZoomLine.hidden = false;
    }
}

- (void) changeTimeScaleState
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self setSelectedPeriodLabel];
    NSDate* startDate = self.startDate;
    NSDate* endDate = self.endDate;
    if (appDelegate.selectedPeriodInDays <=30)
    {
        startDate = [ATHelper getYearStartDate:appDelegate.focusedDate];
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        [dateComponents setYear:1];
        endDate = [gregorian dateByAddingComponents:dateComponents toDate:startDate  options:0];
        
    }
    [self.timeZoomLine changeTimeScaleState:startDate :endDate :appDelegate.selectedPeriodInDays :appDelegate.focusedDate];
}

- (void) setSelectedPeriodLabel
{
    [self.timeZoomLine changeScaleText];
}
/*
- (NSString*) getSelectedPeriodLabel
{
    
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString* retStr=@"";
    if (appDelegate.selectedPeriodInDays == 7)
    {
        retStr = @"Span: 1week";
    }
    else if (appDelegate.selectedPeriodInDays == 30)
    {
        retStr = @"Span: 1mon";
    }
    else if (appDelegate.selectedPeriodInDays == 365)
    {
        retStr = @"Span: 1yr";
    }
    else if (appDelegate.selectedPeriodInDays == 3650)
    {
        retStr = @"Span: 10yrs";
    }
    else if (appDelegate.selectedPeriodInDays == 36500)
    {
        retStr = @"Span: 100yrs";
    }
    else if (appDelegate.selectedPeriodInDays == 365000)
    {
        retStr = @"Span:1000yrs";
    }
    return retStr;
}
*/
- (void) toggleMapViewShowHideAction
{
    if (self.mapViewShowWhatFlag == MAPVIEW_SHOW_ALL)
    {
        self.mapViewShowWhatFlag = MAPVIEW_HIDE_ALL;
        [self animatedHidePart1];
        //TODO may need option to see if hide ann icon or not
        [self hideDescriptionLabelViews];
        [self.navigationController setNavigationBarHidden:true animated:TRUE];
    }
    else if (self.mapViewShowWhatFlag == MAPVIEW_HIDE_ALL)
    {
        self.mapViewShowWhatFlag = MAPVIEW_SHOW_ALL;
        [self animatedShowPart1];
        //TODO may need option to see if hide ann icon or not
        [self showDescriptionLabelViews:self.mapView];
        [self.navigationController setNavigationBarHidden:false animated:TRUE];
    }
    /**** I decide to not use three-steps
    if ([annotationToShowImageSet count] == 0) //if no selected nodes, use 2 step show/hide to have better user experience
    {
        if (self.mapViewShowWhatFlag == MAPVIEW_SHOW_ALL || self.mapViewShowWhatFlag == MAPVIEW_SHOW_PHOTO_LABEL_ONLY)
        {
            self.mapViewShowWhatFlag = MAPVIEW_HIDE_ALL;
            [self animatedHidePart1];
            [self hideDescriptionLabelViews];
            [self.navigationController setNavigationBarHidden:true animated:TRUE];
        }
        else if (self.mapViewShowWhatFlag == MAPVIEW_HIDE_ALL || self.mapViewShowWhatFlag == MAPVIEW_SHOW_PHOTO_LABEL_ONLY)
        {
            self.mapViewShowWhatFlag = MAPVIEW_SHOW_ALL;
            [self animatedShowPart1];
            [self showDescriptionLabelViews:self.mapView];
            [self.navigationController setNavigationBarHidden:false animated:TRUE];
        }
    }
    else //if has selected nodes, use 3-step show/hide
    {
        if (self.mapViewShowWhatFlag == MAPVIEW_SHOW_ALL)
        {
            self.mapViewShowWhatFlag = MAPVIEW_HIDE_ALL;
            [self animatedHidePart1];
            [self hideDescriptionLabelViews];
            [self.navigationController setNavigationBarHidden:true animated:TRUE];
        }
        else if (self.mapViewShowWhatFlag == MAPVIEW_HIDE_ALL)
        {
            self.mapViewShowWhatFlag = MAPVIEW_SHOW_PHOTO_LABEL_ONLY;
            [self animatedHidePart1];
            [self showDescriptionLabelViews:self.mapView];
            [self.navigationController setNavigationBarHidden:TRUE animated:TRUE];
        }
        else if (self.mapViewShowWhatFlag == MAPVIEW_SHOW_PHOTO_LABEL_ONLY)
        {
            self.mapViewShowWhatFlag = MAPVIEW_SHOW_ALL;
            [self animatedShowPart1];
            [self showDescriptionLabelViews:self.mapView];
            [self.navigationController setNavigationBarHidden:false animated:TRUE];
        }
    }
    */
}

- (void) hideTimeScrollAndNavigationBar:(BOOL)hideFlag
{
    if (hideFlag)
    {
        self.mapViewShowWhatFlag = MAPVIEW_HIDE_ALL;
        [self animatedHideTimeScrollAndNavigationBarPart1];
        [self.navigationController setNavigationBarHidden:true animated:TRUE];
    }
    else
    {
        self.mapViewShowWhatFlag = MAPVIEW_SHOW_ALL;
        [self animatedShowTimeScrollAndNavigationBarPart1];
        [self.navigationController setNavigationBarHidden:false animated:TRUE];
    }
}

- (void) animatedHideTimeScrollAndNavigationBarPart1
{
    int timeWindowY = self.view.bounds.size.height - [ATConstants timeScrollWindowHeight];
    int timeLineY = timeWindowY;
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationCurveEaseOut
                     animations:^(void) {
                         self.timeScrollWindow.alpha = 0;
                         self.timeZoomLine.alpha = 0;
                         CGRect frame = self.timeScrollWindow.frame;
                         frame.origin.y = timeWindowY + 30;
                         [self.timeScrollWindow setFrame:frame];
                         frame = self.timeZoomLine.frame;
                         frame.origin.y = timeLineY + 30;
                         [self.timeZoomLine setFrame:frame];
                     }
                     completion:NULL];
}
- (void) animatedShowTimeScrollAndNavigationBarPart1
{
    int timeWindowY = self.view.bounds.size.height - [ATConstants timeScrollWindowHeight];
    int timeLineY = timeWindowY;
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationCurveEaseOut
                     animations:^(void) {
                         self.timeScrollWindow.alpha = 1;
                         self.timeZoomLine.alpha = 1;
                         switchEventListViewModeBtn.alpha = 1;
                         eventListView.alpha = 1;
                         
                         CGRect frame = self.timeScrollWindow.frame;
                         frame.origin.y = timeWindowY;
                         [self.timeScrollWindow setFrame:frame];
                         frame = self.timeZoomLine.frame;
                         frame.origin.y = timeLineY;
                         [self.timeZoomLine setFrame:frame];
                     }
                     completion:NULL];
}


- (void) animatedHidePart1
{
    int timeWindowY = self.view.bounds.size.height - [ATConstants timeScrollWindowHeight];
    int timeLineY = timeWindowY;
    int hideX = -190;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        hideX = -110;
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationCurveEaseOut
                     animations:^(void) {
                         self.timeScrollWindow.alpha = 0;
                         self.timeZoomLine.alpha = 0;
                         eventListView.alpha = 0.9; //ad-hoc notice: cannot be 1 because tmpLbl show/hide depends on this value is 1 or less
                         switchEventListViewModeBtn.alpha = 0;
                         CGRect frame = self.timeScrollWindow.frame;
                         frame.origin.y = timeWindowY + 30;
                         [self.timeScrollWindow setFrame:frame];
                         frame = self.timeZoomLine.frame;
                         frame.origin.y = timeLineY + 30;
                         [self.timeZoomLine setFrame:frame];
                         
                         frame = eventListView.frame;
                         frame.origin.x = hideX;
                         [eventListView setFrame:frame];
                         frame = switchEventListViewModeBtn.frame;
                         frame.origin.x = hideX;
                         [switchEventListViewModeBtn setFrame:frame];
                     }
                     completion:NULL];
}
- (void) animatedShowPart1
{
    int timeWindowY = self.view.bounds.size.height - [ATConstants timeScrollWindowHeight];
    int timeLineY = timeWindowY;
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationCurveEaseOut
                     animations:^(void) {
                         self.timeScrollWindow.alpha = 1;
                         self.timeZoomLine.alpha = 1;
                         switchEventListViewModeBtn.alpha = 1;
                         eventListView.alpha = 1;
                         
                         CGRect frame = self.timeScrollWindow.frame;
                         frame.origin.y = timeWindowY;
                         [self.timeScrollWindow setFrame:frame];
                         frame = self.timeZoomLine.frame;
                         frame.origin.y = timeLineY;
                         [self.timeZoomLine setFrame:frame];
                         
                         frame = eventListView.frame;
                         frame.origin.x = 0;
                         [eventListView setFrame:frame];
                         frame = switchEventListViewModeBtn.frame;
                         frame.origin.x = 10;
                         [switchEventListViewModeBtn setFrame:frame];
                     }
                     completion:NULL];
}

- (void)handleTapGesture:(UIGestureRecognizer *)gestureRecognizer
{
    NSTimeInterval interval = [[[NSDate alloc] init] timeIntervalSinceDate:regionChangeTimeStart];
    // NSLog(@"my tap ------regionElapsed=%f", interval);
    if (interval < 0.5)  //When scroll map, tap to stop scrolling should not flip the display of timeScrollWindow and description views
        return;
    if ([gestureRecognizer numberOfTouches] == 1)
    {
        if (prevSelectedPoiAnnView != nil)
        {
            UIView* poiView = [prevSelectedPoiAnnView viewWithTag:9991];
            if (poiView != nil)
               [poiView removeFromSuperview];
        }
        [self toggleMapViewShowHideAction];
    }
}

- (void)handleLongPressGesture:(UIGestureRecognizer *)gestureRecognizer
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)   // UIGestureRecognizerStateEnded)
        return;
    
    //NSLog(@"--- to be processed State is %d", gestureRecognizer.state);
    CGPoint touchPoint = [gestureRecognizer locationInView:_mapView];
    
    //Following is to do not create annotation when tuch upper part of the map because of the timeline related controls.
    if ((UIDeviceOrientationIsLandscape(orientation) && touchPoint.y <= 120 && touchPoint.x > 300 && touchPoint.x < 650)
        ||
        (UIDeviceOrientationIsPortrait(orientation) && touchPoint.y <=105))
        return;
    
    CLLocationCoordinate2D touchMapCoordinate =
    [_mapView convertPoint:touchPoint toCoordinateFromView:_mapView];
    double lat = touchMapCoordinate.latitude;
    double lng = touchMapCoordinate.longitude;
    
    self.location = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
    //NSLog(@" inside gesture lat is %f", self.location.coordinate.latitude);
    
    //Have to initialize locally here, this is the requirement of CLGeocode
    //######## I have spend many days to figure it out on Jan 11, 2013 weekend
    self.geoCoder = [[CLGeocoder alloc] init];
    
    
    //reverseGeocodeLocation will take long time in very special case, such as when FreedomPop up/down, so use following stupid way to check network first, need more test on train
    
    NSString* link = @"http://www.google.com";
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:link] cachePolicy:0 timeoutInterval:2];
    NSURLResponse* response=nil;
    NSError* error=nil;
    NSData* data=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    //NSString* URLString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if(data == nil || error != nil)
        [self addPinToMap:@"Unknow" :touchMapCoordinate];
    else
        [self.geoCoder reverseGeocodeLocation: self.location completionHandler:
         ^(NSArray *placemarks, NSError *error) {
             //NSLog(@"reverseGeocoder:completionHandler: called lat=%f",self.location.coordinate.latitude);
             if (error) {
                 NSLog(@"Geocoder failed with error: %@", error);
             }
             NSString *locatedAt = @"Unknown";
             if (placemarks && placemarks.count > 0)
             {
                 //Get nearby address
                 CLPlacemark *placemark = [placemarks objectAtIndex:0];
                 //String to hold address
                 locatedAt = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
             }
             [self addPinToMap:locatedAt :touchMapCoordinate];
             //  /*** following is for testing add to db for each longpress xxxxxxxx TODO
             // [self.dataController addEventEntityAddress:locatedAt description:@"desc by touch" date:[NSDate date] lat:touchMapCoordinate.latitude lng:touchMapCoordinate.longitude];
             //    */
         }];
    
}

- (void) addPinToMap:(NSString*)locatedAt :(CLLocationCoordinate2D) touchMapCoordinate
{
    ATDefaultAnnotation *pa = [[ATDefaultAnnotation alloc] initWithLocation:touchMapCoordinate];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    pa.eventDate = appDelegate.focusedDate;
    pa.description=NEWEVENT_DESC_PLACEHOLD;
    pa.address = locatedAt;
    [_mapView addAnnotation:pa];
    if (newAddedPin != nil)
    {
        [_mapView removeAnnotation:newAddedPin];
        newAddedPin = pa;
    }
    else
        newAddedPin = pa;
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    ATDefaultAnnotation* ann = (ATDefaultAnnotation*)annotation;
    
    if ([annotation isKindOfClass:[ATAnnotationPoi class]]){
        //if ([self zoomLevel] <= ZOOM_LEVEL_TO_HIDE_EVENTLIST_VIEW)
         //   return nil; //this will return a standard pin, which is not what I want
        NSString* poiAnnImageFile = @"star-purple.png";
        if (ann.eventType == POI_DISPLAY_TYPE_RED_DOT)
            poiAnnImageFile = @"small-purple-ball-icon.png";
        else if (ann.eventType == POI_DISPLAY_TYPE_ORANGE)
        {
            //if ([self zoomLevel] <= ZOOM_LEVEL_POI_7)
               //poiAnnImageFile = @"small-orange-ball-brighter-icon.png";
            //else
                poiAnnImageFile = @"small-orange-ball-icon.png";
        }
        
        MKAnnotationView* annView = (MKAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:poiAnnImageFile];

        if (!annView)
        {
            annView = [[MKAnnotationView alloc]
                                               initWithAnnotation:annotation reuseIdentifier:poiAnnImageFile];

            UIImage *markerImage = [UIImage imageNamed:poiAnnImageFile];
            annView.image = markerImage;
            //[annView addSubview:numberLabel];
        }
        
        annView.annotation = annotation;
        if (poiAnnViewDic == nil)
            poiAnnViewDic = [[NSMutableDictionary alloc] init];
        
        [poiAnnViewDic setObject:annView forKey:ann.uniqueId];
        
        return annView;
    }
    
    
    // Following will filter out MKUserLocation annotation
    if ([annotation isKindOfClass:[ATDefaultAnnotation class]]) //ATDefaultAnnotation is when longPress
    {
        selectedAnnotationIdentifier = [self getImageIdentifier:ann.eventDate :nil]; //keep this line here, do not move inside
        // try to dequeue an existing pin view first
        MKPinAnnotationView* pinView = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:[ATConstants DefaultAnnotationIdentifier]];
        if (!pinView)
        {
            // if an existing pin view was not available, create one
            MKPinAnnotationView* customPinView = [[MKPinAnnotationView alloc]
                                                  initWithAnnotation:annotation reuseIdentifier:[ATConstants DefaultAnnotationIdentifier]];
            customPinView.pinColor = MKPinAnnotationColorRed;
            customPinView.animatesDrop = YES;
            customPinView.canShowCallout = YES;
            
            UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            rightButton.accessibilityLabel=@"right";
            customPinView.rightCalloutAccessoryView = rightButton;
            
            UIButton* leftButton = [UIButton buttonWithType:UIButtonTypeInfoLight ];
            [leftButton setTintColor:[UIColor clearColor]];
            [leftButton setBackgroundImage:[UIImage imageNamed:@"car-icon.png"] forState:UIControlStateNormal];
            
            leftButton.accessibilityLabel=@"left";
            customPinView.leftCalloutAccessoryView = leftButton;
            return customPinView;
            
        }
        else
        {
            //NSLog(@"+++++++++ reused default annotation +++++ at address %@", [annotation title]);
            pinView.annotation = annotation;
        }
        return pinView;
    }
    else if ([annotation isKindOfClass:[ATAnnotationSelected class]]) //all that read from db will be ATAnnotationSelected type
    {
        NSString* specialMarkerName = [ATHelper getMarkerNameFromDescText: ann.description];
        
        selectedAnnotationIdentifier = [self getImageIdentifier:ann.eventDate: specialMarkerName]; //keep this line here
        MKAnnotationView* annView;
        if (eventEpisodeList != nil && [eventEpisodeList containsObject:ann.uniqueId])
            annView = [self getImageAnnotationView:@"add-to-episode-marker.png" :annotation];
        else
            annView = [self getImageAnnotationView:selectedAnnotationIdentifier :annotation];
        annView.annotation = annotation;
        NSString *key=[NSString stringWithFormat:@"%f|%f",ann.coordinate.latitude, ann.coordinate.longitude];
        //keey list of red  annotations
        BOOL isSpecialMarkerInFocused = false;
        if (specialMarkerName != nil && ![selectedAnnotationIdentifier isEqualToString:[ATConstants WhiteFlagAnnotationIdentifier:switchEventListViewModeToVisibleOnMapFlag]] )
        {
            //Remember special marker annotation identifier has alpha value delimited by ":" if not selected. Selected do not have :
            if ([selectedAnnotationIdentifier rangeOfString:@":"].location == NSNotFound)
                isSpecialMarkerInFocused = true;
        }
        
        /*
         * Show annotation tmpLbl for annotation which is darkest color in time mode.
         *      In map mode, show tmpLbl if annotation on map is less than 10
         */
        if (!switchEventListViewModeToVisibleOnMapFlag)
        {
            if ([selectedAnnotationIdentifier isEqualToString: [ATConstants SelectedAnnotationIdentifier]] || isSpecialMarkerInFocused)
            {
                [self addTmpLblToMap:annotation];
            }
            else
            {
                UILabel* tmpLbl = [annotationToShowImageSet objectForKey:key];
                if ( tmpLbl != nil)
                {
                    [annotationToShowImageSet removeObjectForKey:key];
                    [tmpLbl removeFromSuperview];
                }
            }
        }
        else //in map mode
        {
            if ([self zoomLevel] >= ZOOM_LEVEL_TO_HIDE_DESC_IN_MAP_MODE)
            {
                [self addTmpLblToMap:annotation];
            }
            else
            {
                UILabel* tmpLbl = [annotationToShowImageSet objectForKey:key];
                if ( tmpLbl != nil)
                {
                    [annotationToShowImageSet removeObjectForKey:key];
                    [tmpLbl removeFromSuperview];
                }            }
        }
        /*
         if ([selectedAnnotationIdentifier isEqualToString:[ATConstants WhiteFlagAnnotationIdentifier]])
         {
         [[annView superview] sendSubviewToBack:annView];
         }
         */
        //annView.hidden = false;
        if (currentSelectedEvent != nil)
        {
            if ([currentSelectedEvent.uniqueId isEqualToString:ann.uniqueId])
            {
                selectedEventAnnInEventListView = annView;
            }
        }
        return annView;
    }
    else if ([annotation isKindOfClass:[ATAnnotationFocused class]]) //Focused annotation is added when tab focused
    {
        MKAnnotationView* annView = [self getImageAnnotationView:@"focusedFlag.png" :annotation];
        annView.annotation = annotation;
        return annView;
    }
    
    return nil;
}

//All View is a UIResponder, all UIresponder objects can implement touchesBegan
-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event{
    currentTapTouchKey = 0;
    currentTapTouchMove = false;
    UITouch *touch = [touches anyObject];
    NSNumber* annViewKey = [NSNumber numberWithLong:touch.view.tag];
    if ([annViewKey intValue] > 0) //tag is set in viewForAnnotation when instance tmpLbl
        currentTapTouchKey = [annViewKey intValue];
}

//Only tap to start event editor, when swipe map and happen to swipe on photo, do not start event editor
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    NSNumber* annViewKey = [NSNumber numberWithLong:touch.view.tag];
    if ([annViewKey intValue] > 0 && [annViewKey intValue] == currentTapTouchKey)
        currentTapTouchMove = true;
}
//touchesEnded does not work, touchesCancelled works
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    NSNumber* annViewKey = [NSNumber numberWithLong:touch.view.tag];
    if ([annViewKey intValue] > 0 && [annViewKey intValue] == currentTapTouchKey && !currentTapTouchMove)
    {
        MKAnnotationView* annView = [tmpLblUniqueIdMap objectForKey:annViewKey];

        selectedEventAnnOnMap = annView;
        selectedEventAnnDataOnMap = [annView annotation];
        [self startEventEditor:annView];
        [self toggleMapViewShowHideAction];
        [self refreshFocusedEvent];
    }
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    //didAddAnnotationViews is called when focused to date or move timewheel caused by addAnnotation:removedAnntationSet
    //views size usually is the number of ann on screen
    //NSLog(@"------ view size is %d ",[views count]);
    for (MKAnnotationView* annView in views)
    {
        ATEventAnnotation* ann = [annView annotation];
        if (![ann isKindOfClass:[ATAnnotationSelected class]])
            continue;
        if (ann.eventDate == nil)
            continue;
        NSString* specialMarkerName = [ATHelper getMarkerNameFromDescText: ann.description];
        NSString* identifer = [self getImageIdentifier:ann.eventDate :specialMarkerName];
        //NSLog(@"  identifier is %@  date=%@",identifer, ann.eventDate);
        if ([identifer isEqualToString: [ATConstants WhiteFlagAnnotationIdentifier:switchEventListViewModeToVisibleOnMapFlag]])
            [[annView superview] sendSubviewToBack:annView];
        if ([identifer isEqualToString: [ATConstants SelectedAnnotationIdentifier]])
        {
            if (selectedAnnotationViewsFromDidAddAnnotation == nil)
            {
                selectedAnnotationViewsFromDidAddAnnotation = [[NSMutableSet alloc] init]; //cleaned in refreshAnnotation
            }
            [selectedAnnotationViewsFromDidAddAnnotation addObject:annView];
            [[annView superview] bringSubviewToFront:annView];
        }
    }
    //Above is try to hide white flag behind selected, works partially, but still have problem when zoom map. not sure what is reason
    
    
    [self showDescriptionLabelViews:self.mapView];
}



- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    if (!firstTimeShowFlag) //always show all menus when first time show the view
    {
        [self hideDescriptionLabelViews];
        [self hideTimeScrollAndNavigationBar:true];
    }
    else
    {
        [self hideTimeScrollAndNavigationBar:false];
        firstTimeShowFlag = false;
    }
}
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{

    
    //TODO could set option to enable/disable hide white flag, because if large nmber of selected note, then move map may be slow
    //     although currently we already have optimized it a lot
    /*
    if (selectedAnnotationViewsFromDidAddAnnotation != nil
        && [self zoomLevel] >= ZOOM_LEVEL_TO_SEND_WHITE_FLAG_BEHIND_IN_REGION_DID_CHANGE)
    {
        //NSLog(@"    in regionDidChange  size=%d",[selectedAnnotationViewsFromDidAddAnnotation count]);
        for (MKAnnotationView* annView in selectedAnnotationViewsFromDidAddAnnotation)
        {
            [[annView superview] bringSubviewToFront:annView];
        }
    }
    */
    
    //******************** get annotations on the screen map and show in event list view
    //Do following if 1) map mode for event viewlist
    //                2) map zoom level is at state level
    //                3) eventlistview is not hidden

    eventListInVisibleMapArea = nil;
    if (switchEventListViewModeToVisibleOnMapFlag)
    {
        [self updateEventListViewWithEventsOnMap];
    }
    else
        [self updateEventListViewWithPoiOnMapOnly];
    //******************
    
    if (animated) //means not caused by user scroll on map
    {
        [self goToNextCamera];
    }
    
    //NSLog(@"retion didChange, zoom level is %i", [self zoomLevel]);
    [self.timeZoomLine setNeedsDisplay];
    regionChangeTimeStart = [[NSDate alloc] init];
    //[self showDescriptionLabelViews:mapView];
    [self.mapView bringSubviewToFront:eventListView]; //so eventListView will always cover map marker photo/txt icon (tmpLbl)
    
    //show annotation info window programmatically, especially for when select on event list view
    //Also show poi view programmatically for select an poi from event list view
    //  Both has two different condition because poi ann list will never refresh so viewForAnnotation will not be called
    if (currentSelectedEvent != nil)
    {
        if (selectedEventAnnInEventListView != nil) //for select event from view list come here
        {
            ATEventAnnotation* ann = selectedEventAnnInEventListView.annotation;
            [self.mapView selectAnnotation:ann animated:YES];
        }
        else if ([ATHelper isPOIEvent:currentSelectedEvent])
        {
            MKAnnotationView* selectedPoiAnnEventInEventListView = [poiAnnViewDic objectForKey:currentSelectedEvent.uniqueId ];
            [self displayPOIView:selectedPoiAnnEventInEventListView];
        }
        ////xxxxx
        /*
        self.timeScrollWindow.hidden=false;
        eventListView.hidden = false;
        switchEventListViewModeBtn.hidden = false;
        self.timeZoomLine.hidden = false;
         */
        //[self showDescriptionLabelViews:self.mapView];
        /////xxxxxx self.navigationController.navigationBarHidden = false;
        
        
        selectedEventAnnInEventListView = nil;
        currentSelectedEvent = nil;
    }
    //bookmark zoom level so app restart will restore state
    if ([self zoomLevel] > ZOOM_LEVEL_POI_7)
    {
        [self.mapView removeAnnotations:orangePoiOnMap];
        [self.mapView addAnnotations:orangePoiOnMap];
    }
    else
        [self.mapView removeAnnotations:orangePoiOnMap];
    
    int currentZoomLevel = [self zoomLevel];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.zoomLevel = currentZoomLevel;
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:[NSString stringWithFormat:@"%d",currentZoomLevel] forKey:@"BookmarkMapZoomLevel"];
    [userDefault synchronize];
    
    if (switchEventListViewModeToVisibleOnMapFlag)
    {
        if ([self zoomLevel] > ZOOM_LEVEL_TO_HIDE_DESC_IN_MAP_MODE && prevZoomLevel <= ZOOM_LEVEL_TO_HIDE_DESC_IN_MAP_MODE)
            [self refreshAnnotations];
    }
    else
    {
        if ([self zoomLevel] > ZOOM_LEVEL_TO_HIDE_DESC && prevZoomLevel <= ZOOM_LEVEL_TO_HIDE_DESC_IN_MAP_MODE)
            [self refreshAnnotations];
    }
    prevZoomLevel = [self zoomLevel];
}
-(void) displayPOIView:(MKAnnotationView*)selectedPoiAnnEventInEventListView
{
    [self startPOIEditor:selectedPoiAnnEventInEventListView];
    prevSelectedPoiAnnView = selectedPoiAnnEventInEventListView;
    /*
    int poiViewWidth = 200;
    int poiViewHeidht = 220;
    UIView* poiView = [[UIView alloc] initWithFrame:CGRectMake(- poiViewWidth / 2,- poiViewHeidht, poiViewWidth, poiViewHeidht)];
    [poiView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"help.png"]]];
    [poiView setTag:9991];
    [selectedPoiAnnEventInEventListView addSubview:poiView];
    if (prevSelectedPoiAnnView != nil && prevSelectedPoiAnnView != selectedPoiAnnEventInEventListView)
    {
        UIView* removeView = [prevSelectedPoiAnnView viewWithTag:9991];
        if (removeView != nil)
            [removeView removeFromSuperview];
    }
    prevSelectedPoiAnnView = selectedPoiAnnEventInEventListView;
     */
}

-(void) addTmpLblToMap:(ATDefaultAnnotation*)annotation
{
    MKAnnotationView* annView;
    annView = [self getImageAnnotationView:selectedAnnotationIdentifier :annotation];
    annView.annotation = annotation;
    NSString *key=[NSString stringWithFormat:@"%f|%f",annotation.coordinate.latitude, annotation.coordinate.longitude];
    UILabel* tmpLbl = [annotationToShowImageSet objectForKey:key];
    if (tmpLbl == nil)
    {
        //CGPoint windowPoint = [annView convertPoint:[annView center] toView:self.mapView];
        CGPoint annotationViewPoint = [self.mapView convertCoordinate:annView.annotation.coordinate
                                                        toPointToView:self.mapView];
        
        //NSLog(@"x=%f  y=%f",annotationViewPoint.x, annotationViewPoint.y);
        tmpLbl = [[UILabel alloc] initWithFrame:CGRectMake(annotationViewPoint.x -20, annotationViewPoint.y+5, THUMB_WIDTH, THUMB_HEIGHT)]; //todo MFTopAlignedLabel
        if (annotation.eventType == EVENT_TYPE_HAS_PHOTO) //somehow it is a big number before save to db, need more study why not 1
        {
            NSString* photoFileName = annotation.uniqueId;

            UIImage* img = [ATHelper readPhotoThumbFromFile:photoFileName];
            if (img == nil)
            {
                NSArray* thumbFileUrlList = [ATHelper getPhotoUrlsFromDescText:annotation.description];
                if (thumbFileUrlList != nil && [thumbFileUrlList count] > 0)
                    img = [ATHelper fetchAndCachePhotoFromWeb:thumbFileUrlList[0] thumbPhotoId:photoFileName];
                
            }
            if (img != nil)
            {
                UIImageView* imgView = [[UIImageView alloc]initWithImage: img];
                [imgView setAlpha:0.85];
                imgView.tag = HAVE_IMAGE_INDICATOR; //later used to get subview
                /*
                 imgView.contentMode = UIViewContentModeScaleAspectFill;
                 imgView.clipsToBounds = YES;
                 imgView.layer.cornerRadius = 8;
                 imgView.layer.borderColor = [UIColor brownColor].CGColor;
                 imgView.layer.borderWidth = 1;
                 */
                
                //[imgView setFrame:CGRectMake(-30, -25, 100, 80)];
                tmpLbl.text = @"                             \r\r\r\r\r\r";
                tmpLbl.backgroundColor = [UIColor clearColor];
                imgView.frame = CGRectMake(imgView.frame.origin.x, imgView.frame.origin.y, tmpLbl.frame.size.width, tmpLbl.frame.size.height);
                //[tmpLbl setAutoresizesSubviews:true];
                [tmpLbl addSubview: imgView];
                tmpLbl.layer.cornerRadius = 8;
                tmpLbl.layer.borderColor = [UIColor brownColor].CGColor;
                tmpLbl.layer.borderWidth = 1;
            }
            else
            {
                //xxxxxx TODO if user switch source from server, photo may not be in local yet, then
                //             should display text only and add download request in download queue
                // ########## This is a important lazy download concept #############
                tmpLbl.backgroundColor = [UIColor colorWithRed:255.0 green:255 blue:0.8 alpha:0.8];
                tmpLbl.text = [NSString stringWithFormat:@" %@", [ATHelper clearMakerAllFromDescText: annotation.description ]];
                tmpLbl.layer.cornerRadius = 8;
                tmpLbl.layer.borderColor = [UIColor redColor].CGColor;
                tmpLbl.layer.borderWidth = 1;
            }
        }
        else
        {
            tmpLbl.backgroundColor = [UIColor colorWithRed:255.0 green:255 blue:0.8 alpha:0.8];
            tmpLbl.text = [NSString stringWithFormat:@" %@", [ATHelper clearMakerAllFromDescText: annotation.description ]];
            tmpLbl.layer.cornerRadius = 8;
            //If the event has photo before but the photos do not exist anymore, then show text with red board
            //If this happen, the photo may in Dropbox. if not  in dropbox, then it lost forever.
            //To change color, add a photo and delete it, then it will change to brown border
            tmpLbl.layer.borderColor = [UIColor brownColor].CGColor;
            tmpLbl.layer.borderWidth = 1;
        }
        
        tmpLbl.userInteractionEnabled = YES;
        [tmpLblUniqueIdMap setObject:annView forKey:[NSNumber numberWithInt:tmpLblUniqueMapIdx ]];
        tmpLbl.tag = tmpLblUniqueMapIdx;
        tmpLblUniqueMapIdx++;
        //tmpLbl.textAlignment = UITextAlignmentCenter;
        tmpLbl.lineBreakMode = NSLineBreakByWordWrapping;
        
        
        [self setDescLabelSizeByZoomLevel:tmpLbl];
        if ([self showAnnotationTmpLbl])
            tmpLbl.hidden = true;
        //tmpLbl.alpha = 0;
        else
            //tmpLbl.hidden=false;
            tmpLbl.hidden=false;
        
        [annotationToShowImageSet setObject:tmpLbl forKey:key];
        [self.view addSubview:tmpLbl];
        
    }
    else //if already in the set, need make sure it will be shown
    {
        if (annotation.eventType == EVENT_TYPE_NO_PHOTO)
            tmpLbl.text = [ATHelper clearMakerAllFromDescText: annotation.description ]; //need to change to take care of if user updated description in event editor
        
        if ([self showAnnotationTmpLbl])
            tmpLbl.hidden = true;
        //tmpLbl.alpha = 0;
        else
            //tmpLbl.alpha = 1;
            tmpLbl.hidden=false;
    }
}

- (BOOL)showAnnotationTmpLbl
{
    BOOL ret = false;
    if (switchEventListViewModeToVisibleOnMapFlag)
        ret = [self zoomLevel] <= ZOOM_LEVEL_TO_HIDE_DESC_IN_MAP_MODE;
    else
        ret = [self zoomLevel] <= ZOOM_LEVEL_TO_HIDE_DESC;
    return ret;
}


//////// From WWDC 2013 video "Map Kit in Perspective"
-(void)goToNextCamera
{
    if (animationCameras.count == 0) {
        return;
    }
    MKMapCamera * nextCamera = [animationCameras firstObject];
    [animationCameras removeObjectAtIndex:0];
    ////***** IMPORTANT change I made: NSAnimationContext from the video does not work, I found use UIView animateWithDuration
    [UIView animateWithDuration:1.0f animations:^{
        self.mapView.camera = nextCamera;;
    } completion:NULL];
    
}
-(void) performShortCmeraAnimation:(MKMapCamera*)end
{
    CLLocationCoordinate2D startingCoordinate = self.mapView.centerCoordinate;
    MKMapPoint startingPoint = MKMapPointForCoordinate(startingCoordinate);
    MKMapPoint endingPoint = MKMapPointForCoordinate(end.centerCoordinate);
    
    MKMapPoint midPoint = MKMapPointMake(startingPoint.x + ((endingPoint.x - startingPoint.x)/2.0),
                                         startingPoint.y + ((endingPoint.y -startingPoint.y)/2.0));
    CLLocationCoordinate2D midCoordinate = MKCoordinateForMapPoint(midPoint);
    CLLocationDistance midAltitude = end.altitude *4;
    
    MKMapCamera *midCamera = [MKMapCamera cameraLookingAtCenterCoordinate:end.centerCoordinate
                                                        fromEyeCoordinate:midCoordinate eyeAltitude:midAltitude];
    animationCameras = [[NSMutableArray alloc] init];
    [animationCameras addObject:midCamera];
    [animationCameras addObject:end];
    [self goToNextCamera]; //this will kickout animation
}
-(void) performLongCmeraAnimation:(MKMapCamera*)end
{
    MKMapCamera *start = self.mapView.camera;
    CLLocation *startLocation = [[CLLocation alloc] initWithCoordinate:start.centerCoordinate
                                                              altitude:start.altitude
                                                    horizontalAccuracy:0
                                                      verticalAccuracy:0
                                                             timestamp:nil];
    CLLocation *endLocation = [[CLLocation alloc] initWithCoordinate:end.centerCoordinate
                                                            altitude:end.altitude
                                                  horizontalAccuracy:0
                                                    verticalAccuracy:0
                                                           timestamp:nil];
    CLLocationDistance distance = [startLocation distanceFromLocation:endLocation];
    CLLocationDistance midAltitude = distance;
    MKMapCamera *midCamera1 = [MKMapCamera cameraLookingAtCenterCoordinate:start.centerCoordinate
                                                         fromEyeCoordinate:start.centerCoordinate
                                                               eyeAltitude:midAltitude];
    MKMapCamera *midCamera2 = [MKMapCamera cameraLookingAtCenterCoordinate:end.centerCoordinate
                                                         fromEyeCoordinate:end.centerCoordinate
                                                               eyeAltitude:midAltitude];
    animationCameras = [[NSMutableArray alloc] init];
    [animationCameras addObject:midCamera1];
    [animationCameras addObject:midCamera2];
    [self goToNextCamera];
    
}
-(void)goToCoordinate:(CLLocationCoordinate2D)coord
{
    //TODO end point eyeAltitude should vary according to start/end distance. If distance is too small then eyeAltitude should narro to 500
    MKMapCamera *end = [MKMapCamera cameraLookingAtCenterCoordinate:coord
                                                  fromEyeCoordinate:coord
                                                        eyeAltitude:40000];
    
    
    MKMapCamera *start = self.mapView.camera;
    CLLocation *startLocation = [[CLLocation alloc] initWithCoordinate:start.centerCoordinate
                                                              altitude:start.altitude
                                                    horizontalAccuracy:0 verticalAccuracy:0 timestamp:nil];
    CLLocation *endLocation = [[CLLocation alloc] initWithCoordinate:end.centerCoordinate
                                                            altitude:end.altitude
                                                  horizontalAccuracy:0 verticalAccuracy:0 timestamp:nil];
    CLLocationDistance distance = [startLocation distanceFromLocation:endLocation];
    
    //TODO disable swirl effect when close
    if (distance <300) //if click on same event (or event close to eachother, zoom in)
    {
        end.altitude = 500;
        end.pitch = 55; //show 3d effect so building will show
    }
    else if (distance <1500) //if click on same event (or event close to eachother, zoom in)
    {
        end.altitude = 3000;
    }
    else if (distance <3000) //if click on same event (or event close to eachother, zoom in)
    {
        end.altitude = 5400;
    }
    //now filter based on distance
    if (distance < 50000) {
        [self.mapView setCamera:end animated:YES];
        return;
    }
    if (distance < 150000) {
        [self performShortCmeraAnimation:end];
        return;
    }
    [self performLongCmeraAnimation:end];
}
//////// end code from WWDC "Map Kit In Perspective"

- (void) updateEventListViewWithEventsOnMap
{
    if (eventListInVisibleMapArea == nil)
        eventListInVisibleMapArea = [[NSMutableArray alloc] init];
    else
        [eventListInVisibleMapArea removeAllObjects];
    
    if ([self zoomLevel] >= ZOOM_LEVEL_TO_HIDE_EVENTLIST_VIEW)
    {
        
        NSSet *nearbySet = [self.mapView annotationsInMapRect:self.mapView.visibleMapRect];

        //big performance hit
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        int eventStartPosition = 0;
        for(ATEventAnnotation* annView in nearbySet)
        {
            if ([annView isKindOfClass:[MKUserLocation class]])
                continue; //filter out MKUserLocation pin
            ATEventAnnotation* ann = annView;
            if ([ann isKindOfClass:[ATAnnotationPoi class]] && eventStartPosition <= MAX_NUMBER_OF_POI_IN_EVENT_VIEW)
            {
                if (![self checkCityOrCountryLevelHide:ann])
                    continue;
                ATEventDataStruct* evt = [[ATEventDataStruct alloc] init];
                evt.uniqueId = ann.uniqueId;
                evt.lat = ann.coordinate.latitude;
                evt.lng = ann.coordinate.longitude;
                evt.eventDate = ann.eventDate;
                evt.eventDesc = ann.description;
                evt.eventType = ann.eventType;
                evt.address = ann.address;
                
                [eventListInVisibleMapArea insertObject:evt atIndex:0];
                eventStartPosition++;
            }
            else
            {
                ATDefaultAnnotation* ann = (ATDefaultAnnotation*)annView;
                if (ann != nil && ann.uniqueId != nil)
                {
                    ATEventDataStruct* evt = [appDelegate.uniqueIdToEventMap objectForKey:ann.uniqueId];
                    if (evt != nil)
                        [eventListInVisibleMapArea insertObject:evt atIndex:eventStartPosition];
                }
            }
        }
        
    }
    if (eventListView.hidden == false)
        [self refreshEventListView:false];
}

- (void) updateEventListViewWithPoiOnMapOnly
{
    if (eventListInVisibleMapArea == nil)
        eventListInVisibleMapArea = [[NSMutableArray alloc] init];
    else
        [eventListInVisibleMapArea removeAllObjects];
    
    if ([self zoomLevel] >= ZOOM_LEVEL_TO_HIDE_POI_IN_EVENTLIST_VIEW)
    {
        
        NSSet *nearbySet = [self.mapView annotationsInMapRect:self.mapView.visibleMapRect];
        
        //big performance hit
        int eventStartPosition = 0;
        for(ATEventAnnotation* annView in nearbySet)
        {
            if ([annView isKindOfClass:[MKUserLocation class]])
                continue; //filter out MKUserLocation pin
            ATEventAnnotation* ann = annView;
            if ([ann isKindOfClass:[ATAnnotationPoi class]] && eventStartPosition <= MAX_NUMBER_OF_POI_IN_EVENT_VIEW)
            {
                if (![self checkCityOrCountryLevelHide:ann])
                    continue;
                ATEventDataStruct* evt = [[ATEventDataStruct alloc] init];
                evt.uniqueId = ann.uniqueId;
                evt.lat = ann.coordinate.latitude;
                evt.lng = ann.coordinate.longitude;
                evt.eventDate = ann.eventDate;
                evt.eventDesc = ann.description;
                evt.address = ann.address;
                
                [eventListInVisibleMapArea insertObject:evt atIndex:0];
                eventStartPosition++;
            }
        }
        
    }
    if (eventListView.hidden == false)
        [self refreshEventListView:false];
}


-(BOOL)checkCityOrCountryLevelHide:(ATEventAnnotation*)annView
{
    //If there are too many poi on screen while in large zoom level, I only want to list those 10 closest to center in event list window. But to do it, we need get distances for all poi to center, sort and pick closest 10 poi, wich will have big performance hit
    
    //My approach is to pick 10 from those within certain distance to center based on zoom level:
    //  The small the zoom level, the closer to center will be shown.
    //  When zoom level is large than 12, then show all poi on screen
    
    int eventType = annView.eventType;
    //NSLog(@"zoo level  %d   eventType=%d",appDelegate.zoomLevel, eventType);
    int zoomLevel = [self zoomLevel];
    if ((zoomLevel > ZOOM_LEVEL_POI_11 && eventType == POI_DISPLAY_TYPE_STAR)   //display star poi only when zoom to city level
        || (zoomLevel > ZOOM_LEVEL_POI_7 && eventType == POI_DISPLAY_TYPE_ORANGE)  //display orange poi only when zoom to state level
        || (zoomLevel > ZOOM_LEVEL_POI_4 && eventType == POI_DISPLAY_TYPE_RED_DOT)) //display global poi when zoom to countries level
    {
        //need to show poi, but only show those close to map center
        float distanceRatioToCenter = 2.5;
        /*
        if (appDelegate.zoomLevel < 9)
            distanceRatioToCenter = 4;
        else
            distanceRatioToCenter = 2.5; //the smaller the value, the more poi  included (or larger radius)
         */
        CLLocationCoordinate2D center = [self.mapView centerCoordinate];
        MKMapRect mRect = self.mapView.visibleMapRect;
        CLLocationCoordinate2D conerPoint = [self getCoordinateFromMapRectanglePoint:MKMapRectGetMinX(mRect) y:mRect.origin.y];
        CLLocation* centerColl = [[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude];
        CLLocation* conerColl = [[CLLocation alloc] initWithLatitude:conerPoint.latitude longitude:conerPoint.longitude];
        CLLocationDistance halfWayDistance = [conerColl distanceFromLocation:centerColl] / distanceRatioToCenter;
        
        CLLocation* poiColl = [[CLLocation alloc] initWithLatitude:annView.coordinate.latitude longitude:annView.coordinate.longitude];
        CLLocationDistance distance = [centerColl distanceFromLocation:poiColl];
        if (distance < halfWayDistance)
            return true;
        else
            return false;
    }
    else
        return false; //Do not list any poi in event list view
}

-(CLLocationCoordinate2D)getCoordinateFromMapRectanglePoint:(double)x y:(double)y{
    MKMapPoint swMapPoint = MKMapPointMake(x, y);
    return MKCoordinateForMapPoint(swMapPoint);
}


- (void) showDescriptionLabelViews:(MKMapView*)mapView
{
    for (id key in annotationToShowImageSet) {
        NSArray *splitArray = [key componentsSeparatedByString:@"|"];
        UILabel* tmpLbl = [annotationToShowImageSet objectForKey:key];
        CLLocationCoordinate2D coordinate;
        coordinate.latitude=[splitArray[0] doubleValue];
        coordinate.longitude = [splitArray[1] doubleValue];
        CGPoint annotationViewPoint = [mapView convertCoordinate:coordinate
                                                   toPointToView:mapView];
        if (TRUE) //self.mapViewShowWhatFlag == MAPVIEW_SHOW_ALL || self.mapViewShowWhatFlag == MAPVIEW_SHOW_PHOTO_LABEL_ONLY)
        {  //because mapRegion will call this function, so only show label this condition match
            bool tooCloseToShowFlag = false;
            
            for (NSValue* val in selectedAnnotationNearestLocationList)
            {
                CGPoint p = [val CGPointValue];
                CGFloat xDist = (annotationViewPoint.x - p.x);
                CGFloat yDist = (annotationViewPoint.y - p.y);
                CGFloat distance = sqrt((xDist * xDist) + (yDist * yDist));
                if (distance < DISTANCE_TO_HIDE)
                {
                    tooCloseToShowFlag = true;
                    break;
                }
            }
            if (tooCloseToShowFlag)
            {
                tmpLbl.hidden = true;
                tmpLbl.alpha = 0.3;
                continue;
            }
            else
            {
                tmpLbl.hidden = false; //xxxxx add today afte retreat
                tmpLbl.alpha = 1.0;
                [selectedAnnotationNearestLocationList addObject: [NSValue valueWithCGPoint:annotationViewPoint]];
            }
            
            [self setDescLabelSizeByZoomLevel:tmpLbl];
            CGSize size = tmpLbl.frame.size;
            [tmpLbl setFrame:CGRectMake(annotationViewPoint.x -20, annotationViewPoint.y+5, size.width, size.height)];
            if ([self showAnnotationTmpLbl])
            {
                tmpLbl.hidden = true;
                tmpLbl.alpha = 0.3;
            }
            else
            {
                float alpha = 1.0;
                if (eventListView.alpha < 1)
                    alpha = 0.2; //intentionally make it 0.2 instead of 0.3 after move map in hide mode

                [UIView animateWithDuration:0.5
                                      delay:0.0
                                    options:UIViewAnimationCurveEaseOut
                                 animations:^(void) {
                                     tmpLbl.alpha = alpha;
                                     tmpLbl.hidden = false; //// add after retreat
                                 }
                                 completion:NULL];
            }
        }
    }
    [selectedAnnotationNearestLocationList removeAllObjects];
}

- (void) hideDescriptionLabelViews
{
    for (id key in annotationToShowImageSet) {
        UILabel* tmpLbl = [annotationToShowImageSet objectForKey:key];
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationCurveEaseOut
                         animations:^(void) {
                             tmpLbl.alpha = 0.3;
                         }
                         completion:NULL];
    }
}
-(void) setDescLabelSizeByZoomLevel:(UILabel*)tmpLbl
{
    int zoomLevel = [self zoomLevel];
    CGSize expectedLabelSize = [tmpLbl.text sizeWithFont:tmpLbl.font
                                       constrainedToSize:tmpLbl.frame.size lineBreakMode:NSLineBreakByWordWrapping];
    tmpLbl.numberOfLines = 0;
    tmpLbl.font = [UIFont fontWithName:@"Arial" size:11];
    int labelWidth = 50;
    int labelHeight = 42;
    if ([self showAnnotationTmpLbl])
    {
        //tmpLbl.hidden = true; //do nothing, caller already hidden the label;
        tmpLbl.alpha = 0;
    }
    else if (zoomLevel <= 8)
    {
        tmpLbl.numberOfLines=4;
    }
    else if (zoomLevel <= 10)
    {
        tmpLbl.numberOfLines=4;
        labelWidth = 60;
        labelHeight = 47;
    }
    else if (zoomLevel <= 13)
    {
        tmpLbl.font = [UIFont fontWithName:@"Arial" size:13];
        tmpLbl.numberOfLines=5;
        labelWidth = 90;
        labelHeight = 68;
    }
    else
    {
        tmpLbl.font = [UIFont fontWithName:@"Arial" size:14];
        tmpLbl.numberOfLines=5;
        labelWidth = 100;
        labelHeight = 70;
    }
    
    //HONG if height > CONSTANT, then do not change, I do not like biggerImage unless in a big zooing
    CGRect newFrame = tmpLbl.frame;
    newFrame.size.height = labelHeight;
    newFrame.size.width=labelWidth;
    tmpLbl.frame = newFrame;

    UIImageView* imgView = (UIImageView*)[tmpLbl viewWithTag:HAVE_IMAGE_INDICATOR];
    if (imgView != nil)
    {
        imgView.frame = CGRectMake(imgView.frame.origin.x, imgView.frame.origin.y, tmpLbl.frame.size.width, tmpLbl.frame.size.height);
    }
    
}

- (int) zoomLevel {
    MKCoordinateRegion region = self.mapView.region;
    
    double centerPixelX = [self longitudeToPixelSpaceX: region.center.longitude];
    double topLeftPixelX = [self longitudeToPixelSpaceX: region.center.longitude - region.span.longitudeDelta / 2];
    
    double scaledMapWidth = (centerPixelX - topLeftPixelX) * 2;
    CGSize mapSizeInPixels = self.mapView.bounds.size;
    double zoomScale = scaledMapWidth / mapSizeInPixels.width;
    double zoomExponent = log(zoomScale) / log(2);
    double zoomLevel = 21 - zoomExponent;
    
    return zoomLevel;
}
- (MKAnnotationView*) getImageAnnotationView:(NSString*)annotationIdentifier :(id <MKAnnotation>)annotation
{
    {
        MKAnnotationView* annView = (MKAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
        if (!annView)
        {
            MKAnnotationView* customPinView = [[MKAnnotationView alloc]
                                               initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
            // NSLog(@"========= img %@",annotationIdentifier);
            NSInteger alphaValueLoc = [annotationIdentifier rangeOfString:@":"].location;
            float alphaValue = 1.0;
            if ( alphaValueLoc != NSNotFound)
            {
                NSString* origianlStr = annotationIdentifier;
                annotationIdentifier = [annotationIdentifier substringToIndex:alphaValueLoc];
                NSString* alphaValueStr = [origianlStr substringFromIndex:alphaValueLoc + 1];
                alphaValue = [alphaValueStr floatValue];
                //NSLog(@" ---- ann=%@,  alpha=%@",annotationIdentifier, alphaValueStr);
            }
            UIImage *markerImage = [UIImage imageNamed:annotationIdentifier];
            customPinView.image = markerImage;
            [customPinView setAlpha:alphaValue]; //introduced when add static marker (hinted by description text ==start== etc
            customPinView.canShowCallout = YES;
            
            UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            rightButton.accessibilityLabel=@"right";
            customPinView.rightCalloutAccessoryView = rightButton;
            
            UIButton* leftButton = [UIButton buttonWithType:UIButtonTypeInfoLight ];
            [leftButton setTintColor:[UIColor clearColor]];
            [leftButton setBackgroundImage:[UIImage imageNamed:@"car-icon.png"] forState:UIControlStateNormal];
            
            leftButton.accessibilityLabel=@"left";
            customPinView.leftCalloutAccessoryView = leftButton;
            
            return customPinView;
        }
        else
            //NSLog(@"+++++++++ resuse %@ annotation at %@",annotationIdentifier, [annotation title]);
            
            return annView;
    }
}
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([control.accessibilityLabel isEqualToString: @"right"]){
        selectedEventAnnOnMap = view;
        selectedEventAnnDataOnMap = [view annotation];
        [self startEventEditor:view];
        
        [self refreshFocusedEvent];
    }
    else
    {
        ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
        _destAnnForDirection = [view annotation];
        ATEventDataStruct* startData = appDelegate.focusedEvent;
        if ([_destAnnForDirection.uniqueId isEqualToString:startData.uniqueId])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Direction to this checked event",nil)
                                                            message:NSLocalizedString(@"Tap another event or long press any location on map as start point to get direction here.",nil)
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                  otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Direction to the checked event:",nil)]
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"%@",nil),startData.address]
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                  otherButtonTitles:NSLocalizedString(@"Drive",nil), NSLocalizedString(@"Walk",nil),nil];
            alert.tag = ALERT_FOR_DIRECTION_MODE;
            [alert show];
        }
    }
}

- (void) drawDirectionWithMode:(int)mode
{
    [self closeDirectionView:nil]; //prevent tap// direction again before close perviouse one
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    ATEventDataStruct* startData = appDelegate.focusedEvent;
    MKPlacemark *fromPlacemark = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(startData.lat, startData.lng) addressDictionary:nil];
    MKPlacemark *destPlacemark = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(_destAnnForDirection.coordinate.latitude, _destAnnForDirection.coordinate.longitude) addressDictionary:nil];
    MKMapItem* fromItem = [[MKMapItem alloc] initWithPlacemark:fromPlacemark];
    MKMapItem* toItem = [[MKMapItem alloc] initWithPlacemark: destPlacemark];
    
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    [request setSource:fromItem];
    [request setDestination:toItem];
    [request setTransportType:mode]; // This can be limited to automobile and walking directions.
    [request setRequestsAlternateRoutes:YES]; // Gives you several route options.
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    if (_directionOverlayArray == nil)
        _directionOverlayArray = [[NSMutableArray alloc] init];
    else
    {
        [self.mapView removeOverlays:_directionOverlayArray];
        [_directionOverlayArray removeAllObjects];
    }
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        if (!error) {
            if (_directionRouteDistanceResultSet == nil)
                _directionRouteDistanceResultSet = [[NSMutableArray alloc] init];
            else
                [_directionRouteDistanceResultSet removeAllObjects];
            _directionRouteColorResultSet = @[[UIColor blueColor],[UIColor orangeColor],[UIColor greenColor],[UIColor purpleColor]];

            MKDistanceFormatter *formatter = [[MKDistanceFormatter alloc] init];
            //formatter.units = MKDistanceFormatterUnitsImperial; // Mile
            formatter.units = MKDistanceFormatterUnitsDefault; //Km
            int routeCount = 0;
            for (MKRoute *route in [response routes]) {
                MKPolyline* line = [route polyline];
                line.title = [NSString stringWithFormat: @"direction_%d",routeCount ];
                [_directionOverlayArray addObject:line];
                [self.mapView addOverlay:line level:MKOverlayLevelAboveRoads]; // Draws the route above roads, but below labels.
                
                float distance = route.distance;
                NSString* distanceStr = [formatter stringFromDistance:distance];
                NSTimeInterval expectedTime = route.expectedTravelTime;
                int hours = expectedTime / 3600;
                int minutes = (expectedTime - hours*3600)/60;
                NSString* str = [NSString stringWithFormat:NSLocalizedString(@"%@ - %dh %dmin",nil),distanceStr,hours, minutes];
                if (hours >= 10)
                    str = [NSString stringWithFormat:NSLocalizedString(@"%@ - %dh",nil),distanceStr,hours];
                [_directionRouteDistanceResultSet addObject:str];

                routeCount++;
                if (routeCount >= 3) break; //max only show 3 routes
                // You can also get turn-by-turn steps, distance, advisory notices, ETA, etc by accessing various route properties.
            }
            
            [self refreshAnnotations];//without this, the first time draw direction will not display unless move map a little bit
            [self startDirectionInfoView];
        }
        else
        {
            [self closeDirectionView:nil];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Direction Not Available",nil)
                                                            message:error.localizedFailureReason
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                  otherButtonTitles:nil];
            alert.tag = ALERT_FOR_POPOVER_ERROR;
            [alert show];
        }
    }];
}


- (void) refreshFocusedEvent
{
    //if (selectedEventAnnOnMap == nil || switchEventListViewModeToVisibleOnMapFlag)
    //    return; //do not focuse when popup event editor in map event list mode for two reason:
                // 1. conceptually it is not neccessary   2. there is a small bug if do so
    //MKMapView* mapView = self.mapView;
    MKAnnotationView* view = selectedEventAnnOnMap;
    //need use base class ATEventAnnotation here to handle call out for all type of annotation
    ATEventAnnotation* ann = [view annotation];
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    /********** remove annimation of focuse event, I think it is not neccessary
    //get view location of an annotation
    CGPoint annotationViewPoint = [mapView convertCoordinate:view.annotation.coordinate
                                               toPointToView:mapView];
    CGRect newFrame = CGRectMake(annotationViewPoint.x,annotationViewPoint.y,0,0);//self.focusedEventLabel.frame;
    self.focusedEventLabel.frame = newFrame;
    self.focusedEventLabel.text = [NSString stringWithFormat:@" %@",[appDelegate.dateFormater stringFromDate: ann.eventDate]];
    [self.focusedEventLabel setHidden:false];
    [UIView transitionWithView:self.focusedEventLabel
                      duration:0.5f
                       options:UIViewAnimationCurveEaseInOut
                    animations:^(void) {
                        self.focusedEventLabel.frame = focusedLabelFrame;
                    }
                    completion:^(BOOL finished) {
                        // Do nothing
                        [self.focusedEventLabel setHidden:true];
                    }];
     ***********/
    selectedAnnotationIdentifier = [self getImageIdentifier:ann.eventDate :ann.description];
    ATEventDataStruct* ent = [appDelegate.uniqueIdToEventMap objectForKey:ann.uniqueId];
    if (ent == nil)
        ent = [[ATEventDataStruct alloc] init];
    ent.address = ann.address;
    ent.lat = ann.coordinate.latitude;
    ent.lng = ann.coordinate.longitude;
    ent.eventDate = ann.eventDate;
    ent.eventType = ann.eventType;
    ent.eventDesc = ann.description;
    ent.uniqueId = ann.uniqueId;
    
    if ([ATHelper isPOIEvent:ent])
        return;
    
    appDelegate.focusedEvent = ent;
    
    [self setNewFocusedDateAndUpdateMap:ent needAdjusted:TRUE]; //No reason, have to do focusedRow++ when focused a event in time wheel

    appDelegate.focusedEvent = ent;
    [self showTimeLinkOverlay];
    [self refreshEventListView:false];
    //bookmark selected event
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSUInteger idx = [appDelegate.eventListSorted indexOfObject:ent];
    [userDefault setObject:[NSString stringWithFormat:@"%lu",(unsigned long)idx ] forKey:@"BookmarkEventIdx"];
    [userDefault synchronize];
}

- (void) startEventEditor:(MKAnnotationView*)view
{
    ATEventAnnotation* ann = selectedEventAnnDataOnMap; // Here is key to fix max/min bug that has different event displayed (perviousely the buggy one has ann = view.annotation)
    self.selectedAnnotation = ann;
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.isForPOIEditorFlag = false;
    UIStoryboard* storyboard = appDelegate.storyBoard;
    NSDateFormatter *dateFormater = appDelegate.dateFormater;
    //if (self.eventEditor == nil) {
    //I just learned from iOS5 tutor pdf, there is a way to create segue for accessory buttons, I do not want to change, Will use it in iPhone storyboard
    self.eventEditor = [storyboard instantiateViewControllerWithIdentifier:@"event_editor_id"];
    self.eventEditor.delegate = self;
    //}
    
    SWRevealViewController *revealController = [self revealViewController];
    //
    //TODO if current revealed right side is preference, then do nothing?
    //
    revealController.rightViewController = self.eventEditor;
    revealController.rightViewRevealWidth = [ATConstants revealViewEventEditorWidth];

    if (!appDelegate.rightSideMenuRevealedFlag)
        [revealController rightRevealToggle:nil];
    else
    {
        [revealController rightRevealToggle:nil];
        [revealController rightRevealToggle:nil];
    }
    
    /*
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        BOOL optionIPADFullScreen = [ATHelper getOptionEditorFullScreen];
        if (optionIPADFullScreen)
        {
            [self.navigationController presentViewController:self.eventEditor animated:YES completion:nil];
        }
        else
        {
            self.eventEditorPopover = [[UIPopoverController alloc] initWithContentViewController:self.eventEditor];
            self.eventEditorPopover.popoverContentSize = CGSizeMake(380,480);
            
            //Following view.window=nil case is weird. When tap on text/image to start eventEditor, system will crash after around 10 times. Googling found it will happen when view.window=nil, so have to alert user and call refreshAnn in alert delegate to fix it. (will not work without put into alert delegate)
            BOOL isAtLeastIOS8 = [ATHelper isAtLeastIOS8];
            if (isAtLeastIOS8) //##### this part took me a few week, finally found solution so I can use xcode 6now
                [self.eventEditorPopover presentPopoverFromRect:view.frame inView:self.mapView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            else if (view.window != nil && !isAtLeastIOS8)
                [self.eventEditorPopover presentPopoverFromRect:view.bounds inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A minor error occurs",nil)
                                                                message:NSLocalizedString(@"Please try again!",nil)
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                      otherButtonTitles:nil];
                alert.tag = ALERT_FOR_POPOVER_ERROR;
                [alert show];

            }
        }
    }
    else {
        //[self performSegueWithIdentifier:@"eventeditor_segue_id" sender:nil];
        //[self.navigationController presentModalViewController:self.eventEditor animated:YES]; //pushViewController: self.eventEditor animated:YES];
        [self.navigationController presentViewController:self.eventEditor animated:YES completion:nil];
    }
    */
    //has to set value here after above presentXxxxx method, otherwise the firsttime will display empty text
    [self.eventEditor resetEventEditor];
    
    
    self.eventEditor.coordinate = ann.coordinate;
    if ([ann.description isEqualToString:NEWEVENT_DESC_PLACEHOLD])
    {
        self.eventEditor.description.textColor = [UIColor lightGrayColor];
    }
    
    self.eventEditor.description.text = ann.description;
    self.eventEditor.address.text=ann.address;
    self.eventEditor.dateTxt.text = [NSString stringWithFormat:@"%@",
                                     [dateFormater stringFromDate:ann.eventDate]];
    self.eventEditor.eventType = ann.eventType;
    self.eventEditor.hasPhotoFlag = EVENT_TYPE_NO_PHOTO; //not set to ann.eventType because we want to use this flag to decide if need save image again
    self.eventEditor.eventId = ann.uniqueId;
    if (ann.uniqueId != nil)
        self.eventEditor.eventData = [appDelegate.uniqueIdToEventMap objectForKey:ann.uniqueId];
    else
        self.eventEditor.eventData = nil;
    
    [ATEventEditorTableController setEventId:ann.uniqueId];
    //if (ann.eventType == EVENT_TYPE_HAS_PHOTO)
    [self.eventEditor createPhotoScrollView: ann.uniqueId eventDesc:ann.description ];
}

- (void) startPOIEditor:(MKAnnotationView*)view
{
    ATEventAnnotation* ann = view.annotation;// selectedEventAnnDataOnMap; // [view annotation];
    self.selectedAnnotation = ann;
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.isForPOIEditorFlag = true;
    UIStoryboard* storyboard = appDelegate.storyBoard;

    self.eventEditor = [storyboard instantiateViewControllerWithIdentifier:@"poi_editor_id"];
    self.eventEditor.delegate = self;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        //BOOL optionIPADFullScreen = [ATHelper getOptionEditorFullScreen];
        if (false) //(optionIPADFullScreen)
        {
            [self.navigationController presentViewController:self.eventEditor animated:YES completion:nil];
        }
        else
        {
            self.eventEditorPopover = [[UIPopoverController alloc] initWithContentViewController:self.eventEditor];
            self.eventEditorPopover.popoverContentSize = CGSizeMake(380,480);
            
            //Following view.window=nil case is weird. When tap on text/image to start eventEditor, system will crash after around 10 times. Googling found it will happen when view.window=nil, so have to alert user and call refreshAnn in alert delegate to fix it. (will not work without put into alert delegate)
            BOOL isAtLeastIOS8 = [ATHelper isAtLeastIOS8];
            if (isAtLeastIOS8) //##### this part took me a few week, finally found solution so I can use xcode 6now
                [self.eventEditorPopover presentPopoverFromRect:view.frame inView:self.mapView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            else if (view.window != nil && !isAtLeastIOS8)
                [self.eventEditorPopover presentPopoverFromRect:view.bounds inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A minor error occurs",nil)
                                                                message:NSLocalizedString(@"Please try again!",nil)
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                      otherButtonTitles:nil];
                alert.tag = ALERT_FOR_POPOVER_ERROR;
                [alert show];
                
            }
        }
    }
    else {
        [self.navigationController presentViewController:self.eventEditor animated:YES completion:nil];
    }
    //has to set value here after above presentXxxxx method, otherwise the firsttime will display empty text
    [self.eventEditor resetEventEditor];
    self.eventEditor.description.dataDetectorTypes = UIDataDetectorTypeLink;
    self.eventEditor.coordinate = ann.coordinate;
    if ([ann.description isEqualToString:NEWEVENT_DESC_PLACEHOLD])
    {
        self.eventEditor.description.textColor = [UIColor lightGrayColor];
    }
    
    NSString* descToDisplay= ann.description;
    NSString* descStr= ann.description;
    NSString* titleStr = @"";
    NSMutableAttributedString *attString=[[NSMutableAttributedString alloc] initWithString:descStr];
    
    NSUInteger titleEndLocation = [descStr rangeOfString:@"\n"].location;
    if (titleEndLocation < 80) //title is in file as [Desc]xxx yyy zzzz\n
    {
        titleStr = [descStr substringToIndex:titleEndLocation];
        descStr = [descStr substringFromIndex:titleEndLocation];
        descToDisplay = [NSString stringWithFormat:@"%@%@",titleStr, descStr ];
        attString=[[NSMutableAttributedString alloc] initWithString:descToDisplay];
        [attString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Arial-BoldMT" size:16] range:NSMakeRange(0, [titleStr length] + 1)];
        [attString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Arial" size:15] range:NSMakeRange([titleStr length] + 1, [descStr length]-1)];
    }
    
    self.eventEditor.description.attributedText = attString;
    self.eventEditor.hasPhotoFlag = EVENT_TYPE_NO_PHOTO; //not set to ann.eventType because we want to use this flag to decide if need save image again
    self.eventEditor.eventId = ann.uniqueId;
    if (ann.uniqueId != nil)
        self.eventEditor.eventData = [appDelegate.uniqueIdToEventMap objectForKey:ann.uniqueId];
    else
        self.eventEditor.eventData = nil;
    
    [ATEventEditorTableController setEventId:ann.uniqueId];
    [self.eventEditor createPhotoScrollView: ann.uniqueId eventDesc:ann.description];
}

//always start from focusedEvent
- (void) showTimeLinkOverlay
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    ATEventDataStruct* focusedEvent = appDelegate.focusedEvent;
    
    if (timeLinkOverlaysToBeCleaned != nil)
        [self.mapView removeOverlays:timeLinkOverlaysToBeCleaned];
    if (![ATHelper getOptionDisplayTimeLink])
        return;
    if (focusedEvent == nil)
        return;
    if (timeLinkOverlayDepthColorMap == nil) //keyed on lat|lng, value is depth. viewForOverlay() can use this to decide what color the link to draw
        timeLinkOverlayDepthColorMap = [[NSMutableDictionary alloc] init];
    else
        [timeLinkOverlayDepthColorMap removeAllObjects];
    
    if (timeLinkOverlaysToBeCleaned == nil)
        timeLinkOverlaysToBeCleaned = [[NSMutableArray alloc] init];
    else
        [timeLinkOverlaysToBeCleaned removeAllObjects];
    
    //first draw a circle on selected event
    CLLocationCoordinate2D workingCoordinate;
    workingCoordinate.latitude = focusedEvent.lat;
    workingCoordinate.longitude = focusedEvent.lng;
    if (focusedAnnotationIndicator == nil)
        focusedAnnotationIndicator = [[ATAnnotationFocused alloc] init];
    else
        [self.mapView removeAnnotation:focusedAnnotationIndicator];
    focusedAnnotationIndicator.coordinate = workingCoordinate;
    [self.mapView addAnnotation:focusedAnnotationIndicator];
    
    
    //following prepare mkPoi
    timeLinkDepthDirectionFuture = 0;
    timeLinkDepthDirectionPast = 0;
    NSArray* futureOverlays = [self prepareTimeLinkOverlays:focusedEvent :true];
    //NSLog(@"---------------------------------------");
    NSArray* pastOverlays = [self prepareTimeLinkOverlays:focusedEvent :false];
    
    [timeLinkOverlaysToBeCleaned addObjectsFromArray:futureOverlays];
    [timeLinkOverlaysToBeCleaned addObjectsFromArray:pastOverlays];
    
    
    // http://stackoverflow.com/questions/15061207/how-to-draw-a-straight-line-on-an-ios-map-without-moving-the-map-using-mkmapkit
    //add line by line, instead add all lines in one MKPolyline object, because I want to draw color differently in viewForOverlay
    NSUInteger size = [futureOverlays count];
    for(int i = 0; i < size; i++)
    {
        MKPolyline* line = futureOverlays[i];
        [self.mapView addOverlay:line];
    }
    size = [pastOverlays count];
    for(int i = 0; i < size; i++)
    {
        MKPolyline* line = pastOverlays[i];
        [self.mapView addOverlay:line];
    }
}

- (NSArray*) prepareTimeLinkOverlays:(ATEventDataStruct*)ent :(BOOL)directionFuture
{
    //direction = true is for event before ent
    //direction = false is for event after ent
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray* list  = appDelegate.eventListSorted;
    NSUInteger listSize =[list count];
    
    
    NSInteger currEventIdxConstant = [list indexOfObject:ent];
    
    //link all same day, and 5 different days before/after, (same day must be togetther
    NSInteger linkDepth = 0;
    NSInteger linkCount = 0;
    
    ATEventDataStruct* prevEvent = ent;
    ATEventDataStruct* thisEvent = nil;
    NSMutableArray* returnPolylineList = [[NSMutableArray alloc] init];
    NSMutableArray* eventsInSameDepth = [[NSMutableArray alloc] init];
    
    //Time link logic 1: max time to stop time link witn max depth limit
    int timeLinkMaxNumberOfDaysBtwTwoEvent = 5; //if time zoom is in day, then max is 30
    if (appDelegate.selectedPeriodInDays >31 && appDelegate.selectedPeriodInDays <= 365)
    {
        timeLinkMaxNumberOfDaysBtwTwoEvent = 5; //TODO 365 for historical
    }
    else if (appDelegate.selectedPeriodInDays > 365 && appDelegate.selectedPeriodInDays <=3600)
        timeLinkMaxNumberOfDaysBtwTwoEvent = 5; //TODO 3650 for historical events
    else if (appDelegate.selectedPeriodInDays > 3600)
        timeLinkMaxNumberOfDaysBtwTwoEvent = 5; //TODO 36000 for historical event
    
    //Following is to add points for event in future, and in before depends on direction, the logic is not ideal, hope it works
    //NOTE a senario: if zoom range is not day and focused group is at end, then dashed line for this group will not show
    while (linkDepth <= TIME_LINK_DEPTH) { //TODO TIME_LINK_DEPTH is 5, should be configurable, same day event link together
        linkCount++;
        NSInteger thisIdx = currEventIdxConstant + linkCount;
        if (directionFuture)
            thisIdx = currEventIdxConstant - linkCount;
        
        BOOL breakFlag = false;
        MKPolyline* timeLinkPolyline = nil;
        if (thisIdx >= 0 && thisIdx < listSize)
        {
            thisEvent = list[thisIdx];
            
            NSTimeInterval interval = [thisEvent.eventDate timeIntervalSinceDate: prevEvent.eventDate];
            
            if (abs(interval/86400.0) > timeLinkMaxNumberOfDaysBtwTwoEvent) //TODO  may need to tie with period lenth
            {
                if ([eventsInSameDepth count] == 0)
                    break;
                else
                    breakFlag = true; //breakFlag = true;
            }
            else
            {
                
                //NSLog(@"===in range: date1=%@   date2=%@    days=%f", thisEvent.eventDate, prevEvent.eventDate, interval/86400.0);
                
                [eventsInSameDepth addObject:prevEvent];
                [eventsInSameDepth addObject:thisEvent];
            }
            
        }
        else
        {
            if ([eventsInSameDepth count] == 0)
                break;
            else
                breakFlag = true; //breakFlag = true;
            //else will continues following to finish remaining draw for nodes in same depth
        }
        
        NSInteger numberOfSameDepthLine;
        //Time Link logic 2: put group of events in same time link depth according to time wheel zoom
        BOOL sameDepthFlag = false;
        if (appDelegate.selectedPeriodInDays <=30)
        {
            sameDepthFlag = [prevEvent.eventDate isEqualToDate:thisEvent.eventDate];
        }
        else if (appDelegate.selectedPeriodInDays >30 && appDelegate.selectedPeriodInDays <= 365)
        {
            NSString* year1 = [ATHelper getYearMonthForTimeLink:prevEvent.eventDate];
            NSString* year2 = [ATHelper getYearMonthForTimeLink:thisEvent.eventDate];
            sameDepthFlag = [year1 isEqualToString:year2];
        }
        else if (appDelegate.selectedPeriodInDays >365 && appDelegate.selectedPeriodInDays <=3600)
        {
            NSString* year1 = [ATHelper getYearPartHelper:prevEvent.eventDate];
            NSString* year2 = [ATHelper getYearPartHelper:thisEvent.eventDate];
            sameDepthFlag = [year1 isEqualToString:year2];
        }
        else
        {
            NSString* year1 = [ATHelper get10YearForTimeLink:prevEvent.eventDate];
            NSString* year2 = [ATHelper get10YearForTimeLink:thisEvent.eventDate];
            sameDepthFlag = [year1 isEqualToString:year2];
        }
        
        if (!sameDepthFlag || breakFlag)
        { //if depth changed, draw the link. For same depth links, draw all in one overlay for better performance
            numberOfSameDepthLine = [eventsInSameDepth count] / 2 - 1;  //the last one is not same depth
            NSInteger pointArrSize = numberOfSameDepthLine;
            if (numberOfSameDepthLine > MAX_NUMBER_OF_TIME_LINKS_IN_SAME_DEPTH_GROUP)
                pointArrSize = MAX_NUMBER_OF_TIME_LINKS_IN_SAME_DEPTH_GROUP;
            if (numberOfSameDepthLine > 0)
            {
                // /******* Following code works to draw line amoung events in same depth, and not to draw all but the configurable number for performance. But I comment it out because I think no need to draw if in same depth because annotation color already dell the events are in same depth.
                int skipCount = 0;
                MKMapPoint* pointArr = malloc(sizeof(CLLocationCoordinate2D) * 2 * pointArrSize);
                for (int i = 0; i < numberOfSameDepthLine; i++)  //only process those with same date
                {
                    if (numberOfSameDepthLine > MAX_NUMBER_OF_TIME_LINKS_IN_SAME_DEPTH_GROUP
                        && i >= MAX_NUMBER_OF_TIME_LINKS_IN_SAME_DEPTH_GROUP/2
                        && i <= (numberOfSameDepthLine - MAX_NUMBER_OF_TIME_LINKS_IN_SAME_DEPTH_GROUP/2 - 1)
                        )
                    { //only show first few and last few timelink line, not all for better berformance
                        skipCount ++;
                        continue;
                    }
                    pointArr[2*(i - skipCount) ] = [self getEventMapPoint:eventsInSameDepth[2*i]];
                    pointArr[2*(i - skipCount)  + 1] = [self getEventMapPoint:eventsInSameDepth[2*i+1]];
                    
                }
                timeLinkPolyline = [MKPolyline polylineWithPoints:pointArr count:(2*pointArrSize)];
                [returnPolylineList addObject:timeLinkPolyline];
                free(pointArr);
                linkDepth ++;
                NSInteger tmp = linkDepth;
                if (directionFuture)
                    tmp = - tmp;
                NSString* lineStyle = [NSString stringWithFormat:@"%ld|%d", tmp, TIME_LINK_DASH_LINE_STYLE_FOR_SAME_DEPTH];
                NSString *key=[NSString stringWithFormat:@"%f|%f", timeLinkPolyline.coordinate.latitude, timeLinkPolyline.coordinate.longitude];
                [timeLinkOverlayDepthColorMap  setValue: lineStyle  forKey:key];
                // ******************************/
            }
            //the last one must have differnt date, so add separately. Actually here take care of line with different date
            unsigned long startIdx = [eventsInSameDepth count] - 2;
            MKMapPoint* pointArr2 = malloc(sizeof(CLLocationCoordinate2D) * 2);
            pointArr2[0] = [self getEventMapPoint:eventsInSameDepth[startIdx]];
            pointArr2[1] = [self getEventMapPoint:eventsInSameDepth[startIdx+1]];
            timeLinkPolyline = [MKPolyline polylineWithPoints:pointArr2 count:2];
            [returnPolylineList addObject:timeLinkPolyline];
            free(pointArr2);
            linkDepth ++;
            unsigned long tmp = linkDepth;
            if (directionFuture)
                tmp = - tmp;
            
            NSString* lineStyle = [NSString stringWithFormat:@"%ld|%d", tmp, TIME_LINK_SOLID_LINE_STYLE];
            //NSLog(@"    in prepare: linDepth=%d  tmp=%d, Solid Line",linkDepth, tmp);
            NSString *key=[NSString stringWithFormat:@"%f|%f", timeLinkPolyline.coordinate.latitude, timeLinkPolyline.coordinate.longitude];
            [timeLinkOverlayDepthColorMap  setValue: lineStyle  forKey:key];
            
            [eventsInSameDepth removeAllObjects];
            
            prevEvent = thisEvent;
            
            if (breakFlag)
                break;
        }
        else
        {   //so all same depth link will be in same overlay
            prevEvent = thisEvent;
            continue;
        }
        
    }
    if (directionFuture)
        timeLinkDepthDirectionFuture = linkDepth;
    else
        timeLinkDepthDirectionPast = linkDepth;
    //NSLog(@"    in prepare: ======= linkDepth=%d   timLinkDepthDirectioTrue=%d   False=%d",linkDepth, timeLinkDepthDirectionFuture, timeLinkDepthDirectionPast);
    return returnPolylineList;
}

- (MKMapPoint) getEventMapPoint:(ATEventDataStruct*)evt
{
    CLLocationCoordinate2D workingCoordinate;
    workingCoordinate.latitude = evt.lat;
    workingCoordinate.longitude = evt.lng;
    return MKMapPointForCoordinate(workingCoordinate);
}

//called by self.mapView addOverlay()
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    //TODO draw line color according to date distance, use mkPointDateMapForTimeLinOverlay
    NSString *key=[NSString stringWithFormat:@"%f|%f", overlay.coordinate.latitude, overlay.coordinate.longitude];
    NSString *lineStyle = [timeLinkOverlayDepthColorMap objectForKey:key];
    
    
    NSArray *splitArray = [lineStyle componentsSeparatedByString:@"|"];
    float colorHint =[splitArray[0] floatValue];
    int lineStyleFlag = [splitArray[1] intValue];
    
    double depthFloat = timeLinkDepthDirectionPast;
    if (colorHint < 0) //we put negative number -tmp in prepareTimeLink()
        depthFloat = timeLinkDepthDirectionFuture;
    
    if (depthFloat == 0.0)
        return nil;
    //double alpha = colorHint/depthFloat;
    double alpha = (depthFloat  - abs(colorHint))/depthFloat;
    if (alpha == 0)
    {
        alpha = 0.1;
        if (depthFloat <= 2)
            alpha = 0.7;
    }
    if (alpha < 0)
        alpha = alpha * (-1.0);  //abs() is for int only, color will fail silently if give alpha value negative or great than 1. this fucking function make me crazy
    
    
    UIColor* color = [UIColor colorWithRed:0.9 green:0 blue:0 alpha:alpha];
    if (colorHint <= 0)
        color = [UIColor colorWithRed:0 green:0.9 blue:0 alpha:alpha];
    
    
    MKPolylineView* routeLineView = [[MKPolylineView alloc] initWithPolyline:overlay];
    
    routeLineView.fillColor = color;
    routeLineView.strokeColor = color;
    routeLineView.lineWidth = 2;
    // /***** following working code no longer need. see comments for events in same depth
    if (lineStyleFlag == TIME_LINK_DASH_LINE_STYLE_FOR_SAME_DEPTH) //for all events in same depth, draw dashed line
    {
        //DashLine render is too slow, get rid of it
        // routeLineView.lineDashPattern = [NSArray arrayWithObjects:[NSNumber numberWithFloat:3],[NSNumber numberWithFloat:10], nil];
        routeLineView.lineWidth = 2;
        
        if (abs(colorHint) <= 1) //color link to blue only when first depth has same
            routeLineView.strokeColor = [UIColor colorWithRed:0.7 green:0.6 blue:1.0 alpha:0.5];
        //routeLineView.lineDashPattern = [NSArray arrayWithObjects:[NSNumber numberWithFloat:6],[NSNumber numberWithFloat:15], nil]; //dash line is too slow
        
    }
    // *********/
    //NSLog(@"---- overlay title=%@",[overlay title]);
    if ([[overlay title] isEqualToString:@"direction_0"])
    {
        routeLineView.strokeColor = _directionRouteColorResultSet[0];
        routeLineView.lineWidth = 5.0;
    }
    else if ([[overlay title] isEqualToString:@"direction_1"])
    {
        routeLineView.strokeColor = _directionRouteColorResultSet[1];
        routeLineView.lineWidth = 5.0;
    }
    else if ([[overlay title] isEqualToString:@"direction_2"])
    {
        routeLineView.strokeColor = _directionRouteColorResultSet[2];
        routeLineView.lineWidth = 5.0;
    }
    else if ([[overlay title] isEqualToString:@"direction_3"])
    {
        routeLineView.strokeColor = _directionRouteColorResultSet[3];
        routeLineView.lineWidth = 5.0;
    }
    return routeLineView;
}

//I could not explain, but for tap left annotation button to focuse date, have to to do focusedRow++ in ATTimeScrollWindowNew
- (void) setNewFocusedDateAndUpdateMap:(ATEventDataStruct*) ent needAdjusted:(BOOL)needAdjusted
{
    if (!needAdjusted)
        currentSelectedEvent = ent;
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.focusedDate = ent.eventDate;
    [self.timeScrollWindow setNewFocusedDateFromAnnotation:ent.eventDate needAdjusted:needAdjusted];
    [self refreshAnnotations];
    //[self setMapCenter:ent];
}
- (void) setNewFocusedDateAndUpdateMapWithNewCenter:(ATEventDataStruct*) ent :(int)zoomLevel
{
    [self setNewFocusedDateAndUpdateMap:ent needAdjusted:FALSE];
    [self setMapCenter:ent :zoomLevel];
}
//Mostly called from time wheel (ATTimeScrollWindowNew
- (void) refreshAnnotations //Refresh based on new forcusedDate / selectedPeriodInDays
{
    selectedAnnotationViewsFromDidAddAnnotation = nil;
    //NSLog(@"refreshAnnotation called");
    NSMutableArray * annotationsToRemove = [ self.mapView.annotations mutableCopy ] ;
    //DO not refresh POI events
    for (ATEventAnnotation* ann in self.mapView.annotations)
    {
        if ([ann isKindOfClass:[ATAnnotationPoi class]])
            [annotationsToRemove removeObject:ann];
    }
    [ annotationsToRemove removeObject:self.mapView.userLocation ] ;
    [ self.mapView removeAnnotations:annotationsToRemove ] ;
    [self.mapView addAnnotations:annotationsToRemove];
    [self cleanAnnotationToShowImageSet];
    if (tutorialView != nil)
        [tutorialView updateDateText];
    //[2014-01-06]
    //*** By moving following to didAddAnnotation(), I solved the issue that forcuse an event to date cause all image to show, because above [self.mapView addAnnotations:...] will run parallel to bellow [self showDescr..] while this depends on annotationToShowImageSet prepared in viewForAnnotation, thuse cause problem
    //[self showDescriptionLabelViews:self.mapView];
}

- (NSString*)getImageIdentifier:(NSDate *)eventDate :(NSString*)specialMarkerName
{
    // NSLog(@"  --------------- %u", debugCount);
    //debugCount = debugCount + 1;

    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.focusedDate == nil) //set in annotation Left button click
        appDelegate.focusedDate = [[NSDate alloc] init];
    float segmentDistance = fabsf([self getDistanceFromFocusedDate:eventDate]);
    if (specialMarkerName != nil)
    {
        NSString* pngNameWithAlpha = [NSString stringWithFormat:@"marker_%@", specialMarkerName ];
        UIImage *tempImage = [UIImage imageNamed:pngNameWithAlpha];
        if (!tempImage) {
            pngNameWithAlpha = @"marker_star.png";
        }
        //if off-focuse, append image alpha value
        if (segmentDistance > 1 && segmentDistance <=2)
            pngNameWithAlpha = [NSString stringWithFormat:@"%@:0.7",pngNameWithAlpha];
        else if (segmentDistance > 2 && segmentDistance <=3)
            pngNameWithAlpha = [NSString stringWithFormat:@"%@:0.6",pngNameWithAlpha];
        else if (segmentDistance > 3 && segmentDistance <=4)
            pngNameWithAlpha = [NSString stringWithFormat:@"%@:0.5",pngNameWithAlpha];
        else if (segmentDistance > 4 && segmentDistance <= 5)
            pngNameWithAlpha = [NSString stringWithFormat:@"%@:0.4",pngNameWithAlpha ];
        else if (segmentDistance > 5)
            return [ATConstants WhiteFlagAnnotationIdentifier: switchEventListViewModeToVisibleOnMapFlag];
        
        return pngNameWithAlpha;
    }
    // For regular marker, I tried to use alpha instead of different marker image, but the looks on view is bad, so keep it following way
    if (segmentDistance >= -1 && segmentDistance <= 1)
        return [ATConstants SelectedAnnotationIdentifier];
    if (segmentDistance > 1 && segmentDistance <=2)
        return [ATConstants After1AnnotationIdentifier];
    if (segmentDistance > 2 && segmentDistance <=3)
        return [ATConstants After2AnnotationIdentifier];
    if (segmentDistance > 3 && segmentDistance <= 4)
        return [ATConstants After3AnnotationIdentifier];
    if (segmentDistance > 4 && segmentDistance <=5)
        return [ATConstants After4AnnotationIdentifier];
    if (segmentDistance > 5)
        return [ATConstants WhiteFlagAnnotationIdentifier:switchEventListViewModeToVisibleOnMapFlag]; //Do not show if outside range, but tap annotation is added, just not show and tap will cause annotation show
    if (segmentDistance >= -2 && segmentDistance < -1)
        return [ATConstants Past1AnnotationIdentifier];
    if (segmentDistance >= -3 && segmentDistance < -2)
        return [ATConstants Past2AnnotationIdentifier];
    if (segmentDistance >= -4 && segmentDistance < -3)
        return [ATConstants Past3AnnotationIdentifier];
    if (segmentDistance>= - 5 && segmentDistance < -4 )
        return [ATConstants Past4AnnotationIdentifier];
    if (segmentDistance < -5 )
        return [ATConstants WhiteFlagAnnotationIdentifier:switchEventListViewModeToVisibleOnMapFlag]; //do not show if outside range,  but tap annotation is added, just not show and tap will cause annotation show
    return nil;
}

- (float)getDistanceFromFocusedDate:(NSDate*)eventDate
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSTimeInterval interval = [eventDate timeIntervalSinceDate:appDelegate.focusedDate];
    float dayInterval = interval/86400;
    float segmentInDays = appDelegate.selectedPeriodInDays;
    /** These logic is for my previouse thining that all point be shown, and color phase depends on selectedPeriodInDays
     float segmentDistance = dayInterval/segmentInDays;
     ***/
    
    //Here, only show events withing selectedPeriodInDays, color phase will be selectedPeriodInDays/8
    float lenthOfEachSegment = segmentInDays/10 ; //or 8?
    return dayInterval / lenthOfEachSegment;  //if return value is greate than segmentInDays, then it beyong date rante
}

- (Boolean)eventInPeriodRange:(NSDate*)eventDate
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    float segmentInDays = appDelegate.selectedPeriodInDays;
    float distanceFromForcusedDate = [self getDistanceFromFocusedDate:eventDate];
    if (fabsf(distanceFromForcusedDate) > segmentInDays)
        return false;
    else
        return true;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"=============== Memory warning");
    // Dispose of any resources that can be recreated.
}

//delegate required implementation
- (void)deleteEvent{
    [self toggleMapViewShowHideAction]; //de-select annotation will flip it, so double flip
    //delete the selectedAnnotation, also delete from db if has uniqueId in the selectedAnnotation
    [self.dataController deleteEvent:self.selectedAnnotation.uniqueId];
    [self.mapView removeAnnotation:self.selectedAnnotation];
    ATEventDataStruct* tmp = [[ATEventDataStruct alloc] init];
    tmp.uniqueId = self.selectedAnnotation.uniqueId;
    tmp.eventDate = self.selectedAnnotation.eventDate;
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray* list  = appDelegate.eventListSorted;
    
    NSString *key=[NSString stringWithFormat:@"%f|%f",self.selectedAnnotation.coordinate.latitude, self.selectedAnnotation.coordinate.longitude];
    //remove photo/text icon as well if there are
    UILabel* tmpLbl = [annotationToShowImageSet objectForKey:key];
    if (tmpLbl != nil)
        [tmpLbl removeFromSuperview];
    [annotationToShowImageSet removeObjectForKey:key];//in case this is
    unsigned long index = [list indexOfObject:tmp]; //implemented isEqual
    if (index != NSNotFound)
        [list removeObjectAtIndex:index];
    NSLog(@"   delete object at index %lu",index);
    
    [self deletePhotoFilesByEventId:tmp.uniqueId];//put all phot into deletedPhotoQueue
    if (index == 0 || index == [list count]) //do not -1 since it already removed the element
    {
        [self setTimeScrollConfiguration: -1];
        [self displayTimelineControls];
    }
    if (self.eventEditorPopover != nil)
        [self.eventEditorPopover dismissPopoverAnimated:true];
    if (self.timeZoomLine != nil)
        [self.timeZoomLine setNeedsDisplay];
    [self refreshEventListView:false];
}
- (void)cancelEvent{
    if (self.eventEditorPopover != nil)
        [self.eventEditorPopover dismissPopoverAnimated:true];
}
- (void)restartEditor{
    [self startEventEditor:selectedEventAnnOnMap];
}
- (void)cancelPreference{
    if (self.preferencePopover != nil)
        [self.preferencePopover dismissPopoverAnimated:true];
}
- (void)updateEvent:(ATEventDataStruct*)newData newAddedList:(NSArray *)newAddedList deletedList:(NSArray*)deletedList photoMetaData:(NSDictionary *)photoMetaData{
    //update annotation by remove/add, then update database or added to database depends on if have id field in selectedAnnotation
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray* list  = appDelegate.eventListSorted;
    //For add event, check if the app has been purchased
    if (self.selectedAnnotation.uniqueId == nil && [list count] >= FREE_VERSION_QUOTA )
    {
        
        //solution in yahoo email, search"non-consumable"
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        NSString* loginSecurityCode = [userDefault objectForKey:[ATConstants UserSecurityCodeKeyName]];
        //This part is for test sandbox version, so no limit when test with Mac
        BOOL noHongliuliFlag = true;
        if (loginSecurityCode != nil && [loginSecurityCode isEqualToString:@"375151"])
            noHongliuliFlag = false;
        if ([userDefault objectForKey:IN_APP_PURCHASED] == nil && noHongliuliFlag)
        {
            purchase = [[ATInAppPurchaseViewController alloc] init];
            [purchase processInAppPurchase];
        }
        //Check again if purchase has really done
        if ([userDefault objectForKey:IN_APP_PURCHASED] == nil && noHongliuliFlag)
            return;
    }
    
    [self toggleMapViewShowHideAction]; //de-select annotation will flip it, so double flip
    ATEventEntity* newEntity = [self.dataController updateEvent:self.selectedAnnotation.uniqueId EventData:newData];
    if (newEntity == nil)
        newData.uniqueId = self.selectedAnnotation.uniqueId;
    else
        newData.uniqueId = newEntity.uniqueId;
    
    NSString* thumbNailFileName = nil;
    if (self.eventEditor.photoScrollView.photoList != nil && [self.eventEditor.photoScrollView.photoList count]>0)
    {
        thumbNailFileName = self.eventEditor.photoScrollView.photoList[0];
        if ([thumbNailFileName hasPrefix:@"/var/mobile/Containers/"])
            thumbNailFileName = nil; //if first photo is web photo, do not create thumbNail
    }
    else
        thumbNailFileName = newAddedList[1]; //TODO for adding demo event the firsttime
    /*
    NSDate *now = [NSDate date];
    if (sortList !=nil && [sortList count] > 0)
    {
        int thumbNailIdx = [sortList[0] intValue]; //always set first sorted as thumbnail
        thumbNailFileName = self.eventEditor.photoScrollView.photoList[thumbNailIdx];
        for (NSNumber* idxNum in sortList )
        {
            int idx = [idxNum intValue];
            NSString* photoFileName = self.eventEditor.photoScrollView.photoList[idx]; //check range
            
            //touch file to change file order
            NSString *photoFinalDir = [[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:newData.uniqueId];
            
            NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys: now, NSFileModificationDate, NULL];
            NSString* photoToTouch = [photoFinalDir stringByAppendingPathComponent:photoFileName];

            [[NSFileManager defaultManager] setAttributes: attr ofItemAtPath: photoToTouch error: NULL];
            now = [NSDate dateWithTimeInterval:-1.0 sinceDate:now]; //increment by on seconds
        }
    }
     */
    
    [self writePhotoToFile:newData.uniqueId newAddedList:newAddedList deletedList:deletedList photoForThumbNail:thumbNailFileName];//write file before add nodes to map, otherwise will have black photo on map
    
    NSString *key=[NSString stringWithFormat:@"%f|%f",newData.lat, newData.lng];
    UILabel* tmpLbl = [annotationToShowImageSet objectForKey:key];
    if (tmpLbl != nil)
    {
        [tmpLbl removeFromSuperview];
        [annotationToShowImageSet removeObjectForKey:key]; //so when update a event with new photo or text, the new photo/text will occure immediately because all annotations will be redraw for possible date change
    }
    if ([deletedList count] > 0 && [self.eventEditor.photoScrollView.photoList count] == 0)
    { //This is to fix floating photo if removed last photo in an event
        NSString *key=[NSString stringWithFormat:@"%f|%f", newData.lat, newData.lng];
        [annotationToShowImageSet removeObjectForKey:key];
    }
    
    //Need remove/add annotation or following will work?
    [self.selectedAnnotation setDescription:newData.eventDesc];
    [self.selectedAnnotation setAddress:newData.address];
    [self.selectedAnnotation setEventDate:newData.eventDate];
    [self.selectedAnnotation setEventType:newData.eventType];
    //Need following when change event location (from Flickr Face version)
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(newData.lat, newData.lng);
    //---I want to update info in annotation pop, but following will drop a new pin and no popup
    //---Following always add pin annotation because selectedAnnotation does not what type of annotation
    [self.mapView removeAnnotation:self.selectedAnnotation];
    ATAnnotationSelected *ann = [[ATAnnotationSelected alloc] init];
    ann.uniqueId = newData.uniqueId;
    [ann setCoordinate:coord];
    ann.address = newData.address;
    ann.description=newData.eventDesc;
    ann.eventDate=newData.eventDate;
    ann.eventType=newData.eventType;
    [self.mapView addAnnotation:ann];
    
    if (newEntity != nil) //we can  modify the logic, should use if selectedAnnotation.UniqueId == null to decide it is add action
    {
        //add in sorted order so timeline view can generate sections
        [list insertObject:newData atIndex:0];
        [list sortUsingComparator:^NSComparisonResult(id a, id b) {
            NSDate *first = [(ATEventEntity*)a eventDate];
            NSDate *second = [(ATEventEntity*)b eventDate];
            return [first compare:second]== NSOrderedAscending;
        }];
        [appDelegate.uniqueIdToEventMap setObject:newData forKey:newData.uniqueId];
    }
    else //for update, still need to remove and add incase  date is updated
    {
        //sort again because date may changed
        [list sortUsingComparator:^NSComparisonResult(id a, id b) {
            NSDate *first = [(ATEventEntity*)a eventDate];
            NSDate *second = [(ATEventEntity*)b eventDate];
            return [first compare:second]== NSOrderedAscending;
        }];
    }
    
     appDelegate.focusedDate = ann.eventDate;
    [self setNewFocusedDateAndUpdateMap:newData needAdjusted:FALSE];
    [self setTimeScrollConfiguration:-1];
    [self displayTimelineControls];
    
    if (self.timeZoomLine != nil)
        [self.timeZoomLine setNeedsDisplay];
    if (self.eventEditorPopover != nil)
        [self.eventEditorPopover dismissPopoverAnimated:true];
    [self refreshEventListView:false];
    
    //TODO save metaFile
    NSString *photoMetaFilePath = [[[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:newData.uniqueId] stringByAppendingPathComponent:PHOTO_META_FILE_NAME];
    if (newAddedList != nil && [newAddedList count] > 0)
    {
        NSMutableDictionary* photoDescMap = [photoMetaData objectForKey:PHOTO_META_DESC_MAP_KEY];
        NSDictionary* cloneMap = [NSDictionary dictionaryWithDictionary:photoDescMap];
        for (NSString* fileName in cloneMap)
        {
            NSString* descTxt = [photoDescMap objectForKey:fileName];
            NSString* fileName2 = fileName;
            NSInteger prefixLen = [NEW_NOT_SAVED_FILE_PREFIX length];
            if ([fileName hasPrefix:NEW_NOT_SAVED_FILE_PREFIX])
            {
                fileName2 = [fileName substringFromIndex:prefixLen];
                [photoDescMap removeObjectForKey:fileName];
                [photoDescMap setObject:descTxt forKey:fileName2];
            }
        }
    }
    if (photoMetaData != nil)
        [photoMetaData writeToFile:photoMetaFilePath atomically:TRUE];
}
//delegate required implementation
- (void)addToEpisode{
    if (eventEpisodeList == nil)
        eventEpisodeList = [[NSMutableArray alloc] init];
    
    NSString* tmpUniqueId = self.selectedAnnotation.uniqueId;
    if ([eventEpisodeList containsObject:tmpUniqueId])
        [eventEpisodeList removeObject:tmpUniqueId];
    else
        [eventEpisodeList addObject:tmpUniqueId];
    
    //Following will do removeAnnotation/addAnnotation for this one, so need to remove tmpLbl otherwise tab on icon/text after
    //add/remove episode will crash
    NSString *key=[NSString stringWithFormat:@"%f|%f",self.selectedAnnotation.coordinate.latitude, self.selectedAnnotation.coordinate.longitude];
    UILabel* tmpLbl = [annotationToShowImageSet objectForKey:key];
    [tmpLbl removeFromSuperview];
    [annotationToShowImageSet removeObjectForKey:key];
    //remove/add so viewForAnnotation will call to redraw the annotation with a new icon
    [self.mapView removeAnnotation:self.selectedAnnotation];
    [self.mapView addAnnotation:self.selectedAnnotation];

    if (self.timeZoomLine != nil)
        [self.timeZoomLine setNeedsDisplay];
    
    if ([eventEpisodeList count] == 0)
        [self closeEpisodeView];
    else
        [self startEpisodeView];
    
    
    
    if (self.eventEditorPopover != nil)
        [self.eventEditorPopover dismissPopoverAnimated:true];
    [self refreshEventListView:false];
}
- (BOOL)isInEpisode //delegate requried to implement
{
    if (eventEpisodeList == nil)
        return false;
    else
        return [eventEpisodeList containsObject:self.selectedAnnotation.uniqueId];
        
}

- (void) startEpisodeView
{
    BOOL largeFlag = false;
    int episodeViewHeight = EPISODE_VIEW_HIGHT_SMALL;
    if (episodeView == nil)
    {
        largeFlag = TRUE; //only when first show full episode wording
        episodeViewHeight = EPISODE_VIEW_HIGHT_LARGE;
        episodeView = [[UIView alloc] initWithFrame:CGRectMake(0,0,0,0)];
        [episodeView.layer setCornerRadius:10.0f];
       ////// episodeView setBackgroundColor:xxxx
        // Do any additional setup after loading the view, typically from a nib.
        
        //////[self.mapView addSubview:episodeView];
        
    }
    int episodeViewXPos = [ATConstants screenWidth] - EPISODE_VIEW_WIDTH;
    [UIView transitionWithView:self.mapView
                      duration:0.3
                       options:UIViewAnimationTransitionFlipFromRight //any animation
                    animations:^ {
                        [episodeView setFrame:CGRectMake(episodeViewXPos, 0, EPISODE_VIEW_WIDTH, episodeViewHeight)];
                        episodeView.backgroundColor=[UIColor colorWithRed:1 green:1 blue:0.7 alpha:0.6];
                        episodeView.layer.shadowColor = [UIColor grayColor].CGColor;
                        episodeView.layer.shadowOffset = CGSizeMake(15,15);
                        episodeView.layer.shadowOpacity = 1;
                        episodeView.layer.shadowRadius = 10.0;
                        [self.mapView addSubview:episodeView];
                        //[self partialInitEpisodeView];
                    }
                    completion:^(BOOL finished) {[self partialInitEpisodeView:largeFlag];}];
}

//the purpose to have this to be called in completion:^ is to make animation together with all subviews
//(ATTutorialView has drawRect so no such issue)
- (void) partialInitEpisodeView:(BOOL)largeFlag
{
    [[episodeView subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UILabel* lblWording = [[UILabel alloc] initWithFrame:CGRectMake(10, 3*EPISODE_ROW_HEIGHT + 10, EPISODE_VIEW_WIDTH - 20, 9*EPISODE_ROW_HEIGHT)];
    lblWording.lineBreakMode = NSLineBreakByWordWrapping;
    lblWording.numberOfLines = 0;
    lblWording.text = NSLocalizedString(@"An episode is a collection of events, such as an itinerary, that you can share to your friends' ChronicleMap app. (Photos are not included.)\n\nTo send an episode to a friend's ChronicleMap app, tap the episode in [Menu->Share my Episodes]\n\nYour friend can check the incoming episode in the app's [Menu->Collection Box] and download to display on map.",nil);
    [episodeView addSubview:lblWording];
    
    int btnY = 12*EPISODE_ROW_HEIGHT + 10;
    lblWording.hidden = false;
    if (!largeFlag)
    {
        btnY = 10 + 3*EPISODE_ROW_HEIGHT;
        lblWording.hidden = true;
    }
    NSString* btnSaveTitleText = NSLocalizedString(@"Create Episode",nil);
    if (episodeNameforUpdating != nil)
    {
        NSInteger nameLength = [episodeNameforUpdating length];
        if (nameLength >5)
            btnSaveTitleText = [NSString stringWithFormat:NSLocalizedString(@"Update %@..",nil), [episodeNameforUpdating substringToIndex:5]];
        else
            btnSaveTitleText = [NSString stringWithFormat:NSLocalizedString(@"Update %@",nil), episodeNameforUpdating];
    }
    if (largeFlag)
    {
        UIButton *btnAll = [UIButton buttonWithType:UIButtonTypeSystem];
        btnAll.frame = CGRectMake(10, 3*EPISODE_ROW_HEIGHT - 4, 120, 20);
        [btnAll setTitle:NSLocalizedString(@"Select All",nil) forState:UIControlStateNormal];
        btnAll.titleLabel.font = [UIFont fontWithName:@"Arial-Bold" size:15];
        [btnAll addTarget:self action:@selector(allEpisodeClicked:) forControlEvents:UIControlEventTouchUpInside];
        [episodeView addSubview: btnAll];
        
        UIButton *btnClear = [UIButton buttonWithType:UIButtonTypeSystem];
        btnClear.frame = CGRectMake(140, 3*EPISODE_ROW_HEIGHT - 4, 60, 20);
        [btnClear setTitle:NSLocalizedString(@"Less",nil) forState:UIControlStateNormal];
        btnClear.titleLabel.font = [UIFont fontWithName:@"Arial-Bold" size:17];
        [btnClear addTarget:self action:@selector(lessEpisodeClicked:) forControlEvents:UIControlEventTouchUpInside];
        [episodeView addSubview: btnClear];
    }
    UIButton *btnSave = [UIButton buttonWithType:UIButtonTypeSystem];
    btnSave.frame = CGRectMake(10, btnY, 120, 20);
    [btnSave setTitle:btnSaveTitleText forState:UIControlStateNormal];
    btnSave.titleLabel.font = [UIFont fontWithName:@"Arial-Bold" size:15];
    [btnSave addTarget:self action:@selector(saveEpisodeClicked:) forControlEvents:UIControlEventTouchUpInside];
    [episodeView addSubview: btnSave];
    
    UIButton *btnClear = [UIButton buttonWithType:UIButtonTypeSystem];
    btnClear.frame = CGRectMake(140, btnY, 60, 20);
    [btnClear setTitle:NSLocalizedString(@"Cancel",nil) forState:UIControlStateNormal];
    btnClear.titleLabel.font = [UIFont fontWithName:@"Arial-Bold" size:17];
    [btnClear addTarget:self action:@selector(cancelEpisodeClicked:) forControlEvents:UIControlEventTouchUpInside];
    [episodeView addSubview: btnClear];
    
    if (btnLess == nil)
        btnLess = [UIButton buttonWithType:UIButtonTypeSystem];
    btnLess.frame = CGRectMake(210, btnY, 60, 20);
    if (largeFlag)
        [btnLess setTitle:NSLocalizedString(@"Less",nil) forState:UIControlStateNormal];
    else
        [btnLess setTitle:NSLocalizedString(@"More",nil) forState:UIControlStateNormal];
    btnLess.titleLabel.font = [UIFont fontWithName:@"Arial-Bold" size:17];
    [btnLess addTarget:self action:@selector(lessEpisodeClicked:) forControlEvents:UIControlEventTouchUpInside];
    [episodeView addSubview: btnLess];
    
    if (txtNewEpisodeName == nil)
    {
        txtNewEpisodeName = [[UITextView alloc] initWithFrame:CGRectMake(10, 2*EPISODE_ROW_HEIGHT, EPISODE_VIEW_WIDTH - 20, EPISODE_ROW_HEIGHT)];
        //[episodeView addSubview:txtNewEpisodeName];
    }
    
    if (lblEpisode1 == nil)
    {
        lblEpisode1 = [[UILabel alloc] initWithFrame:CGRectMake(10, 2*EPISODE_ROW_HEIGHT, EPISODE_VIEW_WIDTH - 20, EPISODE_ROW_HEIGHT)];
    }
    [episodeView addSubview:lblEpisode1];
    NSInteger cnt = [eventEpisodeList count];
    if (episodeNameforUpdating == nil)
        lblEpisode1.text = [NSString stringWithFormat:NSLocalizedString(@"%d event(s) are picked for new episode",nil), cnt];
    else
        lblEpisode1.text = [NSString stringWithFormat:NSLocalizedString(@"%d event(s) are in episode [%@]",nil), cnt, episodeNameforUpdating];

}

- (void) closeEpisodeView
{
    if (episodeView != nil)
    {
        [UIView transitionWithView:self.mapView
                          duration:0.5
                           options:UIViewAnimationTransitionCurlDown
                        animations:^ {
                            [episodeView setFrame:CGRectMake(0,0,0,0)];
                        }
                        completion:^(BOOL finished) {
                            [episodeView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                            [episodeView removeFromSuperview];
                            episodeView = nil;
                        }];
    }
    episodeNameforUpdating = nil;
}

- (void) startDirectionInfoView
{
    UIButton* btnCancel = nil;

    if (_directionInfoView == nil)
    {
        //NSLog(@"%@",[[UIWindow keyWindow] _autolayoutTrace]);
        
        _directionInfoView = [[UIView alloc] init];
        [_directionInfoView.layer setCornerRadius:10.0f];
        _directionInfoView.translatesAutoresizingMaskIntoConstraints = NO;
        [_directionInfoView setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9]];
        [self.view addSubview:_directionInfoView];
        
        _lblDirectionDistance = [[UILabel alloc] init];
        UIFont *nameLabelFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        [_lblDirectionDistance setTextColor:[UIColor blackColor]];
        _lblDirectionDistance.font = nameLabelFont;
        _lblDirectionDistance.tag = 100;
        btnCancel = [[UIButton alloc] init];
        [btnCancel setTitle:NSLocalizedString(@"Cancel",nil) forState:UIControlStateNormal];
        [btnCancel setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [btnCancel addTarget:self action:@selector(closeDirectionView:) forControlEvents:UIControlEventTouchUpInside];
     
        [_directionInfoView addSubview:_lblDirectionDistance];
        [_directionInfoView addSubview:btnCancel];
        
        _lblDirectionDistance.translatesAutoresizingMaskIntoConstraints = NO;
        btnCancel.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *itemsDictionary = NSDictionaryOfVariableBindings(_lblDirectionDistance, btnCancel);
        _topDistanceLblCon = [NSLayoutConstraint
                           constraintsWithVisualFormat:@"V:|-5-[_lblDirectionDistance(50)]" options:0 metrics:nil views:itemsDictionary];
        NSArray* topCancelBtnCon = [NSLayoutConstraint
                           constraintsWithVisualFormat:@"V:|-5-[btnCancel(60)]" options:0 metrics:nil views:itemsDictionary];
        NSArray* lblDistanceConstraints = [NSLayoutConstraint
                                           constraintsWithVisualFormat:@"H:|-5-[_lblDirectionDistance(240)]" options:0 metrics:nil views:itemsDictionary];
        NSArray* cancelConstraints = [NSLayoutConstraint
                                      constraintsWithVisualFormat:@"H:[btnCancel(60)]-|" options:0 metrics:nil views:itemsDictionary];
        [_directionInfoView addConstraints:lblDistanceConstraints];
        [_directionInfoView addConstraints:cancelConstraints];
        [_directionInfoView addConstraints:topCancelBtnCon];
        [_directionInfoView addConstraints:_topDistanceLblCon];
        [_directionInfoView layoutIfNeeded];
    }
    else
    {
        _lblDirectionDistance = (UILabel*)[_directionInfoView viewWithTag:100];
    }
    if (_timerDirectionRouteDisplay == nil)
    {
        _timerDirectionRouteDisplay = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                                       target:self
                                                                     selector:@selector(changeDistanceLabel:)
                                                                     userInfo:nil
                                                                      repeats:YES];
        [_timerDirectionRouteDisplay fire];
    }
    else
    {
        [_timerDirectionRouteDisplay fire];
    }
    _directionCurrentDistanceIndex = 0;
    [_lblDirectionDistance setTextColor:_directionRouteColorResultSet[_directionCurrentDistanceIndex]];
    [_lblDirectionDistance setText:[NSString stringWithFormat:@"%@",_directionRouteDistanceResultSet[_directionCurrentDistanceIndex]]];
    id topGuide = self.topLayoutGuide;
    NSDictionary* viewDictionary = NSDictionaryOfVariableBindings(topGuide,_directionInfoView);
    
    //Constraints to put view at right left, (will not use this, I want to put view in center
    //NSArray *constraintsLeft = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[directionInfoView(200)]-|" options:0 metrics:nil views:viewDictionary];
    //[self.view addConstraints:constraintsLeft];
    //Constraint to put in center, this can not be done with VFL, so have to use following two contraitns for both center and width
    
    NSLayoutConstraint* centerConstraint = [NSLayoutConstraint
            constraintWithItem:_directionInfoView
            attribute:NSLayoutAttributeCenterX
            relatedBy:NSLayoutRelationEqual
            toItem:self.view
            attribute:NSLayoutAttributeCenterX
            multiplier:1.0f constant:0.0f];
    [self.view addConstraint:centerConstraint];
    NSLayoutConstraint* widthConstraint = [NSLayoutConstraint
                                            constraintWithItem:_directionInfoView
                                            attribute:NSLayoutAttributeWidth
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:nil
                                            attribute:NSLayoutAttributeNotAnAttribute
                                            multiplier:1.0f constant:300.0f];
    [self.view addConstraint:widthConstraint];
    //Constraints to put view just under navitation bar, using VFL (visual form language)
    NSArray* topConstraints = [NSLayoutConstraint
                   constraintsWithVisualFormat:@"V:[topGuide]-5-[_directionInfoView(70)]" options:0 metrics:nil views:viewDictionary];
       // ######  NOTE: V:|[topGUide]... is wrong, do not need | with top/bottom guide
    [self.view addConstraints:topConstraints];
    [UIView animateWithDuration:0.5
                     animations:^{
                         [self.view layoutIfNeeded];
                     } completion:nil];
    
}


- (void) changeDistanceLabel:(NSTimer*)_timer
{
    if (_lblDirectionDistance != nil)
    {
        NSInteger cnt = [_directionRouteDistanceResultSet count];
        if (_directionCurrentDistanceIndex >= cnt - 1)
            _directionCurrentDistanceIndex = 0;
        else
            _directionCurrentDistanceIndex++;

        [_lblDirectionDistance setTextColor:_directionRouteColorResultSet[_directionCurrentDistanceIndex]];
        [_lblDirectionDistance setText:[NSString stringWithFormat:@"%@",_directionRouteDistanceResultSet[_directionCurrentDistanceIndex]]];
    }
}


- (void) closeDirectionView:(id)sender
{
    if (_directionInfoView != nil)
    {
        [_directionInfoView removeFromSuperview];
        _directionInfoView = nil;

        if (_timerDirectionRouteDisplay != nil)
        {
            [_timerDirectionRouteDisplay invalidate];
            _timerDirectionRouteDisplay = nil;
        }
        [self.mapView removeOverlays:_directionOverlayArray];
    }
}

//Save photo to file. Called by updateEvent after write event to db
//I should put image process functions such as resize/convert to JPEG etc in ImagePickerController
//put it here is because we have to save image here since we only have uniqueId and some other info here
-(void)writePhotoToFile:(NSString*)eventId newAddedList:(NSArray*)newAddedList deletedList:(NSArray*)deletedList photoForThumbNail:(NSString*)photoForThumbnail
{
    NSString *newPhotoTmpDir = [ATHelper getNewUnsavedEventPhotoPath];
    NSString *photoFinalDir = [[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:eventId];
    //TODO may need to check if photo directory with this eventId exist or not, otherwise create as in ATHealper xxxxxx
    if (newAddedList != nil && [newAddedList count] > 0)
    {
        for (NSString* fileName in newAddedList)
        {
            NSString* tmpFileNameForNewPhoto = [NSString stringWithFormat:@"%@%@", NEW_NOT_SAVED_FILE_PREFIX,fileName];
            NSString* newPhotoTmpFile = [newPhotoTmpDir stringByAppendingPathComponent:tmpFileNameForNewPhoto];
            NSString* newPhotoFinalFileName = [photoFinalDir stringByAppendingPathComponent:fileName];
            NSError *error;
            BOOL eventPhotoDirExistFlag = [[NSFileManager defaultManager] fileExistsAtPath:photoFinalDir isDirectory:false];
            if (!eventPhotoDirExistFlag)
                [[NSFileManager defaultManager] createDirectoryAtPath:photoFinalDir withIntermediateDirectories:YES attributes:nil error:&error];
            [[NSFileManager defaultManager] moveItemAtPath:newPhotoTmpFile toPath:newPhotoFinalFileName error:&error];
            //Add to newPhotoQueue for sync to dropbox
            if ([PHOTO_META_FILE_NAME isEqualToString:fileName] )
            {
                BOOL eventPhotoMetaFileExistInQueueFlag = [[self dataController] isItInNewPhotoQueue:[eventId stringByAppendingPathComponent:fileName]];
                if (!eventPhotoMetaFileExistInQueueFlag)
                    [[self dataController] insertNewPhotoQueue:[eventId stringByAppendingPathComponent:fileName]];
            }
            else
                [[self dataController] insertNewPhotoQueue:[eventId stringByAppendingPathComponent:fileName]];
        }
        NSError* error;
        //remove the dir then recreate to clean up this temp dir
        [[NSFileManager defaultManager] removeItemAtPath:newPhotoTmpDir error:&error];
        if (error == nil)
            [[NSFileManager defaultManager] createDirectoryAtPath:newPhotoTmpDir withIntermediateDirectories:YES attributes:nil error:&error];
    }
    NSString* thumbPath = [photoFinalDir stringByAppendingPathComponent:@"thumbnail"];
    if (photoForThumbnail == nil)
    {
        //check if thumbnail exist or not, if not write first photo as thumbnail. This is to make sure there is a thumbnail, for example added the first photo but not select any as a thumbnail yet
        
        BOOL isDir;
        BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:thumbPath isDirectory:&isDir];
        if (!fileExist && newAddedList != nil && [newAddedList count] > 0)
            photoForThumbnail = newAddedList[0];
    }
    if (photoForThumbnail != nil ) //EventEditor must make sure indexForThmbnail is < 0 if no change to thumbNail
    {
        if ([photoForThumbnail hasPrefix:NEW_NOT_SAVED_FILE_PREFIX])
            photoForThumbnail = [photoForThumbnail substringFromIndex:[NEW_NOT_SAVED_FILE_PREFIX length]];//This is the case when user select new added photo as icon
        UIImage* photo = [UIImage imageWithContentsOfFile: [photoFinalDir stringByAppendingPathComponent:photoForThumbnail ]];
        UIImage* thumbImage = [ATHelper imageResizeWithImage:photo scaledToSize:CGSizeMake(THUMB_WIDTH, THUMB_HEIGHT)];
        NSData* imageData = UIImageJPEGRepresentation(thumbImage, JPEG_QUALITY);
        // NSLog(@"---------last write success:%i thumbnail file size=%i",ret, imageData.length);
        [imageData writeToFile:thumbPath atomically:NO];
        
        //touch file to change file order
        /*** not needed. now sort photo is in another way
        NSDate *now = [NSDate date];
        NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys: now, NSFileModificationDate, NULL];
        NSString* photoToTouch = [photoFinalDir stringByAppendingPathComponent:photoForThumbnail];
        [[NSFileManager defaultManager] setAttributes: attr ofItemAtPath: photoToTouch error: NULL];
         */
    }
    if (deletedList != nil && [deletedList count] > 0)
    {
        NSError *error;
        for (NSString* fileName in deletedList)
        {
            NSString* deletePhotoFinalFileName = [photoFinalDir stringByAppendingPathComponent:fileName];
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:deletePhotoFinalFileName];
            //NSLog(@"Path to file: %@", deletePhotoFinalFileName);
            //NSLog(@"File exists: %d", fileExists);
            //NSLog(@"Is deletable file at path: %d", [[NSFileManager defaultManager] isDeletableFileAtPath:deletePhotoFinalFileName]);
            if (fileExists)
            {
                BOOL success = [[NSFileManager defaultManager] removeItemAtPath:deletePhotoFinalFileName error:&error];
                if (!success)
                    NSLog(@"Error: %@", [error localizedDescription]);
                else
                   [[self dataController] insertDeletedPhotoQueue:[eventId stringByAppendingPathComponent:fileName]];
            }
        }
    }
}

-(void)deletePhotoFilesByEventId:(NSString*)eventId
{
    // Find the path to the documents directory
    if (eventId == nil || [eventId length] == 0)
        return;  //Bug fix. This bug is in ver1.0. When remove drop-pin, fileName is empty,so it will remove whole document directory such as myEvents, very bad bug
    NSString *fullPathToFile = [[ATHelper getPhotoDocummentoryPath] stringByAppendingPathComponent:eventId];
    NSError *error;
    NSArray* tmpFileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPathToFile error:&error];
    //all photo files under this event id directory should be removed
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:fullPathToFile error:&error];
    if (success) {
        if (tmpFileList != nil && [tmpFileList count] > 0)
        {
            for (NSString* file in tmpFileList)
            {
                [[self dataController] insertDeletedPhotoQueue:[eventId stringByAppendingPathComponent:file]];
                [[NSFileManager defaultManager] removeItemAtPath:[fullPathToFile stringByAppendingPathComponent:file] error:&error];
            }
            [[self dataController] insertDeletedEventPhotoQueue:eventId];
        }
        NSLog(@"Error removing document path: %@", error.localizedDescription);
    }
}


-(void)calculateSearchBarFrame
{
    int searchBarHeight = [ATConstants searchBarHeight];
    int searchBarWidth = [ATConstants searchBarWidth];
    //[self.navigationItem.titleView setFrame:CGRectMake(0, 0, searchBarWidth, searchBarHeight)];
    //searchBar size on storyboard could not adjust according ipad/iPhone/Orientation
    [self.searchBar setBounds:CGRectMake(0, 0, searchBarWidth, searchBarHeight)];
}
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //NSLog(@"Rodation detected");
    [self displayTimelineControls];
    [self calculateSearchBarFrame]; //in iPhone, make search bar wider in landscape
    [self closeTutorialView];
    if (tutorialStyle != nil)
    {
        tutorialStyle.imageSize = CGSizeMake(300, 600); //for iPad
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
            if (UIDeviceOrientationIsPortrait(orientation))
                tutorialStyle.imageSize = CGSizeMake(80, 160);
            else
                tutorialStyle.imageSize = CGSizeMake(150, 300);
        }
    }
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    [self.searchBar resignFirstResponder];
    MKLocalSearchRequest *request =
    [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = theSearchBar.text;
    request.region = _mapView.region;
    
    if (prevSearchResult == nil)
        prevSearchResult = [[NSMutableArray alloc] init];
    else{
        [_mapView removeAnnotations:prevSearchResult];
        [prevSearchResult removeAllObjects];
    }
    
    MKLocalSearch *search =
    [[MKLocalSearch alloc]initWithRequest:request];
    
    [search startWithCompletionHandler:^(MKLocalSearchResponse
                                         *response, NSError *error) {
        if (response.mapItems.count == 0)
        {
            //NSLog(@"No Matches");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Results",nil) message:NSLocalizedString(@"May be the network is not available",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            for (MKMapItem *item in response.mapItems)
            {
                ATDefaultAnnotation *pa = [[ATDefaultAnnotation alloc] initWithLocation:item.placemark.coordinate];
                pa.eventDate = [NSDate date];
                pa.description=item.name;//@"add by search";
                pa.address = item.placemark.title; //TODO should get from placemarker
                [_mapView addAnnotation:pa];
                [prevSearchResult addObject:pa];
            }
        }
        
        if ([response.mapItems count] == 1)
        {
            MKMapItem* item = response.mapItems[0];
            MKCoordinateRegion region;
            region.center.latitude = item.placemark.coordinate.latitude;
            region.center.longitude = item.placemark.coordinate.longitude;
            MKCoordinateSpan span;
            double radius = item.placemark.region.radius / 1000; // convert to km
            
            //NSLog(@"[searchBarSearchButtonClicked] Radius is %f", radius);
            span.latitudeDelta = radius / 112.0;
            region.span = span;
            [self.mapView setRegion:region animated:YES];
        }
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender {
    if ([segue.identifier isEqualToString:@"preference_id"]) {
        self.preferencePopover = [(UIStoryboardPopoverSegue *)segue popoverController];
    }
    /*if ([segue.identifier isEqualToString:@"iphone_settings"]) {
        [self performSegueWithIdentifier:@"iphone_settings" sender:self]; //preference_storyboard_id
    }*/
}

//This will be called when a callout bulb appear
//There are two way to make annotation callout appear:
//   1) tap annotation on map
//   2) tab an event in event list view
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    //For callout caused by select from Event List View, then do not toggle
    //For callout caused by tap on annotation in map, need to toogle back because tap on annotation will first call tap gesture on mkmapview
    //Again, use regionChangeTimeStart to check: regionChangeTime is long, then must tap on annotation, otherwise, it should be tap on EventListView because it will trigger map scroll
    NSTimeInterval interval = [[[NSDate alloc] init] timeIntervalSinceDate:regionChangeTimeStart];
    if (interval > 0.3)  //When tap on annotation, last map scroll should been at least 0.2 seconds ago.
        [self toggleMapViewShowHideAction];
    
    //when click on annotation, all timewheel/image will flip just as tap on map, so I will flip it back so keep same state as before tap on annotation
    /*
    if (self.mapViewShowWhatFlag == MAPVIEW_SHOW_ALL)
        self.mapViewShowWhatFlag = MAPVIEW_HIDE_ALL;
    else
        self.mapViewShowWhatFlag = MAPVIEW_SHOW_ALL;
*/
    ATEventAnnotation* ann = [view annotation];
    if ([ann isKindOfClass:[ATAnnotationPoi class]])
    {
        [self displayPOIView:view];

    }
}
- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    //[self toggleMapViewShowHideAction];
    
    UIView* poiView = [view viewWithTag:9991];
    if (poiView != nil)
        [poiView removeFromSuperview];
}

- (double)longitudeToPixelSpaceX:(double)longitude
{
    return round(MERCATOR_OFFSET + MERCATOR_RADIUS * longitude * M_PI / 180.0);
}

- (double)latitudeToPixelSpaceY:(double)latitude
{
    return round(MERCATOR_OFFSET - MERCATOR_RADIUS * logf((1 + sinf(latitude * M_PI / 180.0)) / (1 - sinf(latitude * M_PI / 180.0))) / 2.0);
}

- (double)pixelSpaceXToLongitude:(double)pixelX
{
    return ((round(pixelX) - MERCATOR_OFFSET) / MERCATOR_RADIUS) * 180.0 / M_PI;
}

- (double)pixelSpaceYToLatitude:(double)pixelY
{
    return (M_PI / 2.0 - 2.0 * atan(exp((round(pixelY) - MERCATOR_OFFSET) / MERCATOR_RADIUS))) * 180.0 / M_PI;
}
- (MKCoordinateSpan)coordinateSpanWithMapView:(MKMapView *)mapView
                             centerCoordinate:(CLLocationCoordinate2D)centerCoordinate
                                 andZoomLevel:(NSUInteger)zoomLevel
{
    // convert center coordiate to pixel space
    double centerPixelX = [self longitudeToPixelSpaceX:centerCoordinate.longitude];
    double centerPixelY = [self latitudeToPixelSpaceY:centerCoordinate.latitude];
    
    // determine the scale value from the zoom level
    NSInteger zoomExponent = 20 - zoomLevel;
    double zoomScale = pow(2, zoomExponent);
    
    // scale the map’s size in pixel space
    CGSize mapSizeInPixels = mapView.bounds.size;
    double scaledMapWidth = mapSizeInPixels.width * zoomScale;
    double scaledMapHeight = mapSizeInPixels.height * zoomScale;
    
    // figure out the position of the top-left pixel
    double topLeftPixelX = centerPixelX - (scaledMapWidth / 2);
    double topLeftPixelY = centerPixelY - (scaledMapHeight / 2);
    
    // find delta between left and right longitudes
    CLLocationDegrees minLng = [self pixelSpaceXToLongitude:topLeftPixelX];
    CLLocationDegrees maxLng = [self pixelSpaceXToLongitude:topLeftPixelX + scaledMapWidth];
    CLLocationDegrees longitudeDelta = maxLng - minLng;
    
    // find delta between top and bottom latitudes
    CLLocationDegrees minLat = [self pixelSpaceYToLatitude:topLeftPixelY];
    CLLocationDegrees maxLat = [self pixelSpaceYToLatitude:topLeftPixelY + scaledMapHeight];
    CLLocationDegrees latitudeDelta = -1 * (maxLat - minLat);
    
    // create and return the lat/lng span
    MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    return span;
}

- (void) loadEpisode:(NSString *)episodeName
{
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* episodeDictionary = [[userDefault objectForKey:[ATConstants EpisodeDictionaryKeyName]] mutableCopy];
    
    if (episodeDictionary != nil)
        eventEpisodeList = [[episodeDictionary objectForKey:episodeName] mutableCopy];
    episodeNameforUpdating = episodeName;
    [self refreshAnnotations];
    
    CLLocationCoordinate2D centerCoordinate;

    NSArray* evtList = [ATHelper getEventListWithUniqueIds:eventEpisodeList];
    if ([evtList count] == 0)
        return;
    ATEventDataStruct* evt = evtList[0];
    centerCoordinate.latitude = evt.lat;
    centerCoordinate.longitude = evt.lng;
    MKCoordinateSpan span = self.mapView.region.span;
    MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
    
    // set the region like normal
    [self.mapView setRegion:region animated:YES];
    [self startEpisodeView];
    
}

- (void) refreshEventListView:(BOOL)callFromScrollTimewheel
{
    if (callFromScrollTimewheel && switchEventListViewModeToVisibleOnMapFlag)
        return; //while in map eventListView mode, move timewheel will call this function as well, but do nothing. eventListInVisibleMapArea is set to nil in switch button action
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDelegate.selectedPeriodInDays == 0)
    {
        NSLog(@" ##### 0 case");
        return; //TODO add this because call updateEventListViewWithPoiOnMapOnly() in regionDid.. will crash when start app
    }
    int offset = 110;
    //try to move evetlistview to right side screenWidht - eventListViewCellWidth, but a lot of trouble, not know why
    //  even make x to 30, it will move more than 30, besides, not left side tap works
    CGRect newFrame = eventListView.frame; // CGRectMake(0,offset,0,0);
    unsigned long numOfCellOnScreen = 0;
    
    NSMutableArray* eventListViewList = nil;
    
    if (switchEventListViewModeToVisibleOnMapFlag == false) //it means eventlistView will show events inside timewheel period
    {
        NSDictionary* scaleDateDic = [ATHelper getScaleStartEndDate:appDelegate.focusedDate];
        NSDate* scaleStartDay = [scaleDateDic objectForKey:@"START"];
        NSDate* scaleEndDay = [scaleDateDic objectForKey:@"END"];
        
        if ([self.startDate compare:scaleStartDay] == NSOrderedDescending)
            scaleStartDay = self.startDate;
        if ([self.endDate compare:scaleEndDay] == NSOrderedAscending)
            scaleEndDay = self.endDate;
        //NSLog(@" === scaleStartDate = %@,  scaleEndDay = %@", scaleStartDay, scaleEndDay);
        NSArray* allEventSortedList = appDelegate.eventListSorted;
        
        eventListViewList = [[NSMutableArray alloc] init];

        NSInteger cnt = [allEventSortedList count];
        if (cnt == 0 && (eventListInVisibleMapArea == nil || [eventListInVisibleMapArea count] == 0) )
        {
            [eventListView setFrame:newFrame];
            [eventListView.tableView setFrame:newFrame];
            [eventListView refresh:eventListViewList: switchEventListViewModeToVisibleOnMapFlag :callFromScrollTimewheel];
            return;
        }
        ATEventDataStruct* latestEvent = allEventSortedList[0];
        ATEventDataStruct* earlistEvent = allEventSortedList[cnt -1];
        
        //case special: where startDate/EndDate range is totally outside the event date range, or even no event at all
        if (([scaleStartDay compare:latestEvent.eventDate] == NSOrderedDescending || [scaleEndDay compare: earlistEvent.eventDate] == NSOrderedAscending)
            &&  (eventListInVisibleMapArea == nil || [eventListInVisibleMapArea count] == 0) )
        {
            [eventListView setFrame:newFrame];
            [eventListView.tableView setFrame:newFrame];
            [eventListView refresh: eventListViewList :switchEventListViewModeToVisibleOnMapFlag :callFromScrollTimewheel];
            return;
        }
        //come here when there start/end date range has intersect with allEventSorted
        BOOL completeFlag = false;
        unsigned long insertStartPosition = 0;
        if  (eventListInVisibleMapArea != nil && [eventListInVisibleMapArea count] > 0)
        {
            [eventListViewList addObjectsFromArray:eventListInVisibleMapArea];
            insertStartPosition = [eventListInVisibleMapArea  count];
        }
        for (int i=0; i<cnt;i++)
        {
            ATEventDataStruct* evt = allEventSortedList[i];
            if ([self date:evt.eventDate isBetweenDate :scaleStartDay andDate:scaleEndDay])
            {
                [eventListViewList insertObject:evt atIndex:insertStartPosition]; //so event will order by date in regular sequence
                completeFlag = true;
            }
            else
            {
                if (completeFlag == true)
                    break; //this is a trick to enhance performance. Do not continues because all in range has been added
            }
        }
    }
    else
    {
        NSArray *sortedArray;
        sortedArray = [eventListInVisibleMapArea sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSDate *first = [(ATEventEntity*)a eventDate];
            NSDate *second = [(ATEventEntity*)b eventDate];
            BOOL ret = [first compare:second]== NSOrderedDescending;
            if ([first compare:second] == NSOrderedSame) //for same date event, compare desc. This is good for itinary planning Day 1.1, Day 1.2 etc
            {
                NSString *firstDesc = [(ATEventEntity*)a eventDesc];
                NSString *secondDesc = [(ATEventEntity*)b eventDesc];
                ret = [firstDesc compare:secondDesc]== NSOrderedDescending;
            }
            return ret;
        }];
        
        eventListViewList = (NSMutableArray*)sortedArray;
        
    }

    //above logic will remain startDateIdx/endDateIdx to be -1 if no events
    unsigned long cnt = [eventListViewList count]; //Inside ATEventListWindow, this will add two rows for arrow button, one at top, one at bottom
    if (cnt > 0)
    {
        numOfCellOnScreen = cnt;
        if (cnt > [ATConstants eventListViewCellNum])
            numOfCellOnScreen = [ATConstants eventListViewCellNum];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
            CGRect newBtnFrame = switchEventListViewModeBtn.frame;
            UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
            if (UIDeviceOrientationIsPortrait(orientation))
            {
                offset = offset - 10;
                newBtnFrame = CGRectMake(newBtnFrame.origin.x, 66, newBtnFrame.size.width, newBtnFrame.size.height);
            }
            else
            {
                offset = offset - 20;
                newBtnFrame = CGRectMake(newBtnFrame.origin.x, 58, newBtnFrame.size.width, newBtnFrame.size.height);
            }
            [switchEventListViewModeBtn setFrame:newBtnFrame];
        }
    }
    newFrame = CGRectMake(newFrame.origin.x ,offset,[ATConstants eventListViewCellWidth],numOfCellOnScreen * [ATConstants eventListViewCellHeight]);
    /////xxxx
    /*
    self.timeScrollWindow.hidden=false;
    self.timeZoomLine.hidden = false;
     */
    [self showDescriptionLabelViews:self.mapView];
    /////xxxxxx     self.navigationController.navigationBarHidden = false;
    
    
    //important Tricky: bottom part of event list view is not clickable, thuse down arrow button always not clickable, add some height will works
    CGRect aaa = newFrame;
    aaa.size.height = aaa.size.height + 100; //Very careful: if add too much such as 500, it seems work, but left side of timewheel will click through when event list view is long. adjust this value to test down arrow button and left side of timewheel
    [eventListView setFrame:aaa];
    
    [eventListView.tableView setFrame:CGRectMake(0,0,newFrame.size.width,newFrame.size.height)];
    if (eventListViewList != nil)
        [eventListView refresh: eventListViewList :switchEventListViewModeToVisibleOnMapFlag :callFromScrollTimewheel];
}

- (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate
{
    if ([date compare:beginDate] == NSOrderedAscending)
        return NO;
    
    if ([date compare:endDate] == NSOrderedDescending)
        return NO;
    
    return YES;
}

@end
