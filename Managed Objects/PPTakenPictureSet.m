//
//  PPTakenPictureSet.m
//  Picture Post
//
//  Created by Ilya Atkin on 8/12/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import "PPTakenPictureSet.h"
#import "PPTakenPicture.h"
#import "PPPost.h"


@implementation PPTakenPictureSet

@dynamic dateTaken;
@dynamic takenPictures;
@dynamic post;
@dynamic takenPictureSetID;

- (NSString*)imageDirectoryInDirectory:(NSString*)directory {
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"MM\\dd\\yy hh.mm.ss a";
    
    return [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%@)", self.post.title, [df stringFromDate:self.dateTaken]]];
}

- (void)prepareForDeletion {
    NSString* imageDirectory = [self imageDirectoryInDirectory:[@"~/Documents" stringByExpandingTildeInPath]];
    NSString* thumbnailDirectory = [self imageDirectoryInDirectory:[@"~/Library" stringByExpandingTildeInPath]];
    
    [[NSFileManager defaultManager] removeItemAtPath:imageDirectory error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:thumbnailDirectory error:nil];
}

@end
