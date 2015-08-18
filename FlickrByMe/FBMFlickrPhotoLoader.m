//
//  FBMFlickrModel.m
//  FlickrByMe
//
//  Created by Mike Carter (Old) on 8/17/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import "FBMFlickrPhotoLoader.h"
#import "FBMFlickrPhoto.h"

@implementation FBMFlickrPhotoLoader

static NSInteger const flickrPhotosPerPage = 50;
static NSString *const flickrAppKey = @"58113b676ebff68e3c1c05f58c8a8cf7";

- (void)photosForLocation:(CLLocationCoordinate2D)location
                     page:(NSInteger)page
          completionBlock:(FBMPhotoPageBlock)completion
{
  NSLog(@"Requesting page %li from Flickr", (long)page);

  NSString *urlString =
      [NSString stringWithFormat:@"https://api.flickr.com/services/rest/"
                                 @"?method=flickr.photos.search&api_key=%@&lat=%f&lon=%f&radius=5."
                                 @"0&extras=geo&per_page=%li&page=%li&format=json&nojsoncallback=1",
                                 flickrAppKey, location.latitude, location.longitude,
                                 (long)flickrPhotosPerPage, (long)page];

  NSURLSession *session = [NSURLSession sharedSession];
  [[session dataTaskWithURL:[NSURL URLWithString:urlString]
          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (nil != error) {
              completion(0, 0, nil, error);
              return;
            }
            NSDictionary *json =
                [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (nil != error) {
              completion(0, 0, nil, error);
              return;
            }
            // TODO: Should really check here for a Flickr response error, success, fail, etc
            if (json && [json isKindOfClass:[NSDictionary class]]) {
              NSInteger page = [[json[@"photos"] objectForKey:@"page"] integerValue];
              NSInteger pages = [[json[@"photos"] objectForKey:@"pages"] integerValue];
              NSArray *photos = json[@"photos"][@"photo"];
              if (photos && ([photos isKindOfClass:[NSArray class]])) {
                NSMutableArray *photoEntries = [NSMutableArray new];
                for (NSDictionary *temp in photos) {
                  [photoEntries addObject:[[FBMFlickrPhoto alloc] initWithPhotoDictionary:temp]];
                }
                completion(pages, page, photoEntries, error);
                return;
              }
              completion(0, 0, nil, error);
            }
          }] resume];
}

@end
