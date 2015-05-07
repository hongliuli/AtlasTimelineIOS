//
//  ATAnnotationPoi.m
//  AtlasTimelineIOS
//
//  Created by Hong on 5/4/15.
//  Copyright (c) 2015 hong. All rights reserved.
//

#import "ATAnnotationPoi.h"
#import "ATHelper.h"

@implementation ATAnnotationPoi

// override that in parent class ATEventAnnotation
- (NSString *)subtitle
{
    return @"";
}

- (NSString *)title
{
    return [ATHelper clearMakerAllFromDescText: self.description];
}

@end
