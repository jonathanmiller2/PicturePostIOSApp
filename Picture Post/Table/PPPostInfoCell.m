//
//  PPPostInfoCell.m
//  Picture Post
//
//  Created by Ilya Atkin on 8/12/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import "PPPost.h"
#import "PPPostInfoCell.h"

@implementation PPPostInfoCell {
    NSMutableData* _downloadData;
    NSURLSessionDataTask* _imageTask;
}

- (void)loadImageForPost:(PPPost *)post {
    if (post.postPictureID.intValue < 1) {
        _imageLabel.text = @"No Post Image";
        _progressView.hidden = YES;
        
        return;
    }
    
    if (!_imageTask && !_downloadData) {
        _imageLabel.text = @"Downloading Post Image";
        _downloadData = [NSMutableData data];
        
        NSString* imageURLComponent = [NSString stringWithFormat:@"/images/pictures/post_%d/post_picture_%d_medium.jpg", post.postID.intValue, post.postPictureID.intValue];
        NSURL* imageURL = [NSURL URLWithString:imageURLComponent relativeToURL:PPURL];
        
        NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        _imageTask = [session dataTaskWithURL:imageURL];
        
        [_imageTask resume];
        [session finishTasksAndInvalidate];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [_downloadData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (!error) {
        _postImageView.image = [UIImage imageWithData:_downloadData];
        _postImageView.contentMode = UIViewContentModeScaleAspectFill;
        
        _progressView.hidden = YES;
        _imageLabel.hidden = YES;
    }
}

@end
