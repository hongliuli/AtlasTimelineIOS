//
//  ATEventListViewCell.m
//  AtlasTimelineIOS
//
//  Created by Hong on 6/1/14.
//  Copyright (c) 2014 hong. All rights reserved.
//

#import "ATEventListViewPoiCell.h"
#import "ATConstants.h"


@implementation ATEventListViewPoiCell

- (NSString *)reuseIdentifier
{
    return @"reuseIdentifier";
}

// use iOS7 way http://stackoverflow.com/questions/13216135/wrapping-text-in-a-uitextview-around-a-uiimage-without-coretext
// in my code, only iOS7 has this event list view feature
// CoreText is too complicated

- (id)initWithFrame:(CGRect)frame
{
    self=[super initWithFrame:frame];
    if (self)
    {
        UIImageView* iconView = (UIImageView*) [self viewWithTag:9999]; //modify that from parent
        [iconView setFrame:CGRectMake(2, 15, 6, 6)];
        [iconView setImage:[UIImage imageNamed:@"small-red-ball-icon.png"]];
        
    }
    return self;
}
/*
- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = CGRectMake(0,0,50,40);
    self.textLabel.frame = CGRectMake(45, 0, self.frame.size.width -45, self.frame.size.height);
}
*/
@end
