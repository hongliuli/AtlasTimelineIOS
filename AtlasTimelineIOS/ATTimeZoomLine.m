//
//  ATTimeZoomLine.m
//  AtlasTimelineIOS
//
//  Created by Hong on 2/12/13.
//  Copyright (c) 2013 hong. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "ATTimeZoomLine.h"
#import "ATAppDelegate.h"
#import "ATHelper.h"
#import "ATConstants.h"
#import "ATEventDataStruct.h"
#import "ATTimeScrollWindowNew.h"
#import "Toast+UIView.h"

#define MOVABLE_VIEW_HEIGHT 4
#define SCREEN_WIDTH ((([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) || ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown)) ? [[UIScreen mainScreen] bounds].size.width : [[UIScreen mainScreen] bounds].size.height)

@implementation ATTimeZoomLine

UIImageView* timeScaleImageView;
//UILabel* labelScaleText;
UILabel* label1;
UILabel* label2;
UILabel* label3;
UILabel* label4;
UILabel* label5;
UILabel* labelSeg1;
UILabel* labelSeg2;
UILabel* labelSeg3;
UILabel* labelSeg4;

static int toastFirstTimeDelay = 0;

UILabel* labelScaleText;
UILabel* labelDateText;
UILabel* labelDateMonthText;

NSCalendar *calendar;
NSDateFormatter *dateLiterFormat;

NSDate* mStartDateFromParent;
NSDate* mEndDateFromParent;

