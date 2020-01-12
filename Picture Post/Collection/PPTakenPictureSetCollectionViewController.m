//
//  PPTakenPictureCollectionViewController.m
//  Picture Post
//
//  Created by Ilya Atkin on 8/15/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import "PPAppDelegate.h"
#import "PPPostTableViewController.h"
#import "PPPost.h"
#import "PPTakenPicture.h"
#import "PPTakenPictureCell.h"
#import "PPTakenPictureSet.h"
#import "PPTakenPictureSetCollectionViewController.h"
#import "PPUploadDelegate.h"
#import "UIColor+PPColors.h"

#define PP_UPLOADING @(-1)
#define PP_NEXT_IMAGE_ALERT_TAG 101

@interface PPTakenPictureSetCollectionViewController () {
    NSArray* _directions;
    NSManagedObjectContext* _moc;
    NSMutableArray* _imageData;
    NSUInteger _indexForPicker;
    PPAppDelegate* _delegate;
    PPUploadDelegate* _uploadDelegate;
    
    UIImagePickerController* _ipc;
}

@end

@implementation PPTakenPictureSetCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _imageData = [NSMutableArray arrayWithCapacity:9];
    _directions = @[@"North", @"North East", @"East", @"South East", @"South", @"South West", @"West", @"North West", @"Up"];
    _delegate = (id)[[UIApplication sharedApplication] delegate];
    _moc = _delegate.managedObjectContext;
    _uploadDelegate = [[PPUploadDelegate alloc] initWithCollectionView:self.collectionView andManagedObjectContext:_moc];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        _ipc = [[UIImagePickerController alloc] init];
        _ipc.sourceType = UIImagePickerControllerSourceTypeCamera;
        _ipc.editing = NO;
        _ipc.delegate = self;
    });

	if (_takenPictureSet == nil) {
        int n = (int)self.navigationController.viewControllers.count;
        PPPostTableViewController* pst = self.navigationController.viewControllers[n-2];
        PPPost* post = pst.post;
        
        PPTakenPictureSet* tps = [NSEntityDescription insertNewObjectForEntityForName:@"PPTakenPictureSet" inManagedObjectContext:_moc];
        tps.post = post;
        tps.dateTaken = [NSDate date];
        
        for (int i = 0; i < 9; ++i) {
            PPTakenPicture* tp = [NSEntityDescription insertNewObjectForEntityForName:@"PPTakenPicture" inManagedObjectContext:_moc];
            tp.takenPictureSet = tps;
            tp.direction = @(i);
        }
        
        [post.takenPictureSets sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            PPTakenPictureSet* tps1 = obj1;
            PPTakenPictureSet* tps2 = obj2;
            return [tps2.dateTaken compare:tps1.dateTaken];
        }];
        
        [_moc save:nil];
        
        _takenPictureSet = tps;
    }
    else { //check and make sure unfinished uploads are reset
        for (PPTakenPicture* tp in _takenPictureSet.takenPictures) {
            if ([tp.takenPictureID isEqualToNumber:PP_UPLOADING]) {
                tp.takenPictureID = nil;
                [_moc save:nil];
            }
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    
}

#pragma mark - IBActions
- (IBAction)uploadPictureSet:(id)sender {
    int numberOfPictures = 0;
    
    for (PPTakenPicture* tp in _takenPictureSet.takenPictures) {
        if (tp.imagePath && !tp.takenPictureID) {
            ++numberOfPictures;
        }
    }
    
    if (numberOfPictures == 0) {
        [[[UIAlertView alloc] initWithTitle:@"No Pictures" message:@"There are no pictures to upload." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil] show];
        return;
    }
    
    if (!_delegate.phoneNumber) {
        [_delegate addObserver:self forKeyPath:@"phoneNumber" options:NSKeyValueObservingOptionNew context:nil];
        [_delegate presentInitialPhoneNumberAlert];
    }
    else if (!_takenPictureSet.takenPictureSetID){
        [self addPictureSet];
    }
    else {
        [self addPictures];
    }
}

#pragma mark - KVO methods
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"takenPictureSetID"]) {
        [self addPictures];
    }
    else if ([keyPath isEqualToString:@"phoneNumber"]) {
        [_delegate removeObserver:self forKeyPath:@"phoneNumber"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!_takenPictureSet.takenPictureSetID) {
                [self addPictureSet];
            }
            else {
                [self addPictures];
            }
        });
    }
}

