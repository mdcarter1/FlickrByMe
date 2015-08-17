//
//  FBMPhotoViewController.m
//  FlickrByMe
//
//  Created by Mike Carter on 8/13/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import "FBMPhotoViewController.h"
#import "FBMPhotoEntry.h"

@interface FBMPhotoViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidth;
@property (weak, nonatomic) IBOutlet UITextView *titleView;

@end

@implementation FBMPhotoViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self.activityView setHidesWhenStopped:YES];
  [self.activityView startAnimating];
}

- (BOOL)prefersStatusBarHidden
{
  return YES;
}

#pragma mark - Property Overrides

- (void)setEntry:(FBMPhotoEntry *)entry
{
  _entry = entry;

  NSString *urlString =
      // Got this here: https://www.flickr.com/services/api/misc.urls.html
      [NSString stringWithFormat:@"http://farm%ld.static.flickr.com/%ld/%lld_%@_b.jpg",
                                 (long)entry.farm, (long)entry.server, entry.photoId, entry.secret];

  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
  [NSURLConnection
      sendAsynchronousRequest:request
                        queue:[NSOperationQueue new]
            completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
              dispatch_async(dispatch_get_main_queue(), ^{
                [self.activityView stopAnimating];
                UIImage *image = [UIImage imageWithData:data];
                UIViewContentMode mode = [self isTabletSizeClass]
                                             ? UIViewContentModeScaleAspectFit
                                             : UIViewContentModeScaleAspectFill;
                [self.imageView setContentMode:mode];
                [self.imageView setImage:image];
                [self.titleView setText:entry.title];
              });
            }];
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Misc

- (BOOL)isTabletSizeClass
{
  // iPad is only iOS device that would have Regular for both horizontal and vertical
  return (UIUserInterfaceSizeClassRegular == self.traitCollection.horizontalSizeClass &&
          UIUserInterfaceSizeClassRegular == self.traitCollection.verticalSizeClass);
}

@end
