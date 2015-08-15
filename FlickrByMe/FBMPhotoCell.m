//
//  FBMPhotoCell.m
//  FlickrByMe
//
//  Created by Mike Carter (Old) on 8/12/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import "FBMPhotoCell.h"

@implementation FBMPhotoCell


-(void)prepareForReuse
{
  // Don't want to see the old image while new one is async loading...
  [self.imageView setImage:nil];
}

@end