double frameWidth;
CGContextRef context;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        frameWidth = frame.size.width;
        // Initialization code
        timeScaleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(frame.size.width/2 - 45, -10, 90, MOVABLE_VIEW_HEIGHT)];
        [timeScaleImageView setImage:[UIImage imageNamed:@"TimeScaleBar700.png"]];
        timeScaleImageView.contentMode = UIViewContentModeScaleToFill; // UIViewContentModeScaleAspectFill;
        timeScaleImageView.clipsToBounds = YES;
                
        /*
        self.zoomLabel.backgroundColor = [UIColor colorWithRed:1 green:1 blue:0.8 alpha:1 ];
        self.zoomLabel.font=[UIFont fontWithName:@"Helvetica" size:13];
        self.zoomLabel.layer.borderColor=[UIColor orangeColor].CGColor;
        self.zoomLabel.layer.borderWidth=1;
        self.zoomLabel.textAlignment = UITextAlignmentCenter;
        //self.zoomLabel.backgroundColor =
        self.zoomLabel.layer.cornerRadius = 5;
        */

        label1 = [[UILabel alloc] initWithFrame:CGRectMake(-10, -15, 70, 15)];
        
        label2 = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width/4 - 25, -15, 70, 15)];
        
        label3 = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width/2 - 25, -15, 70, 15)];
        
        label4 = [[UILabel alloc] initWithFrame:CGRectMake(3*frame.size.width/4 - 25, -15, 70, 15)];
        
        label5 = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - 25, -15, 70, 15)];

        int segLabelShift = 70;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            segLabelShift = 40;

        
        [self addSubview:timeScaleImageView];
        [self addSubview:label1];
        [self addSubview:label2];
        [self addSubview:label3];
        [self addSubview:label4];
        [self addSubview:label5];
        
        labelSeg1 = [[UILabel alloc] initWithFrame:CGRectMake(segLabelShift, -5, 70, 15)];
        labelSeg1.backgroundColor = [UIColor clearColor];
        labelSeg1.textColor = [UIColor blueColor];
        labelSeg1.font=[UIFont fontWithName:@"Helvetica" size:11];
        [self addSubview:labelSeg1];
        labelSeg2 = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width/4 + segLabelShift, -5, 70, 15)];
        labelSeg2.backgroundColor = [UIColor clearColor];
        labelSeg2.textColor = [UIColor blueColor];
        labelSeg2.font=[UIFont fontWithName:@"Helvetica" size:11];
        [self addSubview:labelSeg2];
        labelSeg3 = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width/2 + segLabelShift, -5, 70, 15)];
        labelSeg3.backgroundColor = [UIColor clearColor];
        labelSeg3.textColor = [UIColor blueColor];
        labelSeg3.font=[UIFont fontWithName:@"Helvetica" size:11];
        [self addSubview:labelSeg3];
        labelSeg4 = [[UILabel alloc] initWithFrame:CGRectMake(3*frame.size.width/4 + segLabelShift, -5, 70, 15)];
        labelSeg4.backgroundColor = [UIColor clearColor];
        labelSeg4.textColor = [UIColor blueColor];
        labelSeg4.font=[UIFont fontWithName:@"Helvetica" size:11];
        [self addSubview:labelSeg4];
        
        dateLiterFormat=[[NSDateFormatter alloc] init];
        [dateLiterFormat setDateFormat:@"EEEE MMMM dd"];
        
        //add the at front
        
        labelScaleText = [[UILabel alloc] initWithFrame:CGRectMake(-30,15, 10, 10)]; //if enlarge it, it will show all text inside, but I think not need.
        labelScaleText.backgroundColor = [UIColor yellowColor ];
        labelScaleText.font=[UIFont fontWithName:@"Helvetica" size:13];
        labelScaleText.layer.borderColor=[UIColor yellowColor].CGColor;
        labelScaleText.layer.borderWidth=1;
        labelScaleText.layer.shadowColor = [UIColor blackColor].CGColor;
        labelScaleText.layer.shadowOffset = CGSizeMake(5,5);
        labelScaleText.layer.shadowOpacity = 1;
        labelScaleText.layer.shadowRadius = 8.0;
        labelScaleText.clipsToBounds = NO;
        labelScaleText.layer.cornerRadius = 8;
        labelScaleText.numberOfLines = 0;
        labelScaleText.textAlignment = UITextAlignmentCenter;
        [self addSubview:labelScaleText];
        labelScaleText.hidden=true;
        labelScaleText.center = timeScaleImageView.center;
        
        //UIWindow* theWindow = [[UIApplication sharedApplication] keyWindow];
        //UIViewController* rvc = theWindow.rootViewController;
        

        //Following xCenter numbers is based on test, if some number even make program crash when change orenation
        int deviceDeltaLandscape = 0;
        int deviceDeltaPortrait = 0;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
            deviceDeltaLandscape = 50;
            deviceDeltaPortrait = -100;
        }
        int xCenter = SCREEN_WIDTH/2 -45;//self.mapViewController.timeScrollWindow.center.x;
        xCenter = [ATConstants screenWidth]/2 -45 + deviceDeltaLandscape;
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
            xCenter = SCREEN_WIDTH/2 - 17 - deviceDeltaPortrait;
        //for Retina landscape iPhone5, need special adjust
        
        CGRect screenRect = [[UIScreen mainScreen] applicationFrame];

        if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0)
            && UIInterfaceOrientationIsLandscape(interfaceOrientation)
            && screenRect.size.height == 568) //to see if it is iPhone5 width
            xCenter = xCenter -43;
        labelDateText = [[UILabel alloc] initWithFrame:CGRectMake(xCenter,200, 80, 80)];
        labelDateText.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:1.0 alpha:0.5 ];
        labelDateText.font=[UIFont fontWithName:@"Helvetica-bold" size:24];
        labelDateText.layer.borderColor=[UIColor grayColor].CGColor;
        labelDateText.layer.borderWidth=1;
        labelDateText.layer.shadowColor = [UIColor blackColor].CGColor;
        labelDateText.layer.shadowOffset = CGSizeMake(100,100);
        labelDateText.layer.shadowOpacity = 1;
        labelDateText.layer.shadowRadius = 40.0;
        labelDateText.layer.cornerRadius = 40;
        labelDateText.textAlignment = UITextAlignmentCenter;
        //Puposely comment out    [self addSubview:labelDateText];
        [self addSubview:labelDateText];
        
        labelDateMonthText = [[UILabel alloc] initWithFrame:CGRectMake(xCenter,240, 40, 40)];
        labelDateMonthText.backgroundColor = [UIColor clearColor];
        labelDateMonthText.font=[UIFont fontWithName:@"Helvetica" size:20];
        labelDateMonthText.textColor = [UIColor grayColor];
        labelDateMonthText.layer.borderColor=[UIColor clearColor].CGColor;
        labelDateMonthText.layer.borderWidth=0;
        labelDateMonthText.textAlignment = UITextAlignmentCenter;
        //Puposely comment out    [self addSubview:labelDateText];
        [self addSubview:labelDateMonthText];
        

        labelDateText.center = CGPointMake(xCenter, 0);// timeScaleImageView.center;
        labelDateMonthText.center = CGPointMake(xCenter, 20);// timeScaleImageView.center;

        
    }
    return self;
}

