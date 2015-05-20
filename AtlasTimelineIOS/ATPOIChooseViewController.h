//
//  ATPOIChooseViewController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 1/25/15.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATPOIChooseViewController;
@protocol POIChooseViewControllerDelegate <NSObject>
- (void)poiGroupChooseViewController:(ATPOIChooseViewController *)controller didSelectPoiGroup:(NSArray *)poiList;
@end


@interface ATPOIChooseViewController : UITableViewController <UIAlertViewDelegate>
@property (nonatomic, weak) id <POIChooseViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *poiSource;
@end