#pragma mark - private methods
- (void)addPictureSet {
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    df.timeZone = [NSTimeZone timeZoneWithName:@"America/New_York"];
    df.dateFormat = PP_DATE_FORMAT;
    NSString* dateString = [df stringFromDate:_takenPictureSet.dateTaken];
    dateString = [dateString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString* urlString = [NSString stringWithFormat:@"/app/AddPictureSet?postId=%d&mobilePhone=%@&pictureSetTimestamp=%@", _takenPictureSet.post.postID.intValue, _delegate.phoneNumber, dateString];
    NSURL* url = [NSURL URLWithString:urlString relativeToURL:PPURL];
    
    [_takenPictureSet addObserver:self forKeyPath:@"takenPictureSetID" options:NSKeyValueObservingOptionNew context:nil];
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary* pictureSetIDdictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        if (!pictureSetIDdictionary[@"error"]) {
            _takenPictureSet.takenPictureSetID = pictureSetIDdictionary[@"pictureSetId"];
            [_moc save:nil];
            [_takenPictureSet removeObserver:self forKeyPath:@"takenPictureSetID"];
        }
    }] resume];
    [session finishTasksAndInvalidate];
}

- (void)addPictures {
    NSArray* orientations = @[@"N", @"NE", @"E", @"SE", @"S", @"SW", @"W", @"NW", @"UP"];
    NSString* boundary = @"----------PPPPPPPPPP";
    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"UploadSession"] delegate:_uploadDelegate delegateQueue:[NSOperationQueue mainQueue]];
    
    for (int i = 0; i < 9; ++i) {
        PPTakenPicture* tp = _takenPictureSet.takenPictures[i];
        
        if (!tp.imagePath || tp.takenPictureID) {
            continue;
        }
        else {
            NSString* contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
            NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/app/AddPicture" relativeToURL:PPURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
            request.HTTPMethod = @"POST";
            [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
            
            NSURL* bodyDataFileURL = [self uploadFileForTakenPicture:tp withOrientation:orientations[i]];
            
            tp.takenPictureID = PP_UPLOADING;
            
            NSURLSessionUploadTask* uploadTask = [session uploadTaskWithRequest:request fromFile:bodyDataFileURL];
            
            _uploadDelegate.takenPictureForTask[uploadTask] = tp;
            _delegate.uploadDelegate = _uploadDelegate;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
            });
            
            [uploadTask resume];
        }
    }
    
    [session finishTasksAndInvalidate];
}

- (NSData*)bodyDataForTakenPicture:(PPTakenPicture*)takenPicture withOrientation:(NSString*)orientation andBoundary:(NSString*)boundary {
    NSMutableData* body = [NSMutableData data];
    NSDictionary* params = @{@"pictureSetId": takenPicture.takenPictureSet.takenPictureSetID,
                             @"orientation": orientation};
    
    for (NSString* param in params) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", param] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@\r\n", [params objectForKey:param]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    NSData *imageData = UIImageJPEGRepresentation([UIImage imageWithData:[NSData dataWithContentsOfFile:takenPicture.imagePath]], 0.5);
    if (imageData) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:imageData];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return body;
}

//returns the URL for the temp file if it could be created
//returns nil if it could not
- (NSURL*)uploadFileForTakenPicture:(PPTakenPicture*)takenPicture withOrientation:(NSString*) orientation{
    NSData* bodyData = [self bodyDataForTakenPicture:takenPicture withOrientation:orientation andBoundary:@"----------PPPPPPPPPP"];
    
    NSString* fileName = [NSString stringWithFormat:@"%@-%@", takenPicture.takenPictureSet.takenPictureSetID, orientation];
    NSURL* tempDirectoryURL = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL* tempFileURL = [NSURL URLWithString:fileName relativeToURL:tempDirectoryURL];
    
    if ([bodyData writeToURL:tempFileURL atomically:YES]) {
        return tempFileURL;
    }
    else {
        return nil;
    }
}

#pragma mark - UIImagePickerControllerDelegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage* originalImage = info[UIImagePickerControllerOriginalImage];
    
    if (originalImage.size.width > originalImage.size.height) {
        PPTakenPicture* tp = _takenPictureSet.takenPictures[_indexForPicker];

        CGSize thumbnailSize = CGSizeMake(640, 480);
        UIGraphicsBeginImageContext(thumbnailSize);
        [originalImage drawInRect:CGRectMake(0, 0, thumbnailSize.width, thumbnailSize.height)];
        UIImage* thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSData* thumbnailData = UIImageJPEGRepresentation(thumbnailImage, 0.85);
        [tp saveThumbnailData:thumbnailData WithFileName:[NSString stringWithFormat:@"t_%d.jpg", (int)_indexForPicker]];

        [_moc save:nil];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSData* shrunkData = UIImageJPEGRepresentation(originalImage, 0.5);
            
            [tp saveImageData:shrunkData WithFileName:[NSString stringWithFormat:@"%d.jpg", (int)_indexForPicker]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_moc save:nil];
            });
        });
        
        [self.collectionView reloadData];
        
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:_indexForPicker inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];

        [self dismissViewControllerAnimated:YES completion:^{
            [[UIApplication sharedApplication] setStatusBarHidden:NO];
            
            if (_indexForPicker < 8) {
                PPTakenPicture* nextTP = _takenPictureSet.takenPictures[_indexForPicker + 1];
                
                if (!nextTP.imagePath) {
                    NSString* nextDirection = _directions[_indexForPicker + 1];
                    NSString* title = [NSString stringWithFormat:@"Take %@ Picture?", nextDirection];
                    
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:@"Don't Take" otherButtonTitles:@"Take", nil];
                    alert.tag = PP_NEXT_IMAGE_ALERT_TAG;
                    [alert show];
                }
            }
        }];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:^{
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Pictures must be taken horizontally." message:nil delegate:self cancelButtonTitle:@"Close" otherButtonTitles:@"Retake", nil];
            [alert show];
        }];
    }
}

#pragma mark - UICollectionViewDataSource methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 9;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PPTakenPictureCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TakenPictureCell" forIndexPath:indexPath];
    cell.directionLabel.backgroundColor = [UIColor ppDarkGreenColor];
    cell.directionLabel.textColor = [UIColor whiteColor];
    cell.progressView.hidden = YES;
    
    PPTakenPicture* tp = _takenPictureSet.takenPictures[indexPath.row];
    
    if (tp.takenPictureID) {
        if ([tp.takenPictureID isEqualToNumber:PP_UPLOADING]) {
            cell.directionLabel.text = [NSString stringWithFormat:@"Uploading %@", _directions[indexPath.row]];
            cell.directionLabel.backgroundColor = [UIColor ppUploadingColor];
            cell.directionLabel.textColor = [UIColor blackColor];
            
            [cell.progressView setProgress:[_uploadDelegate progressForTakenPicture:tp] animated:NO];
            cell.progressView.hidden = NO;
        }
        else {
            cell.directionLabel.backgroundColor = [UIColor ppUploadedColor];

            cell.directionLabel.text = [NSString stringWithFormat:@"%@ (Uploaded)", _directions[indexPath.row]];
        }
    }
    else {
        cell.directionLabel.text = _directions[indexPath.row];
    }

    if (!tp.thumbnailPath) {
        cell.imageView.image = [UIImage imageNamed:@"PPLogo"];
        cell.imageView.contentMode = UIViewContentModeCenter;
        cell.helpLabel.hidden = NO;
    }
    else {
        NSData* dataForImage = [NSData dataWithContentsOfFile:tp.thumbnailPath];
        cell.imageView.image = [UIImage imageWithData:dataForImage];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.helpLabel.hidden = YES;
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate methods
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    _indexForPicker = indexPath.row;
    
    [self presentViewController:_ipc animated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PPTakenPicture* tp = _takenPictureSet.takenPictures[indexPath.row];
    
    if (tp.takenPictureID) {
        return NO;
    }
    else {
        return YES;
    }
}

#pragma mark - UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if (alertView.tag == PP_NEXT_IMAGE_ALERT_TAG) {
            _indexForPicker = _indexForPicker + 1;
        }
        
        [self presentViewController:_ipc animated:YES completion:^{
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
        }];
    }
}

@end