//called in ATViewController
- (void) changeScaleText:(NSString *)text
{
    labelScaleText.text = @"";
}
- (void) changeDateText:(NSString *)yearText :(NSString*)monthText
{
    labelDateText.text = yearText;
    labelDateMonthText.text = monthText;
}
//called by outside when scrollWindow start/stop, or when change time zoom
- (void)showHideScaleText:(BOOL)showFlag
{
    labelScaleText.hidden = !showFlag;
    labelDateText.hidden = !showFlag;
    labelDateMonthText.hidden = !showFlag;
}

//have to call this after set text otherwise sizeToFit will not work
- (void) fitSzie:(UILabel*)label
{
    UIColor* bgColor = [UIColor colorWithRed:0.3 green:0.1 blue:0.1 alpha:0.5 ];
    label.backgroundColor = bgColor;
    label.textColor = [UIColor whiteColor];
    label.font=[UIFont fontWithName:@"Helvetica-Bold" size:13];
    label.textAlignment = UITextAlignmentCenter;
    label.layer.cornerRadius = 5;
    label.layer.borderColor = [UIColor brownColor].CGColor;
    label.layer.borderWidth = 1;
    
    [label sizeToFit];
    
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    int x = CGRectGetMaxX(rect);
    int y = CGRectGetMaxY(rect);

    context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);

    CGContextSetLineWidth(context, 1.0);
    // Draw the base. 
    CGContextMoveToPoint(context, 0,y);
    CGContextAddLineToPoint(context, x, y);
    
    //Draw 1st line at left-most
    CGContextMoveToPoint(context, 0,0);
    CGContextAddLineToPoint(context, 0, y);
    //draw 2nd
    CGContextMoveToPoint(context, x/4,0);
    CGContextAddLineToPoint(context, x/4, y);
    //draw 3rd (middle)
    CGContextMoveToPoint(context, x/2,0);
    CGContextAddLineToPoint(context, x/2, y);
    //draw 4nd
    CGContextMoveToPoint(context, 3*x/4,0);
    CGContextAddLineToPoint(context, 3*x/4, y);
    //Draw last line at right most
    CGContextMoveToPoint(context, x,0);
    CGContextAddLineToPoint(context, x, y); 
    
    CGContextStrokePath(context);
    [self drawEventDotsBySpan];
    

}

