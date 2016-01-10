//
//  ATDownloadTableViewController.h
//  AtlasTimelineIOS
//
//  Created by Hong on 2/17/13.
//  Copyright (c) 2013 hong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"

@class ATPreferenceViewController;
@class ATDownloadTableViewController;
@protocol DownloadTableViewControllerDelegate <NSObject>
- (void)downloadTableViewController:(ATDownloadTableViewController *)controller didSelectSource:(NSString *)source;
@end
@interface ATDownloadTableViewController : UITableViewController<SWTableViewCellDelegate>
@property (nonatomic, weak) id <DownloadTableViewControllerDelegate> delegate;
@property (nonatomic, strong) ATPreferenceViewController* parent;

@end
