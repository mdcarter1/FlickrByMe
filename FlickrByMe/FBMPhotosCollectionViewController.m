//
//  FBMPhotosCollectionViewController.m
//  FlickrByMe
//
//  Created by Carter Mike-EMC045 on 8/11/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import "FBMPhotosCollectionViewController.h"
#import "FBMPhotoEntry.h"
#import "FBMPhotoCell.h"
#import "FBMPhotoViewController.h"
#import <MapKit/MapKit.h>


@interface FBMPhotosCollectionViewController () <CLLocationManagerDelegate,
                                                 UICollectionViewDelegateFlowLayout>

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

static NSInteger  const flickrPhotosPerPage = 50;
static NSString * const flickrAppKey         = @"58113b676ebff68e3c1c05f58c8a8cf7";
static NSString * const reuseIdentifier      = @"FlickrPhotoCell";

typedef void (^FlickrNearbyPhotosCompletionBlock)(NSInteger pages, NSInteger page, NSArray *photos,
                                                  NSError *error);

#pragma mark - Overriden Methods

- (void)viewDidLoad
{
  [super viewDidLoad];

  // Uncomment the following line to preserve selection between presentations
  // self.clearsSelectionOnViewWillAppear = NO;

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

  FBMPhotoEntry *entry = [self.photoEntries objectAtIndex:indexPath.row];

  UIImage *cachedPhoto = [self.photoCache objectForKey:[NSNumber numberWithLongLong:entry.photoId]];
  if (cachedPhoto) {
    [cell.imageView setImage:cachedPhoto];
  } else {
    [cell loadForPhoto:entry
                  queue:self.photoOpQueue
        completionBlock:^(UIImage *image) {
          // Add it to the cache so we can be speedy...
          [self.photoCache setObject:image forKey:[NSNumber numberWithLongLong:entry.photoId]];
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
    [self addPhotoPageForLocation:self.currentCoordinates page:self.currentPage + 1];
  }
}

- (void)collectionView:(UICollectionView *)collectionView
  didEndDisplayingCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath
{
  //[((FBMPhotoCell*)cell) cancelLoadThumb];
}

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  FBMPhotoViewController *vc = [FBMPhotoViewController new];
  [vc setEntry:self.photoEntries[indexPath.row]];
  [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UICollectionViewDelegateFlowLayout

/* Don't need to do this since I'm using fixed sized cells
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  FBMPhotoEntry *entry = self.photoEntries[indexPath.row];
  UIImage *thumb = [self.photoCache objectForKey:[NSNumber numberWithLongLong:entry.photoId]];
  CGSize size = thumb.size.width > 0 ? thumb.size : CGSizeMake(100, 100);
  return size;
}*/

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
  [self addPhotoPageForLocation:self.currentCoordinates page:self.currentPage + 1];
}

#pragma mark - Flickr

- (void)addPhotoPageForLocation:(CLLocationCoordinate2D)location page:(NSInteger)page
{
  [self
      flickrPhotosForLocation:self.currentCoordinates
                         page:self.currentPage + 1
              completionBlock:^(NSInteger pages, NSInteger page, NSArray *photos, NSError *error) {
                // TODO: Handle the error if necessary
                self.lastPage = pages;
                if (page == ++self.currentPage) {
                  // TODO: check retain cycle
                  dispatch_async(dispatch_get_main_queue(), ^{
                    [self.refreshControl endRefreshing];
                    [self.refreshControl removeFromSuperview];
                    // Could just call 'reloadData' here but that might be a little choppy on the
                    // on the scroll so instead do it the right way and insert the new rows.
                    //[self.collectionView reloadData];
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
                  // Uh oh!
                  NSAssert(YES, @"Uh oh we are adding the same page twice!");
                }
              }];
}

- (void)flickrPhotosForLocation:(CLLocationCoordinate2D)location
                           page:(NSInteger)page
                completionBlock:(FlickrNearbyPhotosCompletionBlock)completion
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
                  [photoEntries addObject:[[FBMPhotoEntry alloc] initWithPhotoDictionary:temp]];
                }
                completion(pages, page, photoEntries, error);
                return;
              }
              completion(0, 0, nil, error);
            }
          }] resume];
}

@end
