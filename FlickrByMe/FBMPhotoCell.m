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

- (void)loadForPhoto:(FBMFlickrPhoto *)photo
               queue:(NSOperationQueue *)queue
     completionBlock:(FBMPhotoCellLoadedBlock)completion
{
  NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
    NSString *urlString =
        // Got this here: https://www.flickr.com/services/api/misc.urls.html
        [NSString stringWithFormat:@"http://farm%ld.static.flickr.com/%ld/%lld_%@_m.jpg",
                                   (long)photo.farm, (long)photo.server, photo.photoId,
                                   photo.secret];

    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
    if (data) {
      UIImage *image = [UIImage imageWithData:data];
      if (completion) {
        completion(image);
      }
    } else {
      // Should handle this!
    }
  }];
  [queue addOperation:operation];
}

@end
