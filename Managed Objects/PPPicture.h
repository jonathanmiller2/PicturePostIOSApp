//
//  PPPicture.h
//  Picture Post
//
//  Created by Ilya Atkin on 8/12/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PPPictureSet;

@interface PPPicture : NSManagedObject

@property (nonatomic, retain) NSNumber * pictureID;
@property (nonatomic, retain) PPPictureSet *pictureSet;
@property NSMutableData* thumbnailData;

@end
