//
//  PPTakenPictureSet.h
//  Picture Post
//
//  Created by Ilya Atkin on 8/12/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PPTakenPicture.h"

@class PPPost;

@interface PPTakenPictureSet : NSManagedObject

@property (nonatomic, retain) NSDate * dateTaken;
@property (nonatomic, retain) NSOrderedSet *takenPictures;
@property (nonatomic, retain) PPPost *post;
@property (nonatomic, retain) NSNumber* takenPictureSetID;

- (NSString*)imageDirectoryInDirectory:(NSString*)directory;

@end

@interface PPTakenPictureSet (CoreDataGeneratedAccessors)

- (void)insertObject:(PPTakenPicture *)value inTakenPicturesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromTakenPicturesAtIndex:(NSUInteger)idx;
- (void)insertTakenPictures:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeTakenPicturesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInTakenPicturesAtIndex:(NSUInteger)idx withObject:(PPTakenPicture *)value;
- (void)replaceTakenPicturesAtIndexes:(NSIndexSet *)indexes withTakenPictures:(NSArray *)values;
- (void)addTakenPicturesObject:(PPTakenPicture *)value;
- (void)removeTakenPicturesObject:(PPTakenPicture *)value;
- (void)addTakenPictures:(NSOrderedSet *)values;
- (void)removeTakenPictures:(NSOrderedSet *)values;
@end
