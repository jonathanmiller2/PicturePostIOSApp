//
//  PPPictureViewController.m
//  Picture Post
//
//  Created by Ilya Atkin on 9/10/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import "PPPicture.h"
#import "PPPictureSet.h"
#import "PPPost.h"
#import "PPPictureViewController.h"

@interface PPPictureViewController () {
    NSMutableData* _imageData;
    NSTimer* _scrollBarTimer;
}

@end

@implementation PPPictureViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _imageData = [NSMutableData data];
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURL* imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"/images/pictures/post_%d/picture_%d.jpg", _picture.pictureSet.post.postID.intValue, _picture.pictureID.intValue] relativeToURL:PPURL];
    [self startLoadingAnimation];
    
    [[session dataTaskWithURL:imageURL] resume];
    
    [session finishTasksAndInvalidate];
    
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    float oldMinimumZoomScale = _scrollView.minimumZoomScale;
    float newMinimumZoomScale = toInterfaceOrientation == UIInterfaceOrientationPortrait ?
        (self.view.frame.size.width / _imageView.image.size.width) : (self.view.frame.size.height / _imageView.image.size.height);
    
    float currentZoomScale = _scrollView.zoomScale;
    _scrollView.minimumZoomScale = newMinimumZoomScale;
    _scrollView.zoomScale = (currentZoomScale == oldMinimumZoomScale) ?
        newMinimumZoomScale : currentZoomScale < newMinimumZoomScale ?
        newMinimumZoomScale : currentZoomScale;
    
    if (_scrollBarTimer) {
        [[NSRunLoop mainRunLoop] addTimer:_scrollBarTimer forMode:NSDefaultRunLoopMode];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma  mark - UIScrollViewDelegate methods
- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

#pragma mark - NSURLSessionDelegate and related methods
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [_imageData appendData:data];
    
    float progress = (float)dataTask.countOfBytesReceived/(float)dataTask.countOfBytesExpectedToReceive;
    _progressLabel.text = [NSString stringWithFormat:@"%d%%", (int)(progress*100)];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (!error) {
        [self showImageView];
    }
}

#pragma mark - private methods
- (void)handleZoomForTap:(UITapGestureRecognizer*)tgr {
    float currentZoom = _scrollView.zoomScale;

    if (currentZoom == _scrollView.minimumZoomScale) {
        CGSize scrollViewSize = _scrollView.frame.size;
        
        CGRect zoomRect;
        if (_scrollView.zoomScale < 0.5) {
            CGPoint touchPoint = [tgr locationInView:_imageView];
            
            zoomRect = CGRectMake(touchPoint.x - scrollViewSize.width, touchPoint.y - scrollViewSize.height, 2*scrollViewSize.width, 2*scrollViewSize.height);
        }
        else {
            CGPoint touchPoint = [tgr locationInView:_scrollView];
            
            zoomRect = CGRectMake(touchPoint.x, touchPoint.y, 0, 0);
        }

        [_scrollView zoomToRect:zoomRect animated:YES];
    }
    else {
        [_scrollView setZoomScale:_scrollView.minimumZoomScale animated:YES];
    }
}

- (void)startLoadingAnimation {
    CABasicAnimation* rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.fromValue = @0;
    rotationAnimation.toValue = @(2*M_PI);
    rotationAnimation.duration = 4.0;
    rotationAnimation.repeatCount = INFINITY;
    
    [_loadingImageView.layer addAnimation:rotationAnimation forKey:@"rotation"];
}

- (void)endLoadingAnimationAndHide:(BOOL)hidden {
    [_loadingImageView.layer removeAllAnimations];
    _loadingImageView.hidden = hidden;
    _progressLabel.hidden = hidden;
}

- (void)showImageView {
    UIImage* image = [UIImage imageWithData:_imageData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _scrollView = [[UIScrollView alloc] init];
        [self.view addSubview:_scrollView];
        
        [self endLoadingAnimationAndHide:YES];
        
        _imageView = [[UIImageView alloc] initWithImage:image];
        _imageView.userInteractionEnabled = YES;
        [_scrollView addSubview:_imageView];
        
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_scrollView, _imageView);
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_scrollView]|" options:0 metrics:nil views:viewsDictionary]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_scrollView]|" options:0 metrics:nil views:viewsDictionary]];
        [_scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_imageView]|" options:0 metrics:nil views:viewsDictionary]];
        [_scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_imageView]|" options:0 metrics:nil views:viewsDictionary]];
        
        _scrollView.delegate = self;
        
        float minimumZoomScale = ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait) ?
            (self.view.frame.size.width / image.size.width) : (self.view.frame.size.height / image.size.height);
        
        _scrollView.minimumZoomScale = minimumZoomScale;
        _scrollView.zoomScale = minimumZoomScale;
        
        UITapGestureRecognizer* zoomGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleZoomForTap:)];
        zoomGestureRecognizer.numberOfTapsRequired = 2;
        
        _imageView.gestureRecognizers = @[zoomGestureRecognizer];
        
        //flash scroll bars once everything is finished
        _scrollBarTimer = [NSTimer timerWithTimeInterval:0.5 target:_scrollView selector:@selector(flashScrollIndicators) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:_scrollBarTimer forMode:NSDefaultRunLoopMode];
    });
}

@end
