//
//  FBMPhotoViewController.m
//  FlickrByMe
//
//  Created by Mike Carter (Old) on 8/13/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import "FBMPhotoViewController.h"
#import "FBMPhotoEntry.h"

@interface FBMPhotoViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation FBMPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Property Overrides

- (void)setEntry:(FBMPhotoEntry *)entry
{
  _entry = entry;

  // Lazy load the photo
  NSString *urlString =
      // Got this here: https://www.flickr.com/services/api/misc.urls.html
      [NSString stringWithFormat:@"http://farm%ld.static.flickr.com/%ld/%lld_%@_d.jpg",
                                 (long)entry.farm, (long)entry.server, entry.photoId, entry.secret];

  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
  [NSURLConnection
      sendAsynchronousRequest:request
                        queue:[NSOperationQueue new]
            completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
              dispatch_async(dispatch_get_main_queue(), ^{
                [self.imageView setImage:[UIImage imageWithData:data]];
              });
            }];
}

@end
