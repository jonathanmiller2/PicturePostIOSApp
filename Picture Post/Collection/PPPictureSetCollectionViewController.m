//
//  PPPictureSetCollectionViewController.m
//  Picture Post
//
//  Created by Ilya Atkin on 8/29/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import "PPPictureSetCollectionViewController.h"
#import "PPPicture.h"
#import "PPPictureCell.h"
#import "PPPictureSet.h"
#import "PPPictureViewController.h"
#import "PPPost.h"
#import "UIColor+PPColors.h"

@interface PPPictureSetCollectionViewController () {
    NSArray* _directions;
    NSMutableDictionary* _imageDataForPicture;
}

@end

@implementation PPPictureSetCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _directions = @[@"North", @"North East", @"East", @"South East", @"South", @"South West", @"West", @"North West", @"Up"];
    _imageDataForPicture = [NSMutableDictionary dictionary];
    
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"MM/dd/yy hh:mm a";
    
    self.navigationItem.title = [df stringFromDate:_pictureSet.dateTaken];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet)];
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    for (PPPicture* picture in _pictureSet.pictures) {
        if (picture.pictureID.intValue != 0) {
            NSURL* pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"/images/pictures/post_%d/picture_%d_medium.jpg", _pictureSet.post.postID.intValue, picture.pictureID.intValue] relativeToURL:PPURL];
            
            [[session dataTaskWithURL:pictureURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                _imageDataForPicture[picture.pictureID] = data;
                
                int pictureIndex = (int)[_pictureSet.pictures indexOfObject:picture];
                BOOL pictureVisible = [self.collectionView.indexPathsForVisibleItems containsObject:[NSIndexPath indexPathForItem:pictureIndex inSection:0]];

                if (pictureVisible) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.collectionView reloadData];
                    });
                }
                
            }] resume];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.collectionView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)showActionSheet {
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Close" destructiveButtonTitle:@"Report Offensive Content" otherButtonTitles: nil];
    
    [actionSheet showInView:self.collectionView];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        int pictureSetID = self.pictureSet.pictureSetID.intValue;
        NSURL* reportURL = [NSURL URLWithString:[NSString stringWithFormat:@"/app/FlagPictureSet?pictureSetId=%d", pictureSetID] relativeToURL:PPURL];
        NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        
        [[session dataTaskWithURL:reportURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            UIAlertView* errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"This picture set could not be reported." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
            
            if (!error) {
                NSDictionary* responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                if (responseDictionary[@"reported"]) {
                    UIAlertView* reportedContentAlert = [[UIAlertView alloc] initWithTitle:nil message:@"This picture set has been reported" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [reportedContentAlert show];
                        [self.navigationController popViewControllerAnimated:YES];
                    });
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [errorAlert show];
                    });
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [errorAlert show];
                });
            }
        }] resume];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 9;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PPPictureCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PictureCell" forIndexPath:indexPath];
    cell.directionLabel.text = _directions[indexPath.row];
    
    PPPicture* picture = _pictureSet.pictures[indexPath.row];
    
    if (picture.pictureID.intValue == 0) {
        [cell endLoadingIndication];
        cell.helpLabel.hidden = NO;
        cell.helpLabel.text = @"No photo available";
        cell.imageView.image = [UIImage imageNamed:@"PPLogo"];
        cell.imageView.contentMode = UIViewContentModeCenter;
        
        cell.backgroundColor = [UIColor blackColor];
        cell.helpLabel.textColor = [UIColor whiteColor];
        cell.directionLabel.backgroundColor = [UIColor blackColor];
        
        cell.layer.borderWidth = 0.5;
        cell.layer.borderColor = [UIColor ppDarkGreenColor].CGColor;
    }
    else {
        if (_imageDataForPicture[picture.pictureID]) {
            [cell endLoadingIndication];
            cell.imageView.image = [UIImage imageWithData:_imageDataForPicture[picture.pictureID]];
            cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
            cell.helpLabel.hidden = YES;
            
            if (cell.imageView.image.size.width > cell.imageView.image.size.height) {
                cell.backgroundColor = [UIColor ppDarkGreenColor];
            }
            else {
                cell.backgroundColor = [UIColor ppVeryLightGreenColor];
            }
        }
        else {
            cell.imageView.image = [UIImage imageNamed:@"PPLogo"];
            cell.imageView.contentMode = UIViewContentModeCenter;
            cell.backgroundColor = [UIColor ppVeryLightGreenColor];
            cell.helpLabel.hidden = NO;
            cell.helpLabel.text = @"Loading";
            [cell startLoadingIndication];
        }
        
        cell.helpLabel.textColor = [UIColor blackColor];
        cell.directionLabel.backgroundColor = [UIColor ppDarkGreenColor];
        cell.layer.borderWidth = 0.0;
    }
    
    return cell;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PPPicture* picture = _pictureSet.pictures[indexPath.row];
    
    return (picture.pictureID.intValue != 0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PPPictureViewController* pvc = [self.storyboard instantiateViewControllerWithIdentifier:@"PictureView"];
    pvc.picture = _pictureSet.pictures[indexPath.row];
    pvc.navigationItem.title = _directions[indexPath.row];

    [self.navigationController pushViewController:pvc animated:YES];
}

@end
