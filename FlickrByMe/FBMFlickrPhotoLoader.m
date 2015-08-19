//
//  FBMFlickrModel.m
//  FlickrByMe
//
//  Created by Mike Carter (Old) on 8/17/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import "FBMFlickrPhotoLoader.h"
#import "FBMFlickrPhoto.h"

@interface FBMFlickrPhotoLoader ()

@property (nonatomic, strong) NSOperationQueue *photoOpQueue;
@property (nonatomic, strong) NSCache          *photoCache;

@end

@implementation FBMFlickrPhotoLoader

static NSInteger const flickrPhotosPerPage = 50;
static NSString *const flickrAppKey = @"58113b676ebff68e3c1c05f58c8a8cf7";

- (instancetype)init
{
  self = [super init];
  if (!self) {
    return nil;
  }

  self.photoOpQueue = [[NSOperationQueue alloc] init];
  // Can play with this to see what value works best
  [self.photoOpQueue setMaxConcurrentOperationCount:3];

  self.photoCache = [[NSCache alloc] init];
  [self.photoCache setCountLimit:500];

  return self;
}


- (void)photosForLocation:(CLLocationCoordinate2D)location
                     page:(NSInteger)page
          completionBlock:(FBMPhotoPageBlock)completion
{
  NSLog(@"Req page %li from Flickr", (long)page);

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

    NSData *data = [NSData
        dataWithContentsOfURL:[FBMFlickrPhotoLoader URLForPhotosWithLocation:location page:page]];

    NSInteger pageCount = -1;
    NSInteger pageIndex = -1;
    NSMutableArray *photos = [NSMutableArray new];

    if (data) {
      // TODO: Real world check here for JSON parse and Flickr bad response
      NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
      if (json && [json isKindOfClass:[NSDictionary class]]) {
        pageIndex = [[json[@"photos"] objectForKey:@"page"] integerValue];
        pageCount = [[json[@"photos"] objectForKey:@"pages"] integerValue];
        NSArray *photoDicts = json[@"photos"][@"photo"];
        if (photoDicts && ([photoDicts isKindOfClass:[NSArray class]])) {
          for (NSDictionary *temp in photoDicts) {
            [photos addObject:[[FBMFlickrPhoto alloc] initWithPhotoDictionary:temp]];
          }
        }
      }
    } else {
      NSLog(@"Photos URL load failed!");
    }
    
    if (completion) {
      completion(pageCount, pageIndex, photos);
    }
  });
}

- (void)thumbImageForPhoto:(FBMFlickrPhoto *)photo
           completionBlock:(FBMPhotoThumbImageBlock)completion
{
  // See if we already fetched this photo's thumbnail and have it in our cache
  UIImage *cachedImage = [self.photoCache objectForKey:[NSNumber numberWithLongLong:photo.photoId]];
  if (cachedImage && completion) {
    // TODO: Check this for main first for a synchronous return
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(cachedImage);
    });
    return;
  }

  NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{

    NSData *data =
        [NSData dataWithContentsOfURL:[FBMFlickrPhotoLoader URLForThumbnailWithPhoto:photo]];
    UIImage *image;
    
    if (data) {
      image = [UIImage imageWithData:data];
      // Add it to the cache so we can be speedy when/if we need this image again
      [self.photoCache setObject:image forKey:[NSNumber numberWithLongLong:photo.photoId]];
    } else {
      NSLog(@"Thumbmail URL load failed!");
    }
    
    if (completion) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(image);
      });
    }
  }];

  [self.photoOpQueue addOperation:operation];
}

#pragma mark - URL Helpers

+ (NSURL *)URLForPhotosWithLocation:(CLLocationCoordinate2D)location page:(NSInteger)page
{
  NSString *urlString =
      [NSString stringWithFormat:@"https://api.flickr.com/services/rest/"
                                 @"?method=flickr.photos.search&api_key=%@&lat=%f&lon=%f&radius=5."
                                 @"0&extras=geo&per_page=%li&page=%li&format=json&nojsoncallback=1",
                                 flickrAppKey, location.latitude, location.longitude,
                                 (long)flickrPhotosPerPage, (long)page];
  return [NSURL URLWithString:urlString];
}

+ (NSURL *)URLForThumbnailWithPhoto:(FBMFlickrPhoto *)photo
{
  // TODO: On lower density ala @2x devices we may be able to get away with using _t which
  // is smaller
  NSString *urlString =
      // Got this here: https://www.flickr.com/services/api/misc.urls.html
      [NSString stringWithFormat:@"http://farm%ld.static.flickr.com/%ld/%lld_%@_m.jpg",
                                 (long)photo.farm, (long)photo.server, photo.photoId, photo.secret];
  return [NSURL URLWithString:urlString];
}

@end
