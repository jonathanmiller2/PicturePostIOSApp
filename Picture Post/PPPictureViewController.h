//
//  PPPictureViewController.h
//  Picture Post
//
//  Created by Ilya Atkin on 9/10/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PPPicture;

@interface PPPictureViewController : UIViewController <UIScrollViewDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>
@property UIScrollView *scrollView;
@property UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *loadingImageView;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@property PPPicture* picture;

@end
