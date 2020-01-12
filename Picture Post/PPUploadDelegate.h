//
//  PPUploadDelegate.h
//  Picture Post
//
//  Created by Ilya Atkin on 9/5/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PPTakenPicture;

@interface PPUploadDelegate : NSObject <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property NSMutableDictionary* dataForTask;
@property NSMutableDictionary* progressForTask;
@property NSMutableDictionary* takenPictureForTask;
@property NSManagedObjectContext* moc;

@property (nonatomic, strong) void (^completionHandler)(void);

@property UICollectionView* collectionView;

- (id)initWithCollectionView:(UICollectionView*)collectionView andManagedObjectContext:(NSManagedObjectContext*)moc;
- (float)progressForTakenPicture:(PPTakenPicture*)takenPicture;

@end
