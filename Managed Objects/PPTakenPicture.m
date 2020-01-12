//
//  PPTakenPicture.m
//  Picture Post
//
//  Created by Ilya Atkin on 8/12/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import "PPPost.h"
#import "PPTakenPicture.h"
#import "PPTakenPictureSet.h"

@implementation PPTakenPicture

@dynamic takenPictureSet;
@dynamic takenPictureID;
@dynamic imagePath;
@dynamic direction;
@dynamic thumbnailPath;

- (BOOL)saveImageData:(NSData *)imageData WithFileName:(NSString *)fileName {
    NSString* imageDirectory = [self.takenPictureSet imageDirectoryInDirectory:[@"~/Documents" stringByExpandingTildeInPath]];
    
    BOOL wroteImage = [self writeData:imageData withFileName:fileName toDirectory:imageDirectory];
    
    if (wroteImage) {
        self.imagePath = [imageDirectory stringByAppendingPathComponent:fileName];
    }
    
    return wroteImage;
}

- (BOOL)saveThumbnailData:(NSData *)thumbnailData WithFileName:(NSString *)fileName {
    NSString* thumbnailDirectory = [self.takenPictureSet imageDirectoryInDirectory:[@"~/Library" stringByExpandingTildeInPath]];
    
    BOOL wroteThumbnail = [self writeData:thumbnailData withFileName:fileName toDirectory:thumbnailDirectory];
    
    if (wroteThumbnail) {
        self.thumbnailPath = [thumbnailDirectory stringByAppendingPathComponent:fileName];
    }
    
    return wroteThumbnail;
}

- (BOOL)writeData:(NSData*)data withFileName:(NSString*)fileName toDirectory:(NSString*)directory{
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString* dataPath = [directory stringByAppendingPathComponent:fileName];
    BOOL wroteData = [data writeToFile:dataPath atomically:YES];
    
    return wroteData;
}
@end
