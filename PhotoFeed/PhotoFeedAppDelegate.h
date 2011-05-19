//
//  PhotoFeedAppDelegate.h
//  PhotoFeed
//
//  Created by Peter Shih on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginDelegate.h"
#import "PSDataCenterDelegate.h"

@class Facebook;
@class LoginViewController;
@class AlbumViewController;
@class LoginDataCenter;

@interface PhotoFeedAppDelegate : NSObject <UIApplicationDelegate, LoginDelegate, PSDataCenterDelegate> {
  UIWindow *_window;
  Facebook *_facebook;
  LoginViewController *_loginViewController;
  AlbumViewController *_albumViewController;;
  UINavigationController *_navigationController;
  
  LoginDataCenter *_loginDataCenter;
  
  // Session
  NSString *_sessionKey;
}

@property (nonatomic, retain) UIWindow *window;
@property (readonly) Facebook *facebook;
@property (retain) NSString *sessionKey;

// Private
+ (void)setupDefaults;
- (void)animateHideLogin;
- (void)startSession;
- (void)startRegister;
- (void)tryLogin;
- (void)resetSessionKey;

@end
