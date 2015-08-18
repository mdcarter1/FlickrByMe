//
//  FBMFlickrModel.h
//  FlickrByMe
//
//  Created by Mike Carter (Old) on 8/17/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

typedef void (^FBMPhotoPageBlock)(NSInteger pages, NSInteger page, NSArray *photos);

typedef void (^FBMPhotoThumbImageBlock)(UIImage *image);

@class FBMFlickrPhoto;

@interface FBMFlickrPhotoLoader : NSObject

- (void)photosForLocation:(CLLocationCoordinate2D)location
                     page:(NSInteger)page
          completionBlock:(FBMPhotoPageBlock)completion;

/**
 *  Used for retrieving thumbnail image for a given FBMFlickrPhoto.  If a cached version
 *  of the image is available that will be used for better performance.  For convenience
 *  to the caller the completionBlock is guaranteed to be called on the main thread.
 */
- (void)thumbImageForPhoto:(FBMFlickrPhoto *)photo
           completionBlock:(FBMPhotoThumbImageBlock)completion;

@end
