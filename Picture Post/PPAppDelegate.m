//
//  PPAppDelegate.m
//  Picture Post
//
//  Created by Ilya Atkin on 8/6/13.
//  Copyright (c) 2013 Ilya Atkin. All rights reserved.
//

#import <Security/Security.h>
#import "SSKeychain.h"
#import "PPAppDelegate.h"
#import "PPUploadDelegate.h"

#define PP_LOGIN_TAG 101
#define PP_SAVE_TAG 102
#define PP_FIRST_TAG 103

@implementation PPAppDelegate {
    NSManagedObjectContext* _moc;
    NSManagedObjectModel* _mom;
    NSPersistentStoreCoordinator* _psc;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _annotationsToReload = [NSMutableSet set];
    
    _phoneNumber = [SSKeychain passwordForService:@"pp" account:@"self"];
    
    return YES;
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    _uploadDelegate.completionHandler = completionHandler;
    
    UILocalNotification* notification = [[UILocalNotification alloc] init];
    notification.alertBody = @"Picture set upload complete.";
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];

    NSURLSessionConfiguration* backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:backgroundConfiguration delegate:_uploadDelegate delegateQueue:[NSOperationQueue mainQueue]];
    [session finishTasksAndInvalidate];
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (NSManagedObjectContext*)managedObjectContext {
    if (_moc == nil) {
        NSURL* modelURL = [[NSBundle mainBundle] URLForResource:@"PicturePostModel" withExtension:@"momd"];
        _mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSURL* pathURL = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
        
        NSURL* storeURL = [pathURL URLByAppendingPathComponent:@"PicturePostModel.sqlite"];
        
        _psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_mom];
        [_psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:nil];
        
        _moc = [[NSManagedObjectContext alloc] init];
        _moc.persistentStoreCoordinator = _psc;
    }
    
    return _moc;
}

#pragma mark - UIAlertView delegate methods
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == PP_LOGIN_TAG && buttonIndex == 1) {
        [self validatePhoneNumber:[alertView textFieldAtIndex:0].text];
    }
    else if (alertView.tag == PP_LOGIN_TAG && buttonIndex == 2) {
        NSURL* registrationURL = [NSURL URLWithString:@"/registration.jsp" relativeToURL:PPURL];
        NSString* registrationURLString = [registrationURL absoluteString];
        
        //openURL has a bug where URLs recreated with a relativeURL do not open
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:registrationURLString]];
    }
    else if (alertView.tag == PP_SAVE_TAG && buttonIndex == 1) {
        [SSKeychain setPassword:_phoneNumber forService:@"pp" account:@"self"];
    }
    else if (alertView.tag == PP_FIRST_TAG && buttonIndex == 1) {
        NSURL* instructionsURL = [NSURL URLWithString:@"http://www.unh.edu/nem/mobile/apps/picture-post/instructions.html"];
        [[UIApplication sharedApplication] openURL:instructionsURL];
    }
}

#pragma mark - private methods - phone number
- (void)presentInitialPhoneNumberAlert {
    [self presentPhoneNumberAlertWithTitle:nil andMessage:@"Please enter the number associated with your Picture Post account"];
}

- (void)presentFirstRunAlert {
    BOOL firstRun = [SSKeychain passwordForService:@"pp" account:@"firstRun"] == nil;
    
    if (firstRun) {
        UIAlertView* firstRunAlert = [[UIAlertView alloc] initWithTitle:@"Welcome to Picture Post" message:@"Do you need instructions on how to use Picture Post?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Instructions", nil];
        firstRunAlert.tag = PP_FIRST_TAG;
        [firstRunAlert show];
        
        [SSKeychain setPassword:@"RAN" forService:@"pp" account:@"firstRun"];
    }
}

- (void)presentPhoneNumberAlertWithTitle:(NSString*)title andMessage:(NSString*)message {
    UIAlertView* phoneNumberAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Close" otherButtonTitles:@"Log In", @"Register", nil];
    phoneNumberAlert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    phoneNumberAlert.tag = PP_LOGIN_TAG;
    [phoneNumberAlert textFieldAtIndex:0].keyboardAppearance = UIKeyboardAppearanceLight;
    [phoneNumberAlert textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumberPad;
    
    //WORK AROUND: showing the alert was occassionally crashing because it wasn't being run on the main thread. I believe this is a bug in the SDK
    dispatch_async(dispatch_get_main_queue(), ^{
        [phoneNumberAlert show];
    });
}

- (void)retryPhoneNumberAlert {
    [self presentPhoneNumberAlertWithTitle:@"Invalid Number" andMessage:@"The number entered is not associated with a Picture Post account. Please try again."];
}

- (void)validatePhoneNumber:(NSString*)phoneNumber {
    NSURL* validationURL = [NSURL URLWithString:[NSString stringWithFormat:@"/app/IsValidMobilePhone?mobilePhone=%@", phoneNumber] relativeToURL:PPURL];
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 5.0;
    config.timeoutIntervalForResource = 10.0;
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    [[session dataTaskWithURL:validationURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSDictionary* validity = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            if ([validity[@"status"] isEqualToString:@"Valid"]) {
                [self storePhoneNumber:phoneNumber];
            }
            else {
                [self retryPhoneNumberAlert];
            }
        }
        else {
            [self showNetworkErrorAlert];
        }
    }] resume];
    [session finishTasksAndInvalidate];
}

- (void)showNetworkErrorAlert {
    [[[UIAlertView alloc] initWithTitle:@"Unable to Log In" message:@"You may not have enough Wi-Fi or cellular reception to contact Picture Post." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil] show];
}

- (void)storePhoneNumber:(NSString*)phoneNumber {
    self.phoneNumber = phoneNumber;
    
    UIAlertView* keychainAlert = [[UIAlertView alloc] initWithTitle:@"Save Number" message:@"Would you like to save your log in information?" delegate:self cancelButtonTitle:@"Require Log In" otherButtonTitles:@"Save", nil];
    keychainAlert.tag = PP_SAVE_TAG;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [keychainAlert show];
    });
}

- (void)removePhoneNumber {
    _phoneNumber = nil;
    [SSKeychain deletePasswordForService:@"pp" account:@"self"];
    
//    [_keychainItemForPhoneNumber resetKeychainItem];
}


@end
