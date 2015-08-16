//
//  FBMPhotoEntry.h
//  FlickrByMe
//
//  Created by Mike Carter on 8/12/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FBMPhotoEntry : NSObject

@property (nonatomic, copy  ) NSString  *title;
@property (nonatomic, copy  ) NSString  *secret;
@property (nonatomic, assign) NSInteger farm;
@property (nonatomic, assign) NSInteger server;
@property (nonatomic, assign) long long photoId;

-(instancetype)initWithPhotoDictionary:(NSDictionary*)dictionary;

@end
