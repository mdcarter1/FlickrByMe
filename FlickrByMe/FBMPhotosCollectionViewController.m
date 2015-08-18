//
//  FBMPhotosCollectionViewController.m
//  FlickrByMe
//
//  Created by Mike Carter on 8/11/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import "FBMPhotosCollectionViewController.h"
#import "FBMFlickrPhoto.h"
#import "FBMPhotoCell.h"
#import "FBMPhotoViewController.h"
#import "FBMFlickrPhotoLoader.h"
#import <MapKit/MapKit.h>


@interface FBMPhotosCollectionViewController () <CLLocationManagerDelegate,
                                                 UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) FBMFlickrPhotoLoader   *photoLoader;
@property (nonatomic, strong) NSMutableArray         *photoEntries;
@property (nonatomic, strong) NSCache                *photoCache;
@property (nonatomic, strong) NSOperationQueue       *photoOpQueue;
@property (nonatomic, strong) CLLocationManager      *locationManager;
@property (nonatomic, assign) CLLocationCoordinate2D currentCoordinates;
@property (nonatomic, strong) UIRefreshControl       *refreshControl;
@property (nonatomic, assign) NSInteger              currentPage;
@property (nonatomic, assign) NSInteger              lastPage;

@end

@implementation FBMPhotosCollectionViewController

static NSString *const reuseIdentifier = @"FlickrPhotoCell";

#pragma mark - Overriden Methods

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.collectionView addSubview:self.refreshControl];
  [self.refreshControl beginRefreshing];

  self.locationManager = [[CLLocationManager alloc] init];
  self.locationManager.delegate = self;

  self.photoCache = [[NSCache alloc] init];
  [self.photoCache setCountLimit:500];

  self.photoOpQueue = [[NSOperationQueue alloc] init];
  [self.photoOpQueue setMaxConcurrentOperationCount:3];

  // Note: Flickr search API starts pages at index 1 but we will start at zero because
  // we increment post-page fetch
  self.currentPage = 0;
  self.lastPage = 0;

  self.photoEntries = [NSMutableArray new];
  self.photoLoader = [FBMFlickrPhotoLoader new];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
  if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
    [self.locationManager requestWhenInUseAuthorization];
#endif
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  return [self.photoEntries count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  FBMPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier
                                                                 forIndexPath:indexPath];

  FBMFlickrPhoto *photo = [self.photoEntries objectAtIndex:indexPath.row];

  UIImage *cachedPhoto = [self.photoCache objectForKey:[NSNumber numberWithLongLong:photo.photoId]];
  if (cachedPhoto) {
    [cell.imageView setImage:cachedPhoto];
  } else {
    [cell loadForPhoto:photo
                  queue:self.photoOpQueue
        completionBlock:^(UIImage *image) {
          // Add it to the cache so we can be speedy...
          [self.photoCache setObject:image forKey:[NSNumber numberWithLongLong:photo.photoId]];
        }];
  }
  return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath
{
  // So to support pagination if we are displaying the last cell and we know there is more
  // pages still available on Flickr go ahead and request the next page
  if ((indexPath.row == [self.photoEntries count] - 1) && (self.currentPage < self.lastPage)) {
    [self loadMorePhotos];
  }
}

- (void)collectionView:(UICollectionView *)collectionView
  didEndDisplayingCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath
{
  [((FBMPhotoCell *)cell)cancelLoad];
}

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  FBMPhotoViewController *vc = [FBMPhotoViewController new];
  [vc setPhoto:self.photoEntries[indexPath.row]];
  [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
    didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
  if (status == kCLAuthorizationStatusAuthorizedAlways ||
      status == kCLAuthorizationStatusAuthorizedWhenInUse) {
    [self.locationManager startUpdatingLocation];
  } else {
    // Would need to handle this use-case in the real world
  }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
  if (!locations || locations.count < 1) {
    return;
  }
  // In a real app we would most likely want to handle the fact that the user is not stationary.
  // So we would probably want to switch to the significant location monitoring and then reload
  // or update the collection accordingly.  For this app I'm just using the first location.
  [self.locationManager stopUpdatingLocation];

  self.currentCoordinates = [(CLLocation *)[locations lastObject] coordinate];
  [self loadMorePhotos];
}

#pragma mark - Flickr

- (void)loadMorePhotos
{
  [self.photoLoader
      photosForLocation:self.currentCoordinates
                   page:self.currentPage + 1
        completionBlock:^(NSInteger pages, NSInteger page, NSArray *photos, NSError *error) {
          // Would handle errors more gracefully in the real world of course...
          if (nil != error) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [self.refreshControl endRefreshing];
              [self.refreshControl removeFromSuperview];
              NSLog(@"Photos load error = (%@)", error.localizedDescription);
            });
            return;
          }
          // Always keep updating the last page since in theory it could increase
          // while using the app
          self.lastPage = pages;
          if (page == ++self.currentPage) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [self.refreshControl endRefreshing];
              [self.refreshControl removeFromSuperview];
              // Could just call '[self.collectionView reloadData]' here but that might be a
              // little choppy on the on the scroll so instead do it the right way and insert
              // the new rows
              [self.collectionView performBatchUpdates:^{
                NSUInteger resultsSize = [self.photoEntries count];
                [self.photoEntries addObjectsFromArray:photos];
                NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];
                for (NSUInteger i = resultsSize; i < resultsSize + photos.count; i++) {
                  [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                }
                [self.collectionView insertItemsAtIndexPaths:arrayWithIndexPaths];
              } completion:nil];
            });
          } else {
            NSAssert(NO, @"Uh oh we are adding the same page twice!");
          }
        }];
}

@end
