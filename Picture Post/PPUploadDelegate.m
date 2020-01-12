//
//  PPUploadDelegate.m
//  Picture Post
//
//  Created by Ilya Atkin on 9/5/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import "PPTakenPicture.h"
#import "PPUploadDelegate.h"

@implementation PPUploadDelegate {
    NSMutableDictionary* _progressAtLastReloadForTask;
}

- (id)initWithCollectionView:(UICollectionView*)collectionView andManagedObjectContext:(NSManagedObjectContext *)moc{
    self = ([super init]);
    
    if (self) {
        _dataForTask = [NSMutableDictionary dictionary];
        _progressForTask = [NSMutableDictionary dictionary];
        _takenPictureForTask = [NSMutableDictionary dictionary];
        _progressAtLastReloadForTask = [NSMutableDictionary dictionary];
        _collectionView = collectionView;
        _moc = moc;
    }
    
    return self;
}


//returns -1 if there is no upload for the picture
//this happens in the event the app crashes while an upload is occurring
- (float)progressForTakenPicture:(PPTakenPicture *)takenPicture {
    NSArray* tasksForTakenPicture = [_takenPictureForTask allKeysForObject:takenPicture];
    
    if (tasksForTakenPicture.count == 0) {
        return -1;
    }
    else {
        NSURLSessionTask* task = [_takenPictureForTask allKeysForObject:takenPicture][0];
        NSNumber* progress = _progressForTask[task];
        
        return progress.floatValue;
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    NSNumber* progress = @((double)totalBytesSent/totalBytesExpectedToSend);
    _progressForTask[task] = progress;
    
    if (!_progressAtLastReloadForTask[task]) {
        _progressAtLastReloadForTask[task] = @0;
    }

    NSNumber* progressAtLastReload = _progressAtLastReloadForTask[task];
    float differenceInProgress = progress.floatValue - progressAtLastReload.floatValue;
    
    if (differenceInProgress > 0.1) {
        _progressAtLastReloadForTask[task] = progress;
        
        PPTakenPicture* tp = _takenPictureForTask[task];
        
        [_collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:tp.direction.intValue inSection:0]]];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (_dataForTask[dataTask] == nil) {
        _dataForTask[dataTask] = [NSMutableData data];
    }
    
    [_dataForTask[dataTask] appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (!error && _dataForTask[task]) {
        PPTakenPicture* tp = _takenPictureForTask[task];
        
        NSDictionary* pictureIdDictionary = [NSJSONSerialization JSONObjectWithData:_dataForTask[task] options:0 error:nil];
        
        if (pictureIdDictionary[@"pictureId"]) {
            tp.takenPictureID = pictureIdDictionary[@"pictureId"];
            
            [_moc save:nil];
        }
        else if (pictureIdDictionary[@"error"]) {
            NSArray* errorArray = pictureIdDictionary[@"error"];
            
            if (errorArray.count > 1) {
                NSString* numberString = errorArray[1];
                NSNumber* pictureId = @(atoi(numberString.UTF8String));

                tp.takenPictureID = pictureId;
                [_moc save:nil];
                
                //for whatever reason, the collection view will not reload if called directly
                [self performSelector:@selector(reloadCollectionViewData) withObject:nil afterDelay:0.5];
            }
        }
    }
    else if (!_dataForTask[task]) {
        PPTakenPicture* tp = _takenPictureForTask[task];
        tp.takenPictureID = nil;
    }
    
    [_collectionView reloadData];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    _completionHandler();
}

- (void)reloadCollectionViewData {
    [_collectionView reloadData];
}

@end
