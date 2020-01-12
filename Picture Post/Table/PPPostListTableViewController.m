//
//  PPPostTableViewController.m
//  Picture Post
//
//  Created by Ilya Atkin on 8/29/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import "PPAppDelegate.h"
#import "PPPostTableViewController.h"
#import "PPPost.h"
#import "PPPostListTableViewController.h"
#import "UIColor+PPColors.h"

@interface PPPostListTableViewController () {
    CLLocation* _lastLocation;
    CLLocationManager* _locationManager;
    NSManagedObjectContext* _moc;
    NSMutableArray* _posts;
}

@end

//This controller uses a flag property to determine if this all posts or only favorites are displayed. If this
//controller will be used for other types of post lists, a better solution will be needed. One possible idea is a
//dictionary that includes the type of list being displayed. Converting this controller into a base class for
//specific subclassed and specialized controllers could be done. At first blush however, it seems like this would be
//the more complicated solution.
@implementation PPPostListTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _moc = ((PPAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;

    if (!_favoriteList) {
        _posts = [NSMutableArray arrayWithArray:[_moc executeFetchRequest:[NSFetchRequest fetchRequestWithEntityName:@"PPPost"] error:nil]];
        self.navigationItem.title = @"Picture Post List";
    }
    else {
        NSFetchRequest* fr = [NSFetchRequest fetchRequestWithEntityName:@"PPPost"];
        fr.predicate = [NSPredicate predicateWithFormat:@"favorite = YES"];
        _posts = [NSMutableArray arrayWithArray:[_moc executeFetchRequest:fr error:nil]];
        
        self.navigationItem.title = @"Favorite Posts";
    }
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        [_locationManager startUpdatingLocation];
    }
    else {
        [self sortPostsByName];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    if (_favoriteList && _posts.count > 0) {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }
    
    [self.tableView reloadData];
}

#pragma mark - IBActions
- (IBAction)changeSorting:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            [self sortPostsByDistance];
            break;
        
        case 1:
            [self sortPostsByName];
            break;
            
        default:
            break;
    }
    
    [self.tableView reloadData];
}

#pragma mark - private methods
- (UITableViewCell*)postCellForIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"PostCell" forIndexPath:indexPath];
    PPPost* post = _posts[indexPath.row];

    cell.textLabel.text = post.title;
    cell.backgroundColor = [UIColor ppVeryLightGreenColor];
    
    if (_lastLocation) {
        CLLocation* postLocation = [[CLLocation alloc] initWithLatitude:post.lat.doubleValue longitude:post.lon.doubleValue];
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ miles away", [[NSNumberFormatter localizedStringFromNumber:@([_lastLocation distanceFromLocation:postLocation] / 1609.34) numberStyle:NSNumberFormatterCurrencyStyle] substringFromIndex:1]];
    }
    else {
        cell.detailTextLabel.text = @"";
    }
    
    if (!post.favorite.boolValue && _favoriteList) {
        cell.imageView.image = [UIImage imageNamed:@"starred_sad"];
    }
    else {
        cell.imageView.image = nil;
    }
    
    return cell;
}

- (void)sortPostsByDistance {
    [_posts sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        PPPost* post1 = obj1;
        PPPost* post2 = obj2;
        
        CLLocation* location1 = [[CLLocation alloc] initWithLatitude:post1.lat.floatValue longitude:post1.lon.floatValue];
        CLLocation* location2 = [[CLLocation alloc] initWithLatitude:post2.lat.floatValue longitude:post2.lon.floatValue];
        
        NSNumber* distance1 = @([_lastLocation distanceFromLocation:location1]);
        NSNumber* distance2 = @([_lastLocation distanceFromLocation:location2]);
        
        return [distance1 compare:distance2];
    }];
}

- (void)sortPostsByName {
    [_posts sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        PPPost* post1 = obj1;
        PPPost* post2 = obj2;
        
        return [post1.title.uppercaseString compare:post2.title.uppercaseString];
    }];
}

#pragma  mark - CLLLocationManagerDelegate methods
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (!_lastLocation) {
        _lastLocation = [locations lastObject];
        
        [self sortPostsByDistance];
    }
    else {
        _lastLocation = [locations lastObject];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_favoriteList && _posts.count == 0) {
        return 1;
    }
    else {
        if (_locationManager) {
            return 2;
        }
        else {
            return 1;
        }
    }
}

//In the event that location services are not available, the only has 1 section (0), the post list sorted by name
//In the more likely event that location services are enabled, Section 0 is the sort control and Section 1 the posts
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: {
            if (_favoriteList && _posts.count == 0) {
                return 1;
            }
            else if (_locationManager) {
                return 1;
            }
            else {
                return _posts.count > 0 ? _posts.count : 1;
            }
        }
        
        case 1:
            return _posts.count > 0 ? _posts.count : 1;
            
        default:
            return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            if (_favoriteList && _posts.count == 0) {
                return 120;
            }
            else if (_locationManager) {
                return 44;
            }
            else {
                return 44;
            }
        }
            
        case 1: {
            return 44;
        }
            
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    switch (indexPath.section) {
        case 0: {
            if (_favoriteList && _posts.count == 0) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"NoFavoritesCell" forIndexPath:indexPath];
                tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            }
            else {
                if (_locationManager) {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"SortCell" forIndexPath:indexPath];
                }
                else {
                    cell = [self postCellForIndexPath:indexPath];
                }
            }
        } break;
            
        case 1: {
            cell = [self postCellForIndexPath:indexPath];
        } break;
            
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == (_locationManager ? 1 : 0) && _posts.count != 0) {
        PPPost* post = _posts[indexPath.row];
        PPPostTableViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"PostTable"];
        vc.post = post;
        vc.moc = _moc;
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_favoriteList && _posts.count > 0) {
        if (_locationManager && indexPath.section == 1) {
            return YES;
        }
        else {
            return NO;
        }
    }
    else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    PPPost* post = _posts[indexPath.row];
    post.favorite = @NO;
    [_posts removeObject:post];
    [_moc save:nil];

    if (_posts.count == 0) {
        self.navigationItem.rightBarButtonItem = nil;
        [tableView reloadData];
    }
    else {
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */
@end
