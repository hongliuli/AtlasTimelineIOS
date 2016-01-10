//
//  SWLongPressGestureRecognizer.m
//  SWTableViewCell
//
//  Created by Matt Bowman on 11/27/13.
//  Copyright (c) 2013 Chris Wendel. All rights reserved.
//

#import "SWLongPressGestureRecognizer.h"

@implementation SWLongPressGestureRecognizer

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSString *version = [[UIDevice currentDevice] systemVersion];
    NSString *firstLetter = [version substringToIndex:1];
    if ([firstLetter isEqualToString:@"8"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"",nil) message:NSLocalizedString(@"iOS 8 does not support left swipe operation, please upgrade to iOS 9 or higher!",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
    }
    [super touchesMoved:touches withEvent:event];
    
    self.state = UIGestureRecognizerStateFailed;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    self.state = UIGestureRecognizerStateFailed;

}

@end

