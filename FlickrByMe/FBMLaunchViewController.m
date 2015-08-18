//
//  FBMLaunchViewController.m
//  FlickrByMe
//
//  Created by Mike Carter on 8/17/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import "FBMLaunchViewController.h"

@interface FBMLaunchViewController ()

@property (weak, nonatomic) IBOutlet UIButton *startButton;

@property (strong, nonatomic) UIView  *pinkCircle;
@property (strong, nonatomic) UIView  *blueCircle;
@property (strong, nonatomic) UILabel *titleLabel;

@property (assign, nonatomic) CGPoint offscreenLeft;
@property (assign, nonatomic) CGPoint offscreenRight;
@property (assign, nonatomic) CGPoint onscreenLeft;
@property (assign, nonatomic) CGPoint onscreenRight;

@end

@implementation FBMLaunchViewController

static CGFloat const kCircleSize = 150;
static CGFloat const kCircleHalfSize = kCircleSize / 2;
static CGFloat const kCircleOverlap = 5;
static CGFloat const kTitleLabelWidth = 225;
static CGFloat const kTitleLabelHeight = 80;
static CGFloat const kStartButtonWidth = 200;
static CGFloat const kStartButtonHeight = 30;

- (void)viewDidLoad
{
  [super viewDidLoad];

  CGSize rootSize = self.view.frame.size;
  CGPoint rootCenter = self.view.center;

  self.offscreenLeft = CGPointMake(-kCircleHalfSize, rootCenter.y);
  self.offscreenRight = CGPointMake(rootSize.width + kCircleHalfSize, rootCenter.y);
  self.onscreenLeft = CGPointMake(rootCenter.x - kCircleHalfSize + kCircleOverlap, rootCenter.y);
  self.onscreenRight = CGPointMake(rootCenter.x + kCircleHalfSize - kCircleOverlap, rootCenter.y);

  // Make some circles
  self.pinkCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kCircleSize, kCircleSize)];
  self.pinkCircle.backgroundColor =
      [UIColor colorWithRed:222.0f / 225.0f green:53.0f / 225.0f blue:134.0f / 225.0f alpha:1.0f];
  self.pinkCircle.layer.cornerRadius = kCircleHalfSize;
  self.pinkCircle.center = self.offscreenLeft;
  [self.view addSubview:self.pinkCircle];

  self.blueCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kCircleSize, kCircleSize)];
  self.blueCircle.backgroundColor =
      [UIColor colorWithRed:27.0f / 225.0f green:23.0f / 225.0f blue:198.0f / 225.0f alpha:1.0f];
  self.blueCircle.layer.cornerRadius = kCircleHalfSize;
  self.blueCircle.center = self.offscreenRight;
  [self.view addSubview:self.blueCircle];

  self.titleLabel =
      [[UILabel alloc] initWithFrame:CGRectMake(self.view.center.x - kTitleLabelWidth / 2,
                                                self.view.center.y + kCircleHalfSize,
                                                kTitleLabelWidth, kTitleLabelHeight)];
  self.titleLabel.text = @"FlickrByMe";
  self.titleLabel.textAlignment = NSTextAlignmentCenter;
  self.titleLabel.font = [UIFont fontWithName:@"Noteworthy" size:42];
  self.titleLabel.textColor = [UIColor blackColor];
  self.titleLabel.alpha = 0.0;
  [self.view addSubview:self.titleLabel];


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
              self.titleLabel.alpha = 1.0;
            }
            completion:^(BOOL finished){
            }];
      }];

  self.startButton.layer.cornerRadius = 10;
  self.startButton.alpha = 0;
  self.startButton.backgroundColor = [UIColor blackColor];
  self.startButton.frame = CGRectMake(rootCenter.x - kStartButtonWidth / 2, rootSize.height - 50,
                                      kStartButtonWidth, kStartButtonHeight);
}

- (BOOL)shouldAutorotate
{
  // Disallowing rotation for this excercise. In real world I would
  // move the layout code out of viewDidLoad so we could reposition
  // everything
  return NO;
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
        self.blueCircle.center = self.offscreenRight;
        self.pinkCircle.center = self.offscreenLeft;
      }
      completion:^(BOOL finished) {
        [self performSegueWithIdentifier:@"FlickrPhotoSearch" sender:self];
      }];
}

@end
