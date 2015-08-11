//
//  FBMPhotoEntry.m
//  FlickrByMe
//
//  Created by Carter Mike-EMC045 on 8/12/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import "FBMPhotoEntry.h"

@implementation FBMPhotoEntry

- (instancetype)initWithPhotoDictionary:(NSDictionary *)dictionary
{
  self = [super init];
  if (!self) {
    return nil;
  }

  self.title = dictionary[@"title"];
  self.secret = dictionary[@"secret"];
  self.farm = [dictionary[@"farm"] intValue];
  self.server = [dictionary[@"server"] intValue];
  self.photoId = [dictionary[@"id"] longLongValue];

  return self;
}

@end
