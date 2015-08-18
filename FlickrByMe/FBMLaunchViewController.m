//
//  FBMLaunchViewController.m
//  FlickrByMe
//
//  Created by Mike Carter (Old) on 8/17/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import "FBMLaunchViewController.h"

@interface FBMLaunchViewController ()

@property (weak, nonatomic) IBOutlet UIView *pinkCircle;
@property (weak, nonatomic) IBOutlet UIView *blueCircle;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (assign, nonatomic) CGPoint offscreenLeft;
@property (assign, nonatomic) CGPoint offscreenRight;
@property (assign, nonatomic) CGPoint onscreenLeft;
@property (assign, nonatomic) CGPoint onscreenRight;

@end

@implementation FBMLaunchViewController

static const CGFloat circleSize = 150;
static const CGFloat circleHalfSize = circleSize/2;
static const CGFloat circleOverlap = 20;


- (void)viewDidLoad
{
  [super viewDidLoad];


  self.offscreenLeft = CGPointMake(-circleHalfSize, self.view.center.y);
  self.offscreenRight = CGPointMake(self.view.frame.size.width + circleHalfSize, self.view.center.y);
  self.onscreenLeft = CGPointMake(self.view.center.x - circleHalfSize, self.view.center.y);
  self.onscreenRight = CGPointMake(self.view.center.x + circleHalfSize, self.view.center.y);

  // Make some circles
  self.pinkCircle.layer.cornerRadius = 75;
  self.blueCircle.layer.cornerRadius = 75;

  self.blueCircle.frame = CGRectMake(0, 0, 150, 150);
  self.blueCircle.center = self.offscreenRight;

  self.pinkCircle.frame = CGRectMake(0, 0, 150, 150);
  self.pinkCircle.center = self.offscreenLeft;

  self.titleLabel.frame =
      CGRectMake(self.view.center.x - self.titleLabel.frame.size.width / 2,
                 self.view.center.y - self.titleLabel.frame.size.height / 2, 225, 50);

  [UIView animateWithDuration:1.0
      delay:0
      options:(UIViewAnimationOptionCurveEaseInOut)
      animations:^{
        self.blueCircle.center = self.onscreenLeft;
        self.pinkCircle.center = self.onscreenRight;
      }
      completion:^(BOOL finished) {
        [UIView animateWithDuration:1
            delay:0
            options:(UIViewAnimationOptionCurveLinear)
            animations:^{
              self.startButton.alpha = 1.0;
            }
            completion:^(BOOL finished){
            }];
      }];

  self.startButton.layer.cornerRadius = 10;
  self.startButton.alpha = 0;
  self.startButton.frame = CGRectMake(self.view.center.x - self.startButton.frame.size.width / 2,
                                      self.view.frame.size.height - 50, 200, 30);
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
  // Not doing segueue to give my exit animations time to play out
  return ![identifier isEqualToString:@"FlickrPhotoSearch"];
}

- (IBAction)startFlickrSearch:(id)sender
{
  [UIView animateWithDuration:1.0
      delay:0
      options:(UIViewAnimationOptionCurveEaseInOut)
      animations:^{
        self.blueCircle.center = self.offscreenLeft;
        self.pinkCircle.center = self.offscreenRight;
      }
      completion:^(BOOL finished) {
        [self performSegueWithIdentifier:@"FlickrPhotoSearch" sender:self];
      }];
}

@end
