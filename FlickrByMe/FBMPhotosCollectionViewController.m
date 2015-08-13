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
#import <MapKit/MapKit.h>


@interface FBMPhotosCollectionViewController () <CLLocationManagerDelegate>

#pragma mark - Model

@property (nonatomic, strong) NSMutableArray    *photoEntries;
@property (nonatomic, strong) NSCache           *photoCache;
@property (nonatomic, strong) NSOperationQueue  *photoOpQueue;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) UIRefreshControl  *refreshControl;

@end

@implementation FBMPhotosCollectionViewController

static NSString * const flickrAppKey    = @"58113b676ebff68e3c1c05f58c8a8cf7";
static NSString * const reuseIdentifier = @"FlickrPhotoCell";

typedef void (^FlickrNearbyPhotosCompletionBlock)(CLLocationCoordinate2D location, NSArray *photos,
                                                  NSError *error);

#pragma mark - Overriden Methods

- (void)viewDidLoad
{
  [super viewDidLoad];

  // Uncomment the following line to preserve selection between presentations
  // self.clearsSelectionOnViewWillAppear = NO;

  // Register cell classes
  [self.collectionView registerClass:[FBMPhotoCell class]
          forCellWithReuseIdentifier:reuseIdentifier];

  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.collectionView addSubview:self.refreshControl];
  [self.refreshControl beginRefreshing];

  // Location stuff
  self.locationManager = [[CLLocationManager alloc] init];
  self.locationManager.delegate = self;
  
  // Misc
  self.photoCache = [[NSCache alloc] init];
  [self.photoCache setCountLimit:500];
  
  self.photoOpQueue = [[NSOperationQueue alloc] init];
  [self.photoOpQueue setMaxConcurrentOperationCount:3];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  if (YES /*!firstLocationHasBeenRetrieved*/) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
      [self.locationManager requestWhenInUseAuthorization];
#endif
  }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark UICollectionViewDataSource

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

  // Configure the cell
  // [cell setBackgroundColor:[UIColor blackColor]];

  FBMPhotoEntry *entry = [self.photoEntries objectAtIndex:indexPath.row];

  UIImage *cachedPhoto = [self.photoCache objectForKey:[NSNumber numberWithLongLong:entry.photoId]];
  if (cachedPhoto) {
    [cell.imageView setImage:cachedPhoto];
  } else {
    // Lazy load the photo
    NSString *urlString =
        // Got this here: https://www.flickr.com/services/api/misc.urls.html
        [NSString stringWithFormat:@"http://farm%ld.static.flickr.com/%ld/%lld_%@_s.jpg",
                                   (long)entry.farm, (long)entry.server, entry.photoId,
                                   entry.secret];


    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [NSURLConnection
        sendAsynchronousRequest:request
                          queue:self.photoOpQueue
              completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                UIImage *image = [UIImage imageWithData:data];
                // Add it to the cache so we can be speedy...
                [self.photoCache setObject:image
                                    forKey:[NSNumber numberWithLongLong:entry.photoId]];
                dispatch_async(dispatch_get_main_queue(), ^{
                  [cell.imageView setImage:image];
                });
              }];
  }
  return cell;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self.navigationController pushViewController:[UIViewController new] animated:YES];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
    didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
  if (status == kCLAuthorizationStatusAuthorizedAlways ||
      status == kCLAuthorizationStatusAuthorizedWhenInUse) {
    [self.locationManager startUpdatingLocation];
  } else {
    // TODO: Handle this?
  }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
  if (!locations || locations.count < 1) return;

  [self.locationManager stopUpdatingLocation];

  [self
      flickrPhotosForLocation:[(CLLocation *)[locations lastObject] coordinate]
              completionBlock:^(CLLocationCoordinate2D location, NSArray *photos, NSError *error) {
                // TODO: check retain cycle
                self.photoEntries = [[NSMutableArray alloc] initWithArray:photos];
                dispatch_async(dispatch_get_main_queue(), ^{
                  [self.refreshControl endRefreshing];
                  [self.refreshControl removeFromSuperview];
                  [self.collectionView reloadData];
                });
              }];
}

#pragma mark - Flickr

- (void)flickrPhotosForLocation:(CLLocationCoordinate2D)location
                completionBlock:(FlickrNearbyPhotosCompletionBlock)completion
{
  NSString *urlString =
      [NSString stringWithFormat:@"https://api.flickr.com/services/rest/"
                                 @"?method=flickr.photos.search&api_key=%@&lat=%f&lon=%f&radius=5."
                                 @"0&extras=geo&per_page=100&format=json&nojsoncallback=1",
                                 flickrAppKey, location.latitude, location.longitude];

  NSURLSession *session = [NSURLSession sharedSession];
  [[session dataTaskWithURL:[NSURL URLWithString:urlString]
          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // Need to check for a session error
            if (nil != error) {
              completion(location, nil, error);
              return;
            }
            // TODO: Should check for a Flickr response error, success, fail, etc
            //
            NSDictionary *json =
                [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            // Checking for a JSON parsing error
            if (nil != error) {
              completion(location, nil, error);
              return;
            }
            if (json && [json isKindOfClass:[NSDictionary class]]) {
              NSArray *photos = json[@"photos"][@"photo"];
              if (photos && ([photos isKindOfClass:[NSArray class]])) {
                NSMutableArray *photoEntries = [NSMutableArray new];
                for (NSDictionary *temp in photos) {
                  [photoEntries addObject:[[FBMPhotoEntry alloc] initWithPhotoDictionary:temp]];
                }
                completion(location, photoEntries, error);
                return;
              }
              completion(location, nil, error);
            }
          }] resume];
}

@end
