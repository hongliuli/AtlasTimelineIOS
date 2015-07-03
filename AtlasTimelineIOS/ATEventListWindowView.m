//
//  ATEventListViewController.m
//  AtlasTimelineIOS
//
//  Created by Hong on 6/1/14.
//  Copyright (c) 2014 hong. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ATEventListWindowView.h"
#import "ATViewController.h"
#import "ATAppDelegate.h"
#import "ATEventDataStruct.h"
#import "ATHelper.h"
#import "ATConstants.h"
#import "ATEventListViewCell.h"
#import "ATEventListViewPoiCell.h"

#define EVENT_TYPE_NO_PHOTO 0
#define EVENT_TYPE_HAS_PHOTO 1

#define MAPVIEW_HIDE_ALL 1
#define MAPVIEW_SHOW_PHOTO_LABEL_ONLY 2

@implementation ATEventListWindowView

NSArray* internalEventList;
BOOL isAtLeast7;

BOOL eventListViewInMapModeFlag;

NSDateFormatter *dateFormatter;

UIColor *greyColor;
UIFont *boldFont;
NSString* selectedPOIEventId;

- (id)initWithFrame:(CGRect)frame
{
    if (self == [super initWithFrame:frame])
    {
        NSString *version = [[UIDevice currentDevice] systemVersion];
        isAtLeast7 = [version compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending;
        
        internalEventList = [[NSArray alloc] init];
        self.tableView = [[UITableView alloc] initWithFrame:frame];
        
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        
        [self addSubview:self.tableView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        tap.numberOfTapsRequired =1;
        [self.tableView addGestureRecognizer:tap]; //IMPORTANT: I used [self addGest..] which cause sometime tap on a row does not react. After chage to self.tableView addGest.., it works much better
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        
        greyColor=[UIColor darkGrayColor];
        boldFont=[UIFont fontWithName:@"Arial-BoldMT" size:13];
    }
    return self;
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [internalEventList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@" ===== cellForRow %d  internalList count %d ",indexPath.row, [internalEventList count]);
    
    ATEventDataStruct* evt = internalEventList[indexPath.row];
    //REMEMBER internalEventList has added row to first and last for arrow button (code refresh() method to add two rows
    /* Do not show up-down arrow
    if (indexPath.row == 0) // first one is up arrow
    {
        UITableViewCell* cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, [ATConstants eventListViewCellWidth], 40)];
        if ([self shouldHideArrowButtonRow:indexPath.row])
            return cell;
        cell.selectionStyle = UITableViewCellStyleDefault;
        if (!eventListViewInMapModeFlag)
        {
            CGRect imageFrame = CGRectMake([ATConstants eventListViewCellWidth]/2 - 50, 10, 100, 40);
            UIImageView* upArrow = [[UIImageView alloc] initWithFrame:imageFrame];
            [upArrow setImage:[UIImage imageNamed:@"arrow-up-icon.png"]];
            [cell.contentView addSubview:upArrow]; //gotoPrevEventAction is hadled by didSelected...
        }
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.backgroundColor= [UIColor clearColor];
        return cell;
    }
    if (indexPath.row == [internalEventList count] - 1) //last one is down arrow
    {
        UITableViewCell* cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, [ATConstants eventListViewCellWidth], 40)];
        if ([self shouldHideArrowButtonRow:indexPath.row])
            return cell;
        cell.selectionStyle = UITableViewCellStyleDefault;
        if (!eventListViewInMapModeFlag)
        {
            CGRect imageFrame = CGRectMake([ATConstants eventListViewCellWidth]/2 - 50, -5, 100, 40);
            UIImageView* downArrow = [[UIImageView alloc] initWithFrame:imageFrame];
            [downArrow setImage:[UIImage imageNamed:@"arrow-down-icon.png"]];
            [cell.contentView addSubview:downArrow];
        }
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.backgroundColor= [UIColor clearColor];
        return cell;
    }
    */
    
    NSString* dateStr = [dateFormatter stringFromDate:evt.eventDate];
    NSString* descStr = evt.eventDesc;
    if ([descStr length] > 150)
    {
        descStr = [evt.eventDesc substringToIndex:150];
    }
    NSString* titleStr = @"";
    NSString* descToDisplay = [NSString stringWithFormat:@"%@\n%@",dateStr, descStr ];


    if ([ATHelper isPOIEvent:evt])
    {
        ATEventListViewPoiCell* cellPoi = (ATEventListViewPoiCell*)[tableView dequeueReusableCellWithIdentifier:@"PoiCell"];
        if (cellPoi == nil)
        {
            cellPoi = [[ATEventListViewPoiCell alloc] initWithFrame:CGRectMake(0, 0, [ATConstants eventListViewCellWidth], [ATConstants eventListViewCellHeight])];
            cellPoi.eventDescView.font = [UIFont fontWithName:@"Arial-BoldMT" size:15];
            
            cellPoi.selectionStyle = UITableViewCellStyleDefault;
            [cellPoi.layer setCornerRadius:7.0f];
            [cellPoi.layer setMasksToBounds:YES];
            [cellPoi.layer setBorderWidth:1.0f];
            [cellPoi.layer setBorderColor:[UIColor lightGrayColor].CGColor];
            

            NSUInteger titleEndLocation = [descStr rangeOfString:@"\n"].location;
            if (titleEndLocation == NSNotFound)
                titleStr = descStr;
            else
                titleStr = [descStr substringToIndex:titleEndLocation];
            cellPoi.eventDescView.text = titleStr;
            [cellPoi.checkIcon setHidden:true];
        }
        if ([evt.uniqueId isEqualToString:selectedPOIEventId])
        {
            [cellPoi setBackgroundColor:[UIColor colorWithRed:0.7 green:0.7 blue:0.9 alpha:0.7]];
            [cellPoi.checkIcon setHidden:false];
        }
        else
            [cellPoi setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:1.0 alpha:0.7]];
        UIImageView* iconView = (UIImageView*) [cellPoi viewWithTag:9999]; //modify that from parent
        [iconView setFrame:CGRectMake(2, 2, 65, 50)];
        [iconView setImage:[ATHelper readPhotoFromFile:evt.uniqueId eventId:evt.uniqueId]];
        //[iconView setImage:[ATHelper readPhotoThumbFromFile:evt.uniqueId]];
        return cellPoi;
    }
    
    NSString* cellType = @"redBoardCell";
    UIColor* boarderColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.2];
    if (eventListViewInMapModeFlag)
    {
        cellType = @"blueBoardCell";
        boarderColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.2];
    }
    
    ATEventListViewCell* cell = (ATEventListViewCell*)[tableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil)
    {
        cell = [[ATEventListViewCell alloc] initWithFrame:CGRectMake(0, 0, [ATConstants eventListViewCellWidth], [ATConstants eventListViewCellHeight])];
        cell.eventDescView.font = [UIFont fontWithName:@"Arial" size:13];
        
        cell.selectionStyle = UITableViewCellStyleDefault;
        [cell.layer setCornerRadius:7.0f];
        [cell.layer setMasksToBounds:YES];
        [cell.layer setBorderWidth:1.0f];
        [cell.layer setBorderColor:boarderColor.CGColor];
        cell.contentView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.7];
        //cell.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.7];
        //[cell.layer setBorderColor:(__bridge CGColorRef)([UIColor lightGrayColor])];
    }
    
    NSMutableAttributedString *attString=[[NSMutableAttributedString alloc] initWithString:descToDisplay];
    [attString addAttribute:NSForegroundColorAttributeName value:greyColor range:NSMakeRange(0, [dateStr length])];
    
    NSUInteger titleEndLocation = [descStr rangeOfString:@"\n"].location;
    if (titleEndLocation < 80 && titleEndLocation > 0) //title is in file as [Desc]xxx yyy zzzz\n
    {
        titleStr = [descStr substringToIndex:titleEndLocation];
        descStr = [descStr substringFromIndex:titleEndLocation];
        descToDisplay = [NSString stringWithFormat:@"%@\n%@%@", dateStr,titleStr, descStr ];
        attString=[[NSMutableAttributedString alloc] initWithString:descToDisplay];
        NSUInteger dateStrLen = [dateStr length];
        [attString addAttribute:NSForegroundColorAttributeName value:greyColor range:NSMakeRange(0, dateStrLen)];
        [attString addAttribute:NSFontAttributeName value:boldFont range:NSMakeRange(dateStrLen, [titleStr length] + 1)];
    }
    
    //dateStr = [dateStr substringToIndex:10];
    cell.eventDescView.attributedText = attString;
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    ATEventDataStruct* focusedEvent = appDelegate.focusedEvent;
    if (focusedEvent != nil && [focusedEvent.uniqueId isEqual:evt.uniqueId])
    {
        [cell.checkIcon setHidden:false];
        cell.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.40];
    }
    else
    {
        [cell.checkIcon setHidden:true];
        cell.backgroundColor = [UIColor clearColor];
    }
    
    if (evt.eventType == EVENT_TYPE_HAS_PHOTO && isAtLeast7) //excusionPaths is available only after 7
    {
        CGRect imageFrame = CGRectMake(0, 0, [ATConstants eventListViewPhotoWidht] - 2,[ATConstants eventListViewPhotoHeight] - 5);
        cell.photoImage.image = [ATHelper readPhotoThumbFromFile:evt.uniqueId];
        
        UIBezierPath * imgRect = [UIBezierPath bezierPathWithRect:imageFrame];
        cell.eventDescView.textContainer.exclusionPaths = @[imgRect];
    }
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    /* Do not show up-down arrow
    if (indexPath.row == 0 || indexPath.row == [internalEventList count] - 1)
    {
        //Do not show arrow button if reach last or begin of events
        if ([self shouldHideArrowButtonRow:indexPath.row] || eventListViewInMapModeFlag)
            return 0;
        else
            return 40;
    }
    else
     */
    {
        ATEventDataStruct* evt = internalEventList[indexPath.row];
        if ([ATHelper isPOIEvent:evt])
            return 50;
        else
        return [ATConstants eventListViewCellHeight];
    }
}

