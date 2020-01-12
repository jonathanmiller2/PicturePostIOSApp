//
//  PPPictureSet.m
//  Picture Post
//
//  Created by Ilya Atkin on 8/12/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import "PPPictureSet.h"
#import "PPPicture.h"
#import "PPPost.h"


@implementation PPPictureSet

@dynamic dateTaken;
@dynamic pictures;
@dynamic post;
@dynamic pictureSetID;

+ (PPPictureSet*)insertPictureSetFromDictionary:(NSDictionary *)dictionary forPost:(PPPost *)post inContext:(NSManagedObjectContext *)moc {
    NSFetchRequest* fr = [[NSFetchRequest alloc] initWithEntityName:@"PPPictureSet"];
    fr.predicate = [NSPredicate predicateWithFormat:@"pictureSetID = %@", dictionary[@"pictureSetId"]];
    NSArray* results = [moc executeFetchRequest:fr error:nil];
    
    if (results.count > 0) {
        return results[0];
    }
    
    PPPictureSet* pictureSet = [NSEntityDescription insertNewObjectForEntityForName:@"PPPictureSet" inManagedObjectContext:moc];
    pictureSet.post = post;
    pictureSet.pictureSetID = dictionary[@"pictureSetId"];
    
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    df.dateFormat = PP_DATE_FORMAT;
    pictureSet.dateTaken = [df dateFromString:dictionary[@"pictureSetTimeStamp"]];
    
    for (NSNumber* n in dictionary[@"pictureIds"]) {
        PPPicture* p = [NSEntityDescription insertNewObjectForEntityForName:@"PPPicture" inManagedObjectContext:moc];
        p.pictureID = n;
        p.pictureSet = pictureSet;
    }
    
    return pictureSet;
}

@end