//this will be called when add/modify ends event, so it is actually called inside setTimeScrollConfiguration()
- (void)changeScaleLabelsDateFormat:(NSDate*)startDay :(NSDate*)endDay
{
    NSTimeInterval interval = [endDay timeIntervalSinceDate: startDay];
    int dayInterval = interval/86400;
    double timeSpanInDay = dayInterval;
    float tmp = 0.0;
    int timeSegment = 0;
    NSString* timeSegmentUnit = nil;
    if (timeSpanInDay < 121)
    {
        tmp = timeSpanInDay/4;
        timeSegment = timeSpanInDay/4;
        timeSegmentUnit = @"days";
    }
    else if (timeSpanInDay < 365*4)
    {
        tmp = timeSpanInDay/120;
        timeSegment = timeSpanInDay/120; //divide 30 and 4
        timeSegmentUnit=@"months";
    }
    else
    {
        tmp = (timeSpanInDay/365)/4;
        timeSegment = (timeSpanInDay/365)/4;
        timeSegmentUnit=@"years";
    }
    NSString* plusSign=@"";
    if (tmp - timeSegment >0.3)
        plusSign=@"+";
    labelSeg1.text = [NSString stringWithFormat:@"%i%@ %@",timeSegment,plusSign,timeSegmentUnit];
    labelSeg2.text = [NSString stringWithFormat:@"%i%@ %@",timeSegment,plusSign,timeSegmentUnit];
    labelSeg3.text = [NSString stringWithFormat:@"%i%@ %@",timeSegment,plusSign,timeSegmentUnit];
    labelSeg4.text = [NSString stringWithFormat:@"%i%@ %@",timeSegment,plusSign,timeSegmentUnit];
    
    if (calendar == nil)
        calendar = [NSCalendar currentCalendar];
    
    NSString* yearPart;
    if (timeSpanInDay <= 30)
    {
        label1.hidden = true;
        label2.hidden = true;
        label3.hidden = true;
        label4.hidden = true;
        label5.hidden = true;
        return;
    }
    else
    {
        label1.hidden = false;
        label2.hidden = false;
        label3.hidden = false;
        label4.hidden = false;
        label5.hidden = false;
    }
    NSDate* tmpDate = startDay;

    NSDateComponents *dateComponent = [[NSDateComponents alloc] init];
    if (timeSpanInDay > 30 && timeSpanInDay <=365) //show Label as 01/02/2013
    {
        label1.text = [NSString stringWithFormat:@" %@ ", [ATHelper getMonthDateInTwoNumber:tmpDate]];
                       
        dateComponent.day = timeSpanInDay/4;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        label2.text = [NSString stringWithFormat:@" %@ ", [ATHelper getMonthDateInTwoNumber:tmpDate]];
        
        dateComponent.day = timeSpanInDay/2;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        label3.text = [NSString stringWithFormat:@" %@ ", [ATHelper getMonthDateInTwoNumber:tmpDate]];
        
        dateComponent.day = 3*timeSpanInDay/4;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        label4.text = [NSString stringWithFormat:@" %@ ", [ATHelper getMonthDateInTwoNumber:tmpDate]];
        dateComponent.day = timeSpanInDay;
        
        tmpDate = endDay;
        label5.text = [NSString stringWithFormat:@" %@ ", [ATHelper getMonthDateInTwoNumber:tmpDate]];;
        [self fitSzie:label1];
        [self fitSzie:label2];
        [self fitSzie:label3];
        [self fitSzie:label4];
        [self fitSzie:label5];
        
    }
    else if (timeSpanInDay > 365 && timeSpanInDay < 5 * 365) //show label as Mar 2013
    {
        
        yearPart = [ATHelper getYearPartHelper:tmpDate];
        label1.text = [NSString stringWithFormat:@" %@, %@ ", [self getThreeLetterMonth:tmpDate], yearPart ];
        
        dateComponent.day = timeSpanInDay/4;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        yearPart = [ATHelper getYearPartHelper:tmpDate];
        label2.text = [NSString stringWithFormat:@" %@, %@ ", [self getThreeLetterMonth:tmpDate], yearPart ];
        
        dateComponent.day = timeSpanInDay/2;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        yearPart = [ATHelper getYearPartHelper:tmpDate];
        label3.text = [NSString stringWithFormat:@" %@, %@ ", [self getThreeLetterMonth:tmpDate], yearPart ];
        
        dateComponent.day = 3*timeSpanInDay/4;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        yearPart = [ATHelper getYearPartHelper:tmpDate];
        label4.text = [NSString stringWithFormat:@" %@, %@ ", [self getThreeLetterMonth:tmpDate], yearPart ];
        
        tmpDate = endDay;
        yearPart = [ATHelper getYearPartHelper:tmpDate];
        label5.text = [NSString stringWithFormat:@" %@, %@ ", [self getThreeLetterMonth:tmpDate], yearPart ];
        [self fitSzie:label1];
        [self fitSzie:label2];
        [self fitSzie:label3];
        [self fitSzie:label4];
        [self fitSzie:label5];

    }
    else //> 5 year, always show label as year such as 2003 AD
    {
        label1.text = [NSString stringWithFormat:@" %@ ", [ATHelper getYearPartHelper:tmpDate] ];
        dateComponent.day = timeSpanInDay/4;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        label2.text = [NSString stringWithFormat:@" %@ ", [ATHelper getYearPartHelper:tmpDate] ];
        dateComponent.day = timeSpanInDay/2;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        label3.text = [NSString stringWithFormat:@" %@ ", [ATHelper getYearPartHelper:tmpDate] ];
        dateComponent.day = 3*timeSpanInDay/4;
        tmpDate = [calendar dateByAddingComponents:dateComponent toDate:startDay options:0];
        label4.text = [NSString stringWithFormat:@" %@ ", [ATHelper getYearPartHelper:tmpDate] ];
        tmpDate = endDay;
        label5.text = [ATHelper getYearPartHelper:tmpDate];
        [self fitSzie:label1];
        [self fitSzie:label2];
        [self fitSzie:label3];
        [self fitSzie:label4];
        [self fitSzie:label5];
        
    }
}

