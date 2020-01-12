//
//  PPPictureSetTableViewController.m
//  Picture Post
//
//  Created by Ilya Atkin on 8/8/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import "PPAppDelegate.h"
#import "PPPostTableViewController.h"
#import "PPPictureSet.h"
#import "PPPictureSetCollectionViewController.h"
#import "PPPost.h"
#import "PPPostInfoCell.h"
#import "PPTakenPictureSet.h"
#import "PPTakenPictureSetCollectionViewController.h"
#import "UIColor+PPColors.h"

#define PP_TAKE_TAG 100
#define PP_FAVORITE_TAG 101

@interface PPPostTableViewController () {
    BOOL _loading;
    NSMutableData* _pictureSetListData;
}
@end

@implementation PPPostTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = _post.title;
    
    [self.refreshControl addTarget:self action:@selector(loadPictureSets) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl addTarget:self action:@selector(toggleRefreshControlTitle) forControlEvents:UIControlEventValueChanged];
    
    [self loadPictureSets];;

}

- (void)viewWillAppear:(BOOL)animated {
    if (_post.takenPictureSets.count > 0) {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }

    if (!self.isMovingToParentViewController) {
        [self.tableView reloadData];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - private methods

- (void)loadPictureSets {
    NSString* urlString = [NSString stringWithFormat:@"/app/GetPostAndPictureSets?postId=%d", _post.postID.intValue];
    NSURL* url = [NSURL URLWithString:urlString relativeToURL:PPURL];
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.allowsCellularAccess = YES;
    config.timeoutIntervalForRequest = 5;
    config.timeoutIntervalForResource = 5;
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask* pictureSetTask = [session dataTaskWithURL:url];
    
    _pictureSetListData = [NSMutableData data];
    
    _loading = YES;
    
    [pictureSetTask resume];
    [session finishTasksAndInvalidate];
}

- (void)toggleRefreshControlTitle {
    NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithAttributedString:self.refreshControl.attributedTitle];
    
    if (self.refreshControl.refreshing) {
        s.mutableString.string = @"Loading";
    }
    else {
        s.mutableString.string = @"Pull to reload picture sets";
    }
    
    self.refreshControl.attributedTitle = s;
}

- (IBAction)toggleFavorite:(id)sender {
    UISwitch* favoriteSwitch = sender;
    _post.favorite = @(favoriteSwitch.on);
    
    [((PPAppDelegate*)[[UIApplication sharedApplication] delegate]).annotationsToReload addObject:_post];
    
    [_moc save:nil];
}

#pragma mark - NSURLSessionDelegate methods
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [_pictureSetListData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    if (!error) {
        id jsonObject = [NSJSONSerialization JSONObjectWithData:_pictureSetListData options:NSJSONReadingAllowFragments error:nil];
        
        if ([[jsonObject class] isSubclassOfClass:[NSDictionary class]]) {
            NSArray* pictureSets = ((NSDictionary*)jsonObject)[@"pictureSets"];
            
            for (PPPictureSet* ps in _post.pictureSets) {
                [_moc deleteObject:ps];
            }
            
            for (NSDictionary* pictureSet in pictureSets) {
                [PPPictureSet insertPictureSetFromDictionary:pictureSet forPost:_post inContext:_moc];
            }
            
            [_post.pictureSets sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                PPPictureSet* ps1 = obj1;
                PPPictureSet* ps2 = obj2;
                return [ps2.dateTaken compare:ps1.dateTaken];
            }];
            
            [_moc save:nil];
            
            _loading = NO;
            
            [self.refreshControl endRefreshing];
            [self toggleRefreshControlTitle];
            
            [self.tableView reloadData];
        }
    }
    else {
        _loading = NO;
        [self.tableView reloadData];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 2;
            
        case 1:
            return _post.takenPictureSets.count  + 1;
            
        case 2:
            return (_post.pictureSets.count > 0 ? _post.pictureSets.count : 1) + (_loading ? 1 : 0);
            
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            if (indexPath.row == 0) {
                static NSString* cellID = @"PostInfoCell";
                PPPostInfoCell* cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
                [cell loadImageForPost:_post];
                cell.backgroundColor = [UIColor ppVeryLightGreenColor];
                
                return cell;
            }
            else if (indexPath.row == 1) {
                static NSString* cellID = @"FavoriteCell";
                UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
                cell.backgroundColor = [UIColor ppVeryLightGreenColor];
                
                UISwitch* favoriteSwitch = (id)[cell viewWithTag:PP_FAVORITE_TAG];
                favoriteSwitch.on = _post.favorite.boolValue;
                
                return cell;
            }
        }
            
        case 1: {
            if (indexPath.row == 0) {
                static NSString* cellID = @"TakeNewPictureSetCell";
                UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
             
                
                if (![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
                    UIButton* button = (id)[cell viewWithTag:PP_TAKE_TAG];
                    button.enabled = NO;
                }
                
                cell.backgroundColor = [UIColor ppVeryLightGreenColor];
                
                return cell;
            }
            else {
                static NSString* cellID = @"PictureSetCell";
                UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
                NSDateFormatter* df = [[NSDateFormatter alloc] init];
                df.dateFormat = @"MM/dd/yy hh:mm a";
                PPTakenPictureSet* ps = _post.takenPictureSets[indexPath.row - 1];
                cell.textLabel.text = [df stringFromDate:ps.dateTaken];
                cell.backgroundColor = [UIColor ppVeryLightGreenColor];
                return cell;
            }
        }
            
        case 2: {
            static NSString* cellID = @"PictureSetCell";            
            UITableViewCell* cell;
            
            if (_loading && indexPath.row == 0) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"LoadingCell" forIndexPath:indexPath];
                cell.backgroundColor = [UIColor ppVeryLightGreenColor];
                
                return cell;
            }
            else {
                cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
            }
            
            
            if (_post.pictureSets.count > 0) {
                NSDateFormatter* df = [[NSDateFormatter alloc] init];
                df.dateFormat = @"MM/dd/yy hh:mm a";
                PPPictureSet* ps = _post.pictureSets[indexPath.row - (_loading ? 1 : 0)];
                cell.textLabel.text = [df stringFromDate:ps.dateTaken];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            else {
                cell.textLabel.text = @"No Picture Sets";
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            cell.backgroundColor = [UIColor ppVeryLightGreenColor];

            return cell;
        }
            
        default: {
            return nil;
        }
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView* header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"Header"];
    
    if (!header) {
        header = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"Header"];
    }
    
    switch (section) {
        case 1:
            header.textLabel.text = @"Taken Picture Sets";
            return header;
            
        case 2:
            header.textLabel.text = @"Picture Sets";
            return header;
            
        default:
            return nil;
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            if (indexPath.row == 0) {
                return 120;
            }
            else {
                return 44;
            }
        }
            
        default:
            return 44;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 0;
            
        case 1:
            return 20;
            
        case 2:
            return 20;
            
        default:
            return 0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 1: {
            if (indexPath.row == 0){
                if (![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
                    [[[UIAlertView alloc] initWithTitle:@"Camera Required" message:@"A camera is required in order to take a picture set." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil] show];
                }
            }
            else {
                PPTakenPictureSetCollectionViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"TakenPictureCollection"];
                vc.takenPictureSet = _post.takenPictureSets[indexPath.row - 1];
                
                [self.navigationController pushViewController:vc animated:YES];
            }
        } break;
            
        case 2: {
            PPPictureSetCollectionViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"PictureSetCollection"];
            vc.pictureSet = _post.pictureSets[indexPath.row];
            
            [self.navigationController pushViewController:vc animated:YES];
            
        } break;
            
        default:
            break;
    }
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 1: {
            switch (indexPath.row) {
                case 0:
                    return NO;
                    
                default:
                    return YES;
            }
        }
            
        default:
            return NO;
    }
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        
        PPTakenPictureSet* pst = _post.takenPictureSets[indexPath.row - 1];
        [_moc deleteObject:pst];
        [_moc save:nil];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
