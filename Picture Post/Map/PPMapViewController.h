//
//  PPMapViewController.h
//  Picture Post
//
//  Created by Ilya Atkin on 8/6/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPMapViewController : UIViewController <MKMapViewDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *accountButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *shownPostsControl;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
- (IBAction)toggleLoginStatus:(id)sender;
- (IBAction)toggleShownPosts:(UISegmentedControl *)sender;

@end
