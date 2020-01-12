//
//  PPMapViewController.m
//  Picture Post
//
//  Created by Ilya Atkin on 8/6/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import "PPAppDelegate.h"
#import "PPMapViewController.h"
#import "PPPostListTableViewController.h"
#import "PPPostTableViewController.h"
#import "PPPost.h"
#import <CoreLocation/CoreLocation.h>

#define PP_LOGIN_TAG 101
#define PP_SAVE_TAG 102
#define PP_FIRST_TAG 103
#define PP_FAVORITES_TAG 201
#define PP_POSTLIST_TAG 202

@interface PPMapViewController () {
    NSManagedObjectContext* _moc;
    PPAppDelegate* _appDelegate;
    CLLocationManager* _locationManager;
}

@end

@implementation PPMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _mapView.delegate = self;
    _appDelegate = (id)[[UIApplication sharedApplication] delegate];
    _moc = _appDelegate.managedObjectContext;
    
    self.navigationController.toolbarHidden = NO;
    self.navigationController.toolbar.tintColor = self.navigationController.navigationBar.tintColor;
    
    self.navigationItem.title = @"Picture Post Map";
    
    self.navigationItem.rightBarButtonItem = [[MKUserTrackingBarButtonItem alloc] initWithMapView:_mapView];
    
    _locationManager = [[CLLocationManager alloc] init];
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
        [_locationManager requestWhenInUseAuthorization];
    }
    
    [self loadPosts];
}

- (void)viewWillAppear:(BOOL)animated {
    if(_appDelegate.phoneNumber) {
        _accountButton.title = @"Log Out";
    }
    
    if (self.navigationController.toolbarHidden) {
        [self.navigationController setToolbarHidden:NO animated:animated];
    }
    
    NSFetchRequest* fr = [NSFetchRequest fetchRequestWithEntityName:@"PPPost"];
    fr.predicate = [NSPredicate predicateWithFormat:@"favorite = YES"];
    int numberOfFavorites = (int)[_moc executeFetchRequest:fr error:nil].count;
    
    if (numberOfFavorites == 0) {
        _shownPostsControl.selectedSegmentIndex = 0;
        _shownPostsControl.enabled = NO;
        [self showAllPosts];
        
        [_appDelegate.annotationsToReload removeAllObjects];
    }
    else {
        _shownPostsControl.enabled = YES;
        
        if (_appDelegate.annotationsToReload.count > 0) {
            for (PPPost* post in _appDelegate.annotationsToReload) {
                [_mapView removeAnnotation:post];
                [_mapView addAnnotation:post];
            }
            
            [_appDelegate.annotationsToReload removeAllObjects];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [_appDelegate presentFirstRunAlert];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIBarButtonItem* barButton = sender;
    
    if (barButton.tag == PP_FAVORITES_TAG) {        
        PPPostListTableViewController* vc = segue.destinationViewController;
        vc.favoriteList = YES;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - KVO methods
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"phoneNumber"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _accountButton.title = @"Log Out";
        });
    }
}

#pragma mark - IBActions and related
- (IBAction)toggleLoginStatus:(id)sender {
    if (_appDelegate.phoneNumber) {
        [self removePhoneNumber];
    }
    else {
        [_appDelegate addObserver:self forKeyPath:@"phoneNumber" options:NSKeyValueObservingOptionNew context:nil];
        [_appDelegate presentInitialPhoneNumberAlert];
    }
}

- (IBAction)toggleShownPosts:(UISegmentedControl *)sender {
    if (!sender.enabled) {
        sender.selectedSegmentIndex = 0;
        
        [[[UIAlertView alloc] initWithTitle:@"No Favorite Posts" message:@"This button would toggle between showing every post and only your favorites." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
    }
    else {
        switch (sender.selectedSegmentIndex) {
            case 0: {
                [self showAllPosts];
            } break;
                
            case 1: {
                [self showFavoritePosts];
            } break;
                
            default:
                break;
        }
    }
}

#pragma mark - private methods - additional phone number
- (void)removePhoneNumber {
    [_appDelegate removePhoneNumber];
    _accountButton.title = @"Log In";
}

#pragma mark - private methods - posts
- (void)showAllPosts {
    NSFetchRequest* fr = [NSFetchRequest fetchRequestWithEntityName:@"PPPost"];
    NSArray* allPosts = [_moc executeFetchRequest:fr error:nil];
    [_mapView removeAnnotations:_mapView.annotations];
    [_mapView addAnnotations:allPosts];
}

- (void)showFavoritePosts {
    NSFetchRequest* fr = [NSFetchRequest fetchRequestWithEntityName:@"PPPost"];
    fr.predicate = [NSPredicate predicateWithFormat:@"favorite = YES"];
    NSArray* favoritePosts = [_moc executeFetchRequest:fr error:nil];
    [_mapView removeAnnotations:_mapView.annotations];
    [_mapView addAnnotations:favoritePosts];
    
}

- (void)loadPosts {
    NSFetchRequest* fr = [NSFetchRequest fetchRequestWithEntityName:@"PPPost"];
    NSArray* posts = [_moc executeFetchRequest:fr error:nil];
    
    if (posts.count > 0) {
        [_mapView addAnnotations:posts];
    }
    
    [self downloadPostList];
}


- (void)downloadPostList {
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 5.0;
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask* postListTask = [session dataTaskWithURL:[NSURL URLWithString:@"/app/GetPostList" relativeToURL:PPURL] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            [self insertPostsFromData:data];
        }
        self.navigationItem.title = @"Picture Post Map";
    }];
    
    self.navigationItem.title = @"Updating Map";
    [postListTask resume];
    
    [session finishTasksAndInvalidate];
}

- (void)insertPostsFromData:(NSData*)data {
    NSError* error = nil;
    
    NSString* jsonString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSArray* posts = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to process the list of new posts" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
            [alert show];
        });
    }
    else {
        for (NSDictionary* postDictionary in posts) {
            PPPost* post = [PPPost postFromDictionary:postDictionary inContext:_moc];
            
            if (post.postID.intValue == 433) {
                NSLog(@"%@", post.postDescription);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_mapView addAnnotation:post];
            });
        }
        
        [_moc save:nil];
    }
}

#pragma mark - MKMapViewDelegate methods
- (MKAnnotationView*)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    else {
        MKAnnotationView* annotationView = [_mapView dequeueReusableAnnotationViewWithIdentifier:annotation.title];
        
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotation.title];
            annotationView.userInteractionEnabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        }
        
        PPPost* post = (PPPost*)annotation;
        
        if (post.favorite.boolValue) {
            annotationView.image = [UIImage imageNamed:@"FavoritePin"];
            annotationView.centerOffset = CGPointMake(0.5, -24);
        }
        else {
            annotationView.image = [UIImage imageNamed:@"PostPin"];
            annotationView.centerOffset = CGPointMake(6.5, -24);
        }
        
        return annotationView;
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    PPPost* post = (PPPost*)view.annotation;
    
    PPPostTableViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"PostTable"];
    vc.post = post;
    vc.moc = _moc;
    
    [self.navigationController pushViewController:vc animated:YES];
}

@end
