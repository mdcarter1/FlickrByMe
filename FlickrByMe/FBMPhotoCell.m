//
//  FBMPhotoCell.m
//  FlickrByMe
//
//  Created by Mike Carter (Old) on 8/12/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import "FBMPhotoCell.h"
#import "FBMPhotoEntry.h"

@interface FBMPhotoCell ()

//@property (nonatomic, weak) NSOperationQueue *queue;
@property (nonatomic, strong) NSBlockOperation *operation;

@end


@implementation FBMPhotoCell

#pragma mark - Overridden Methods

- (void)prepareForReuse
{
  [super prepareForReuse];
  // Don't want to see the old image while new one is async loading
  [self.imageView setImage:nil];
  // May or may not really need to do this since the parent collection view has probably already
  // asked this cell to stop loading but doesn't hurt
  [self cancelLoad];
}

- (void)loadForPhoto:(FBMPhotoEntry *)entry
               queue:(NSOperationQueue *)queue
     completionBlock:(FBMPhotoCellLoadedBlock)completion
{
  self.operation = [NSBlockOperation blockOperationWithBlock:^{
    NSString *urlString =
        // Got this here: https://www.flickr.com/services/api/misc.urls.html
        [NSString stringWithFormat:@"http://farm%ld.static.flickr.com/%ld/%lld_%@_t.jpg",
                                   (long)entry.farm, (long)entry.server, entry.photoId,
                                   entry.secret];

    NSError *error;
    NSURLResponse *response;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    // Send synchronously since I'm making it the callers repsonsibility to setup the queue
    NSData *data =
        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    if (nil == error) {
      UIImage *image = [UIImage imageWithData:data];
      if (completion) {
        completion(image);
      }
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.imageView setImage:image];
      }];
    } else {
      // Should handle this!
    }
  }];
  [queue addOperation:self.operation];
}

- (void)cancelLoad
{
  [self.operation cancel];
}

@end
