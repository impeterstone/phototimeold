//
//  PhotoTimeAppDelegate.h
//  PhotoTime
//
//  Created by Peter Shih on 3/23/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginDelegate.h"
#import "PSDataCenterDelegate.h"
#import "PSExposeController.h"
#import "SearchTermDelegate.h"
#import "PSTextField.h"

@class Facebook;
@class SplashViewController;
@class LoginViewController;
@class LoginDataCenter;
@class AlbumDataCenter;
@class SearchTermController;

@interface PhotoTimeAppDelegate : NSObject <UIApplicationDelegate, LoginDelegate, PSDataCenterDelegate, PSExposeControllerDelegate, PSExposeControllerDataSource, UITextFieldDelegate, SearchTermDelegate, UINavigationControllerDelegate> {
  UIWindow *_window;
  Facebook *_facebook;
  SplashViewController *_splashViewController;
  LoginViewController *_loginViewController;
  UINavigationController *_navController;
  
  AlbumDataCenter *_albumDataCenter;
  
  // Session
  NSString *_sessionKey;
  
  // Search
  PSTextField *_searchField;
  UIBarButtonItem *_filterButton;
  UIBarButtonItem *_cancelButton;
  SearchTermController *_searchTermController;
  BOOL _searchActive;
}

@property (nonatomic, retain) UIWindow *window;
@property (readonly) Facebook *facebook;
@property (retain) NSString *sessionKey;

// Private
+ (void)setupDefaults;
- (void)animateHideLogin;
- (void)startSession;
- (void)startDownloadAlbums;
- (void)tryLogin;
- (void)resetSessionKey;

- (void)getMe;
- (void)serializeMeWithResponse:(id)response;
- (void)getFriends;
- (void)serializeFriendsWithResponse:(id)response shouldDownload:(BOOL)shouldDownload;

- (void)updateLoginProgress:(NSNotification *)notification;
- (void)updateLoginProgressOnMainThread:(NSDictionary *)userInfo;

// Search
- (void)setupSearch;
- (void)filter;
- (void)search;
- (void)cancelSearch;
- (void)searchWithText:(NSString *)searchText;

@end
