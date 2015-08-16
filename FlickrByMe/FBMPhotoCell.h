//
//  FBMPhotoCell.h
//  FlickrByMe
//
//  Created by Mike Carter (Old) on 8/12/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FBMPhotoEntry;

typedef void (^FBMPhotoCellLoadedBlock)(UIImage* image);

@interface FBMPhotoCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (void)loadForPhoto:(FBMPhotoEntry *)entry
                    queue:(NSOperationQueue *)queue
          completionBlock:(FBMPhotoCellLoadedBlock)completion;

- (void)cancelLoad;

@end
