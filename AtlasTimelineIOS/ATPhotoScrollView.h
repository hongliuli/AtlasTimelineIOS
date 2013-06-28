//
//  HorizontalTableCell.h
//  HorizontalTables
//
//  Created by Felipe Laso on 8/19/11.
//  Copyright 2011 Felipe Laso. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATEventEditorTableController;

@interface ATPhotoScrollView : UIView <UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) NSMutableArray* photoList;
@property (nonatomic, strong) UITableView *horizontalTableView;
@property (weak, nonatomic) ATEventEditorTableController* eventEditor;
@property int selectedPhotoIndex;
@property int selectedAsThumbnailIndex;

@end