- (NSString*)getThreeLetterMonth:(NSDate*)tmpDate
{
    NSString* tmpDateStr = [dateLiterFormat stringFromDate:tmpDate];
    NSRange range = [tmpDateStr rangeOfString:@" "];
    NSInteger idx = range.location + range.length;
    NSString* monthDateString = [tmpDateStr substringFromIndex:idx];
    return [monthDateString substringToIndex:3];
}

//will be called when scroll time window, zoom time window and add/modify ends events
- (void)changeTimeScaleState:(NSDate*)startDate :(NSDate*)endDate :(int)periodIndays :(NSDate*)focusedDate
{
    mStartDateFromParent = startDate;
    mEndDateFromParent = endDate;
    
    if (calendar == nil)
        calendar = [NSCalendar currentCalendar];
    
    //TODO should we validate that startDay < focused date < endDay ???? for defensive
    
    NSDateComponents *dateComponent = [[NSDateComponents alloc] init];
    
    NSDate* scaleStartDay;
    NSDate* scaleEndDay;
    
    if (focusedDate == nil)
        focusedDate = [[NSDate alloc] init];
    if (periodIndays <= 30)
    {
        dateComponent.day = -1;
        scaleStartDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
        dateComponent.day = 1;
        scaleEndDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
    }
    else if (periodIndays == 365)
    {
        dateComponent.month = -5;
        scaleStartDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
        dateComponent.month = 5;
        scaleEndDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
    }
    else if (periodIndays == 3650)
    {
        dateComponent.year = -5;
        scaleStartDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
        dateComponent.year = 5;
        scaleEndDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
    }
    else if (periodIndays == 36500)
    {
        dateComponent.year = -50;
        scaleStartDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
        dateComponent.year = 50;
        scaleEndDay = [calendar dateByAddingComponents:dateComponent toDate:focusedDate options:0];
    }
    else if (periodIndays == 365000)
    {
        dateComponent.year = -500;
        scaleStartDay = [ATHelper dateByAddingComponentsRegardingEra:dateComponent toDate:focusedDate options:0];
        dateComponent.year = 500;
        scaleEndDay = [ATHelper dateByAddingComponentsRegardingEra:dateComponent toDate:focusedDate options:0];
    }
    if ([startDate compare:scaleStartDay] == NSOrderedDescending)
        scaleStartDay = startDate;
    if ([endDate compare:scaleEndDay] == NSOrderedAscending)
        scaleEndDay = endDate;
    
   // ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];
   // NSDateFormatter *dateFormater = appDelegate.dateFormater;
    //NSLog(@"------ focusedDate is %@  formated is %@", focusedDate, [dateFormater stringFromDate:focusedDate]);
    //Following check will fail when accross BC/AD, and not neccessary
    /*
    if ([scaleStartDay compare:scaleEndDay] == NSOrderedDescending)
    {
        NSLog(@"  ####### server error, scaleStartDay should before scaleEndDay");
       // return;
    }
    */

    NSTimeInterval interval = [endDate timeIntervalSinceDate: startDate];
    int dayInterval = interval/86400;
    double timeSpanInDay = dayInterval;
    double pixPerDay = frameWidth / timeSpanInDay;
    
    interval = [scaleStartDay timeIntervalSinceDate: startDate];
    dayInterval = interval/86400;
    
    double scaleStartInPix = pixPerDay*dayInterval;
    
    interval = [scaleEndDay timeIntervalSinceDate: scaleStartDay];
    dayInterval = interval/86400;
    double scaleLengthInPix = pixPerDay * dayInterval;
    
    if (scaleStartInPix + scaleLengthInPix >frameWidth)
    {
        //NSLog(@" ###### Server error inner scale bar out of range");
        return;
    }
    self.scaleLenForDisplay = scaleLengthInPix;
    double scaleStartAdj = 0;
    if (scaleLengthInPix <5)
    {
        if (periodIndays <= 30)
            self.scaleLenForDisplay = 5;
        else
            self.scaleLenForDisplay = 10;
        scaleStartAdj = 0; //need compute?
    }
    timeScaleImageView.frame = CGRectMake(scaleStartInPix + scaleStartAdj, 10, self.scaleLenForDisplay, MOVABLE_VIEW_HEIGHT);
    if (self.scaleLenForDisplay < 150)
        [timeScaleImageView setImage:[UIImage imageNamed:@"TimeScaleBar100.png"]];
    else if (self.scaleLenForDisplay < 250 )
        [timeScaleImageView setImage:[UIImage imageNamed:@"TimeScaleBar200.png"]];
    else if (self.scaleLenForDisplay < 350 )
        [timeScaleImageView setImage:[UIImage imageNamed:@"TimeScaleBar300.png"]];
    else if (self.scaleLenForDisplay < 500 )
        [timeScaleImageView setImage:[UIImage imageNamed:@"TimeScaleBar400.png"]];
    else //if over 500
        [timeScaleImageView setImage:[UIImage imageNamed:@"TimeScaleBar700.png"]];
    
    CGPoint center = timeScaleImageView.center;
    center.y = -10;//this value decided y value when scroll time window
    labelScaleText.center = center;

    //[labelScaleText setFrame:CGRectMake(
                                  //  floorf((timeScaleImageView.frame.size.width - labelScaleText.frame.size.width) / 2.0), 0,
                                  //  labelScaleText.frame.size.width, labelScaleText.frame.size.height)];
    
}

