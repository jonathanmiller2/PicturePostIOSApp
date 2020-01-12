//
//  PPPictureSetTableViewController.h
//  Picture Post
//
//  Created by Ilya Atkin on 8/8/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PPPost;

@interface PPPostTableViewController : UITableViewController <NSURLSessionDelegate, NSURLSessionTaskDelegate>

@property PPPost* post;
@property NSManagedObjectContext* moc;

- (IBAction)toggleFavorite:(id)sender;

@end
