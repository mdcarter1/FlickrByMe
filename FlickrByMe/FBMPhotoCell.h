//
//  FBMPhotoCell.h
//  FlickrByMe
//
//  Created by Mike Carter on 8/12/15.
//  Copyright (c) 2015 Mike Carter. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FBMFlickrPhoto;

typedef void (^FBMPhotoCellLoadedBlock)(UIImage *image);

@interface FBMPhotoCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (void)loadForPhoto:(FBMFlickrPhoto *)photo
               queue:(NSOperationQueue *)queue
     completionBlock:(FBMPhotoCellLoadedBlock)completion;

- (void)cancelLoad;

@end
