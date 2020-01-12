//
//  PPPostInfoCell.h
//  Picture Post
//
//  Created by Ilya Atkin on 8/12/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PPPost;

@interface PPPostInfoCell : UITableViewCell <NSURLSessionDataDelegate, NSURLSessionTaskDelegate>
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *imageLabel;
@property (weak, nonatomic) IBOutlet UIImageView *postImageView;

- (void)loadImageForPost:(PPPost*)post;

@end
