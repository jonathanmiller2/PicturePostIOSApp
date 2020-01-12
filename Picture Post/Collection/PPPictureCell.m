//
//  PPPictureCell.m
//  Picture Post
//
//  Created by Ilya Atkin on 9/9/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import "PPPictureCell.h"

@implementation PPPictureCell

- (void)startLoadingIndication {
    CABasicAnimation* loadingAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    loadingAnimation.fromValue = @0;
    loadingAnimation.toValue = @(2*M_PI);
    loadingAnimation.duration = 4.0;
    loadingAnimation.repeatCount = INFINITY;
    
    [_imageView.layer addAnimation:loadingAnimation forKey:@"loadingAnimation"];
}

- (void)endLoadingIndication {
    [_imageView.layer removeAllAnimations];
}

@end