- (BOOL) shouldHideArrowButtonRow:(int)row
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    ATEventDataStruct* firstEvt = internalEventList[1];
    ATEventDataStruct* lastEvt = internalEventList[[internalEventList count] - 2];
    int globalIdxFirst = [appDelegate.eventListSorted indexOfObject:firstEvt];
    int globalIdxLast = [appDelegate.eventListSorted indexOfObject:lastEvt];
    return ((globalIdxFirst == [appDelegate.eventListSorted count] - 1 &&  row == 0) ||
            (globalIdxLast == 0 && row == [internalEventList count] - 1));
}
//have tap gesture achive two thing: prevent call tapGesture on parent mapView and process select a row action without a TableViewController
- (void)handleTapGesture:(UIGestureRecognizer *)gestureRecognizer
{
    //NSLog(@" ----- tap");
    if ([gestureRecognizer numberOfTouches] == 1)
    {
        NSIndexPath *index = [self.tableView indexPathForRowAtPoint: [gestureRecognizer locationInView:self.tableView]];
        //NSLog(@"   row clicked on is %i", index.row);
        [self didSelectRowAtIndexPath:index];
    }
}
- (void) didSelectRowAtIndexPath:(NSIndexPath *)indexPath  //called by tapGesture. This is not in a TableViewController, so no didSelect... delegate mechanism, have to process  by tap gesture
{
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    ATViewController* mapView = appDelegate.mapViewController;
    ATEventDataStruct* evt = internalEventList[indexPath.row];
    
    /* Do not show up-down arrow
    if (indexPath.row == 0) //tapped on up arrow button
    {
        //NSLog(@"******* up arrow, find previouse event to scroll to");
        ATEventDataStruct* firstEvt = internalEventList[1];
        int globalIdx = [appDelegate.eventListSorted indexOfObject:firstEvt];
        evt = appDelegate.eventListSorted[globalIdx + 1]; //no need to check range here
        [mapView showTimeLinkOverlay];
        [mapView setNewFocusedDateAndUpdateMapWithNewCenter : evt :-1]; //do not change map zoom level
        [mapView refreshEventListView:false];
    }
    else if (indexPath.row == [internalEventList count] - 1)
    {
        //NSLog(@"******* down arrow, find next event");
        ATEventDataStruct* lastEvt = internalEventList[[internalEventList count] -2];//Minus 2 because the -1 is a dummy row for arrow
        int globalIdx = [appDelegate.eventListSorted indexOfObject:lastEvt];
        evt = appDelegate.eventListSorted[globalIdx -1]; //no need to check range here
        [mapView showTimeLinkOverlay];
        [mapView setNewFocusedDateAndUpdateMapWithNewCenter : evt :-1]; //do not change map zoom level
        [mapView refreshEventListView:false];
    }
    else
     */
    { //Do not change focused event for up/down arrow cause
        
        appDelegate.focusedDate = evt.eventDate;
        appDelegate.focusedEvent = evt;  //appDelegate.focusedEvent is added when implement here
        int zoomLeve = [mapView zoomLevel];
        if ([mapView zoomLevel] < 5)
            zoomLeve = 5;
        [mapView setNewFocusedDateAndUpdateMapWithNewCenter : evt :zoomLeve]; //do not change map zoom level
        [self.tableView reloadData]; //so show checkIcon for selected row
        [mapView showTimeLinkOverlay];

        selectedPOIEventId = evt.uniqueId;
        
        //bookmark selected event
        if (![ATHelper isPOIEvent:evt])
        {
            NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
            int idx = [appDelegate.eventListSorted indexOfObject:evt];
            [userDefault setObject:[NSString stringWithFormat:@"%d",idx ] forKey:@"BookmarkEventIdx"];
            [userDefault synchronize];
        }
    }
    
}

