//
//  FBMFlickrModel.h
//  FlickrByMe
//
//  Created by Mike Carter (Old) on 8/17/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

typedef void (^FBMPhotoPageBlock)(NSInteger pages, NSInteger page, NSArray *photos, NSError *error);

typedef void (^FBMPhotoThumbImageBlock)(UIImage *image);

@class FBMFlickrPhoto;

@interface FBMFlickrPhotoLoader : NSObject

- (void)photosForLocation:(CLLocationCoordinate2D)location
                     page:(NSInteger)page
          completionBlock:(FBMPhotoPageBlock)completion;

- (void)thumbImageForPhoto:(FBMFlickrPhoto *)photo
                     queue:(NSOperationQueue *)queue
           completionBlock:(FBMPhotoThumbImageBlock)completion;

@end