- (void)drawEventDotsBySpan
{
    float DOT_SIZE = 5.0;
    float DOT_Y_POS = 3.0;
    ATAppDelegate *appDelegate = (ATAppDelegate *)[[UIApplication sharedApplication] delegate];

    Boolean eventVisibleOnMapFlag = false; //draw bar if there are event visible in map screen
    int size = [appDelegate.eventListSorted count] ;
    if (appDelegate.eventListSorted == nil || size < 1)
        return;

    //TODO mStartDate/mEndDate should not be null
    
    NSTimeInterval interval = [mEndDateFromParent timeIntervalSinceDate: mStartDateFromParent];
    int dayInterval = interval/86400;
    double timeSpanInDay = dayInterval;
    double pixPerDay = frameWidth / timeSpanInDay;
    
    //Get current map range
    MKCoordinateRegion region =  self.mapViewController.mapView.region;
    CLLocationCoordinate2D northWestCorner, southEastCorner;
    CLLocationCoordinate2D center   = region.center;
    northWestCorner.latitude  = center.latitude  - (region.span.latitudeDelta  / 2.0);
    northWestCorner.longitude = center.longitude - (region.span.longitudeDelta / 2.0);
    southEastCorner.latitude  = center.latitude  + (region.span.latitudeDelta  / 2.0);
    southEastCorner.longitude = center.longitude + (region.span.longitudeDelta / 2.0);
    
    NSDate* dt1 = ((ATEventDataStruct*)appDelegate.eventListSorted[0]).eventDate;

    //for (ATEventDataStruct* evt in appDelegate.eventListSorted)
    float previouseVisibleEventDrawXPos = 0;
    float previouseRegularDotXPos = 0;


    for (int i = 0; i< size; i++ )
    {
        //NSLog(@"#### i=%d",i);
        ATEventDataStruct* evt = appDelegate.eventListSorted[i];
        NSTimeInterval interval;
        int dayInterval;
        double x;
        
        NSDate* dt = evt.eventDate;
        if ([self checkIfEventOnScreen:evt :northWestCorner :southEastCorner])
        {
            eventVisibleOnMapFlag = true;
        }
        if (i == 0 || i == size - 1) //TODO do not know why i==0 x=930 will not draw dots
        {
            interval = [dt  timeIntervalSinceDate: mStartDateFromParent];
            dayInterval = interval/86400;
            x = pixPerDay * dayInterval;
            if (x >= self.frame.size.width)
                x = x -5;
            if (eventVisibleOnMapFlag)
            {
                CGContextSetRGBFillColor(context, 0,0.5,0.2, 1);
                CGContextFillRect(context, CGRectMake(x, DOT_Y_POS, DOT_SIZE, 2*DOT_SIZE));
                previouseVisibleEventDrawXPos = x;
            }
            else
            {
                CGContextSetRGBFillColor(context, 1.0, 0.4, 0.4, 1);
                CGContextFillEllipseInRect(context, CGRectMake(x, DOT_Y_POS, DOT_SIZE, DOT_SIZE));
            }
            //dt1 = dt;
            eventVisibleOnMapFlag = false;
            //NSLog(@" o or 1 -- draw dots for dt %@  dt1=%@ and x=%f i=%d", dt, dt1, x, i);
        }
        else
        {   
            interval = [dt  timeIntervalSinceDate: mStartDateFromParent];
            dayInterval = interval/86400;
            x = pixPerDay * dayInterval;
            
            if (eventVisibleOnMapFlag)
            {
                CGContextSetRGBFillColor(context, 0,0.5,0.2, 1);
                CGContextFillRect(context, CGRectMake(x, DOT_Y_POS, DOT_SIZE, 2*DOT_SIZE));
                previouseVisibleEventDrawXPos = x;
                if (toastFirstTimeDelay > 10 && toastFirstTimeDelay < 1000 )
                {
                    toastFirstTimeDelay = 10001; //My Trick so only display once
                    float xPos = x - 170;
                    if (xPos < 80)
                        xPos = 100;
                    [self makeToast:@"Tip: Green dots indicate events currently displayed on map." duration:30.0 position:[NSValue valueWithCGPoint:CGPointMake(xPos, -25)]];
                    self.hidden = false;
                    self.mapViewController.timeScrollWindow.hidden  = false;
                }
            }
            else
            {
                if (abs(x - previouseVisibleEventDrawXPos) >= DOT_SIZE) //make sure barDots will be draw always and not covered by later regular dot
                {
                    if (abs(x - previouseRegularDotXPos) >= DOT_SIZE) //do not draw if too crowd
                    {
                        CGContextSetRGBFillColor(context, 1.0, 0.4, 0.4, 1);
                        CGContextFillEllipseInRect(context, CGRectMake(x, DOT_Y_POS, DOT_SIZE, DOT_SIZE));
                        previouseRegularDotXPos = x;
                    }
                }
            }
            dt1 = dt;
            eventVisibleOnMapFlag = false;
        }
    } //end for loop
    toastFirstTimeDelay++;
}

-(Boolean)checkIfEventOnScreen:(ATEventDataStruct*) event :(CLLocationCoordinate2D)northWestCorner :(CLLocationCoordinate2D)southEastCorner
{
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(event.lat, event.lng);
    CLLocationCoordinate2D location = coord;
    
    return(
        location.latitude  >= northWestCorner.latitude &&
        location.latitude  <= southEastCorner.latitude &&
        
        location.longitude >= northWestCorner.longitude &&
        location.longitude <= southEastCorner.longitude
           );
}


@end
