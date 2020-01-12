//
//  PPPostTableViewController.h
//  Picture Post
//
//  Created by Ilya Atkin on 8/29/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPPostListTableViewController : UITableViewController <CLLocationManagerDelegate>

@property BOOL favoriteList;

- (IBAction)changeSorting:(UISegmentedControl *)sender;
@end
