//
//  FBMPhotoViewController.m
//  FlickrByMe
//
//  Created by Mike Carter on 8/13/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import "FBMPhotoViewController.h"
#import "FBMFlickrPhoto.h"

@interface FBMPhotoViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *borderView;
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

- (void)setPhoto:(FBMFlickrPhoto *)photo
{
  _photo = photo;

  // TODO: This Flickr stuff could be moved over to FBMFlickrPhototLoader to be more
  // consistent
  NSString *urlString =
      // Got this here: https://www.flickr.com/services/api/misc.urls.html
      [NSString stringWithFormat:@"http://farm%ld.static.flickr.com/%ld/%lld_%@_b.jpg",
                                 (long)photo.farm, (long)photo.server, photo.photoId, photo.secret];

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
    if (data) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityView stopAnimating];
        
        UIImage *image = [self imageScaledForCurrentSizeClass:data];
        UIViewContentMode mode = [self isTabletSizeClass] ? UIViewContentModeScaleAspectFit
                                                          : UIViewContentModeScaleAspectFill;
        if ([self isTabletSizeClass]) {
          [self.imageHeight setConstant:image.size.height];
          [self.imageWidth setConstant:image.size.width];
          [self.imageView setNeedsUpdateConstraints];
        }
        [self.imageView setContentMode:mode];
        [self.imageView setImage:image];
        
        // Account for empty title
        if (!photo.title || photo.title.length == 0) {
          [self.titleView setText:@"Untitled"];
        } else {
          [self.titleView setText:photo.title];
        }
        
        // This will smooth the presentation so we don't get a hard pop when the images
        // are show drawn
        [UIView animateWithDuration:1
            delay:0
            options:(UIViewAnimationOptionCurveLinear)
            animations:^{
              self.borderView.alpha = 1.0;
              self.imageView.alpha = 1.0;
              self.titleView.alpha = 1.0;
            }
            completion:^(BOOL finished){
            }];
      });
    }
  });
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

- (UIImage *)imageScaledForCurrentSizeClass:(NSData *)data
{
  UIImage *image = [UIImage imageWithData:data];
  if ([self isTabletSizeClass]) {
    CGFloat scale = MAX(image.size.width / 500, image.size.height / 500);
    image = [UIImage imageWithData:data scale:scale];
  }
  return image;
}

@end
