//
//  PPPost.m
//  Picture Post
//
//  Created by Ilya Atkin on 8/6/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import "PPPost.h"
#import "PPPictureSet.h"


@implementation PPPost

@dynamic postID;
@dynamic name;
@dynamic postDescription;
@dynamic installDate;
@dynamic referencePictureSetID;
@dynamic lat;
@dynamic lon;
@dynamic postPictureID;
@dynamic pictureSets;
@dynamic takenPictureSets;
@dynamic favorite;

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(self.lat.floatValue, self.lon.floatValue);
}

- (NSString*)subtitle {
    return self.postDescription;
}

- (NSString*)title {
    return self.name;
}

+ (PPPost*)postFromDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)moc {
    NSFetchRequest* fr = [NSFetchRequest fetchRequestWithEntityName:@"PPPost"];
    fr.predicate = [NSPredicate predicateWithFormat:@"postID=%@", dictionary[@"postId"]];
    NSArray* posts = [moc executeFetchRequest:fr error:nil];
    
    if (posts.count > 0) {
        PPPost* post = posts[0];
        post.lat = dictionary[@"lat"];
        post.lon = dictionary[@"lon"];
        post.name = dictionary[@"name"];
        post.postDescription = dictionary[@"description"];
        post.postPictureID = dictionary[@"postPictureId"];
        
        [moc save:nil];
        
        return Nil;
    }
    
    PPPost* post = [NSEntityDescription insertNewObjectForEntityForName:@"PPPost" inManagedObjectContext:moc];
    post.postID = dictionary[@"postId"];
    post.name = dictionary[@"name"];
    post.postDescription = dictionary[@"description"];
    post.postPictureID = dictionary[@"postPictureId"];
    post.lat = dictionary[@"lat"];
    post.lon = dictionary[@"lon"];
    
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy-MM-dd";
    post.installDate = [df dateFromString:dictionary[@"installDate"]];
    
    return post;
}

@end
