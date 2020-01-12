//
//  PPTakenPictureCollectionViewController.h
//  Picture Post
//
//  Created by Ilya Atkin on 8/15/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PPTakenPictureSet;

@interface PPTakenPictureSetCollectionViewController : UICollectionViewController <UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property PPTakenPictureSet* takenPictureSet;

@end
