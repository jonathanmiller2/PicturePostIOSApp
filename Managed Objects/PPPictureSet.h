//
//  PPPictureSet.h
//  Picture Post
//
//  Created by Ilya Atkin on 8/12/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PPPicture, PPPost;

@interface PPPictureSet : NSManagedObject

@property (nonatomic, retain) NSDate * dateTaken;
@property (nonatomic, retain) NSOrderedSet *pictures;
@property (nonatomic, retain) PPPost *post;
@property (nonatomic, retain) NSNumber* pictureSetID;

+ (PPPictureSet*)insertPictureSetFromDictionary:(NSDictionary*)dictionary forPost:(PPPost*)post inContext:(NSManagedObjectContext*)moc;


@end

@interface PPPictureSet (CoreDataGeneratedAccessors)

- (void)insertObject:(PPPicture *)value inPicturesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPicturesAtIndex:(NSUInteger)idx;
- (void)insertPictures:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePicturesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPicturesAtIndex:(NSUInteger)idx withObject:(PPPicture *)value;
- (void)replacePicturesAtIndexes:(NSIndexSet *)indexes withPictures:(NSArray *)values;
- (void)addPicturesObject:(PPPicture *)value;
- (void)removePicturesObject:(PPPicture *)value;
- (void)addPictures:(NSOrderedSet *)values;
- (void)removePictures:(NSOrderedSet *)values;
@end
