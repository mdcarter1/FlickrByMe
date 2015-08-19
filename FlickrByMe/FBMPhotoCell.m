//
//  FBMPhotoCell.m
//  FlickrByMe
//
//  Created by Mike Carter on 8/12/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import "FBMPhotoCell.h"
#import "FBMFlickrPhoto.h"

@implementation FBMPhotoCell

#pragma mark - Overridden Methods

- (void)prepareForReuse
{
  [super prepareForReuse];
  // Don't want to see the old image while new one is async loading
  [self.imageView setImage:nil];
}

@end