- (void) refresh:(NSArray*)eventList :(BOOL)eventListViewInMapModeFlagArg :(BOOL)callFromTimewheel //called by mapview::refreshEventListView()
{
    eventListViewInMapModeFlag = eventListViewInMapModeFlagArg;
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
    /* Do not show up-down arrow
    [eventList addObject:[[ATEventDataStruct alloc] init]];
    [eventList insertObject:[[ATEventDataStruct alloc] init] atIndex:0];
     */
    internalEventList = eventList;
    [self.tableView reloadData];
    [self.tableView layoutIfNeeded]; //must have for following work
    if (appDelegate.focusedEvent == nil)
        return;
    /* Do not show up-down arrow
    int selectedEventIdx = 1; //previouse is 0. after add Up/Down arrow cell, change to 1 is better
    for (int i=1; i< [eventList count] - 1; i++)
     */
    int selectedEventIdx = 0;
    for (int i=0; i< [eventList count]; i++)
    {
        ATEventDataStruct* evt = eventList[i];
        if ([evt.uniqueId isEqual:appDelegate.focusedEvent.uniqueId])
        {
            selectedEventIdx = i;
            break;
        }
    }
    if (selectedEventIdx < [internalEventList count] && callFromTimewheel)
        [self.tableView scrollToRowAtIndexPath: [NSIndexPath indexPathForRow:selectedEventIdx inSection:0]
                              atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}
/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

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
