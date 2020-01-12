//
//  PPTakenPicture.h
//  Picture Post
//
//  Created by Ilya Atkin on 8/12/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PPTakenPictureSet;

@interface PPTakenPicture : NSManagedObject

@property (nonatomic, retain) PPTakenPictureSet *takenPictureSet;
@property (nonatomic, retain) NSNumber* takenPictureID;
@property (nonatomic, retain) NSString* imagePath;
@property (nonatomic, retain) NSNumber* direction;
@property (nonatomic, retain) NSString* thumbnailPath;

- (BOOL)saveImageData:(NSData*)imageData WithFileName:(NSString*)fileName;
- (BOOL)saveThumbnailData:(NSData*)thumbnailData WithFileName:(NSString*)fileName;

@end
