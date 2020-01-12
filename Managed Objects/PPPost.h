//
//  PPPost.h
//  Picture Post
//
//  Created by Ilya Atkin on 8/6/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PPPictureSet;

@interface PPPost : NSManagedObject <MKAnnotation>

@property (nonatomic, retain) NSNumber * postID;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * postDescription;
@property (nonatomic, retain) NSDate * installDate;
@property (nonatomic, retain) NSDate * referencePictureSetID;
@property (nonatomic, retain) NSNumber * lat;
@property (nonatomic, retain) NSNumber * lon;
@property (nonatomic, retain) NSNumber * postPictureID;
@property (nonatomic, retain) NSMutableOrderedSet *pictureSets;
@property (nonatomic, retain) NSMutableOrderedSet *takenPictureSets;
@property (nonatomic, retain) NSNumber* favorite;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *subtitle;
@property (nonatomic, readonly, copy) NSString *title;

+ (PPPost*)postFromDictionary:(NSDictionary*)dictionary inContext:(NSManagedObjectContext*)moc;

@end

@interface PPPost (CoreDataGeneratedAccessors)

- (void)insertObject:(PPPictureSet *)value inPictureSetsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPictureSetsAtIndex:(NSUInteger)idx;
- (void)insertPictureSets:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePictureSetsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPictureSetsAtIndex:(NSUInteger)idx withObject:(PPPictureSet *)value;
- (void)replacePictureSetsAtIndexes:(NSIndexSet *)indexes withPictureSets:(NSArray *)values;
- (void)addPictureSetsObject:(PPPictureSet *)value;
- (void)removePictureSetsObject:(PPPictureSet *)value;
- (void)addPictureSets:(NSOrderedSet *)values;
- (void)removePictureSets:(NSOrderedSet *)values;
- (void)insertObject:(NSManagedObject *)value inTakenPictureSetsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromTakenPictureSetsAtIndex:(NSUInteger)idx;
- (void)insertTakenPictureSets:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeTakenPictureSetsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInTakenPictureSetsAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceTakenPictureSetsAtIndexes:(NSIndexSet *)indexes withTakenPictureSets:(NSArray *)values;
- (void)addTakenPictureSetsObject:(NSManagedObject *)value;
- (void)removeTakenPictureSetsObject:(NSManagedObject *)value;
- (void)addTakenPictureSets:(NSOrderedSet *)values;
- (void)removeTakenPictureSets:(NSOrderedSet *)values;
@end
