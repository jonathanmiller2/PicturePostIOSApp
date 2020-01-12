//
//  PPPictureCell.h
//  Picture Post
//
//  Created by Ilya Atkin on 9/9/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPPictureCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *directionLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *helpLabel;

- (void)startLoadingIndication;
- (void)endLoadingIndication;

@end
