//
//  FBMPhotosCollectionViewController.m
//  FlickrByMe
//
//  Created by Carter Mike-EMC045 on 8/11/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import "FBMPhotosCollectionViewController.h"
#import "FBMPhotoEntry.h"
#import <MapKit/MapKit.h>


@interface FBMPhotosCollectionViewController () <CLLocationManagerDelegate>


#pragma mark - Model

@property (nonatomic, strong) NSMutableArray* flickrPhotos;

@property (nonatomic, strong) CLLocationManager* locationManager;

@property (nonatomic, strong) UIRefreshControl* refreshControl;


@end

@implementation FBMPhotosCollectionViewController

static NSString * const flickrAppKey    = @"58113b676ebff68e3c1c05f58c8a8cf7";
static NSString * const reuseIdentifier = @"FlickrPhotoCell";

typedef void (^FlickrNearbyPhotosCompletionBlock)( CLLocationCoordinate2D location, NSArray *photos, NSError *error);

#pragma mark - Overriden Methods

- (void)viewDidLoad {
  [super viewDidLoad];

  // Uncomment the following line to preserve selection between presentations
  // self.clearsSelectionOnViewWillAppear = NO;

  // Register cell classes
  [self.collectionView registerClass:[UICollectionViewCell class]
          forCellWithReuseIdentifier:reuseIdentifier];

  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.collectionView addSubview:self.refreshControl];
  [self.refreshControl beginRefreshing];
  
  // Location stuff
  self.locationManager = [[CLLocationManager alloc] init];
  self.locationManager.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  if (YES/*!firstLocationHasBeenRetrieved*/) {
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

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return [self.flickrPhotos count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  UICollectionViewCell *cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier
                                                forIndexPath:indexPath];

  // Configure the cell
  [cell setBackgroundColor:[UIColor blackColor]];

  return cell;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

#pragma mark - <CLLocationManagerDelegate>

- (void)locationManager:(CLLocationManager *)manager
    didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
  if (status == kCLAuthorizationStatusAuthorizedAlways ||
      status ==
          kCLAuthorizationStatusAuthorizedWhenInUse) {
    [self.locationManager startUpdatingLocation];
  } else {
    // TODO: Handle this?
  }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
  if (!locations || locations.count < 1)
    return;
  
  [self.locationManager stopUpdatingLocation];

  [self
      flickrPhotosForLocation:[(CLLocation *)[locations lastObject] coordinate]
              completionBlock:^(CLLocationCoordinate2D location,
                                NSArray *photos, NSError *error) {
                // TODO: check retain cycle
                self.flickrPhotos =
                    [[NSMutableArray alloc] initWithArray:photos];
                dispatch_async(dispatch_get_main_queue(), ^{
                  [self.refreshControl endRefreshing];
                  [self.refreshControl removeFromSuperview];
                  [self.collectionView reloadData];
                });
              }];
}

#pragma mark - Flickr

- (void)flickrPhotosForLocation:( CLLocationCoordinate2D)location
                completionBlock:(FlickrNearbyPhotosCompletionBlock)completion {


  NSString *urlString = [NSString
      stringWithFormat:@"https://api.flickr.com/services/rest/"
                       @"?method=flickr.photos.search&api_key=%@&lat=%f&lon=%f&radius=5.0&extras=geo&per_page=100&format=json&nojsoncallback=1",
                       flickrAppKey, location.latitude, location.longitude];
 
  NSURLSession *session = [NSURLSession sharedSession];
  [[session dataTaskWithURL:[NSURL URLWithString:urlString]
          completionHandler:^(NSData *data, NSURLResponse *response,
                              NSError *error) {
            // Need to check for a session error
            if (nil != error) {
              completion(location, nil, error);
            }
            // Now check for a Flickr response error, success, fail, etc
            // TODO

            NSDictionary *json =
                [NSJSONSerialization JSONObjectWithData:data
                                                options:kNilOptions
                                                  error:&error];
            // Checking for a JSON parsing error
            if (nil != error) {
              completion(location, nil, error);
            }
            // TODO: Clean this up
            if (json && [json isKindOfClass:[NSDictionary class]]) {
              NSArray *photos = json[@"photos"][@"photo"];
              if (photos && ([photos isKindOfClass:[NSArray class]])) {
                NSMutableArray *photoEntries = [NSMutableArray new];
                for (NSDictionary *temp in photos) {
                  [photoEntries addObject:[[FBMPhotoEntry alloc] initWithPhotoDictionary:temp]];
                }
                completion(location, photoEntries, error);
              } else {
                completion(location, nil, error);
              }
            } else {
              completion(location, nil, error);
            }
          }] resume];
}

@end
