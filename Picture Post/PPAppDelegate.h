//
//  PPAppDelegate.h
//  Picture Post
//
//  Created by Ilya Atkin on 8/6/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SSKeychain, PPUploadDelegate;

@interface PPAppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property NSString* phoneNumber;
//@property SSKeychain* keychainItemForPhoneNumber;
@property PPUploadDelegate* uploadDelegate;
@property NSMutableSet* annotationsToReload;

- (NSManagedObjectContext*)managedObjectContext;

- (void)removePhoneNumber;
- (void)presentInitialPhoneNumberAlert;
- (void)presentFirstRunAlert;

@end
