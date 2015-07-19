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
        self.checkIcon = [[UIImageView alloc] initWithFrame:CGRectMake([ATConstants eventListViewCellWidth] -25, 7, 20, 20)];
        [self.checkIcon setImage:[UIImage imageNamed:@"focuseIcon.png"]];
        [self.checkIcon setTag:9999];
        [self.contentView addSubview:self.checkIcon];
        int poiImageWidth = 65;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            poiImageWidth = 50;
        CGRect textFrame = CGRectMake(poiImageWidth, 0, [ATConstants eventListViewCellWidth] - poiImageWidth, [ATConstants eventListViewCellHeight]);
        UITextView* descView = (UITextView*)[self viewWithTag:99992];
        descView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        [descView setFrame:textFrame];
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
