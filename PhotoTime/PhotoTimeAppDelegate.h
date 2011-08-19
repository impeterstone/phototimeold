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
#import "Facebook.h"

@class SplashViewController;
@class LoginViewController;
@class LoginDataCenter;
@class AlbumDataCenter;
@class SearchTermController;

@interface PhotoTimeAppDelegate : NSObject <UIApplicationDelegate, LoginDelegate, PSDataCenterDelegate, PSExposeControllerDelegate, PSExposeControllerDataSource, UITextFieldDelegate, SearchTermDelegate, UINavigationControllerDelegate, FBSessionDelegate, UIAlertViewDelegate> {
  UIWindow *_window;
  Facebook *_facebook;
  SplashViewController *_splashViewController;
  LoginViewController *_loginViewController;
  UINavigationController *_navController;
  
  AlbumDataCenter *_albumDataCenter;
  
  // Expose
  UINavigationItem *_headerNavItem;
  UINavigationBar *_headerNavBar;
  UINavigationController *_activeNavController;
  
  // Search
  PSTextField *_searchField;
  UIBarButtonItem *_filterButton;
  UIBarButtonItem *_cancelButton;
  UIBarButtonItem *_logoutButton;
  SearchTermController *_searchTermController;
  BOOL _searchActive;
}

@property (nonatomic, retain) UIWindow *window;
@property (readonly) Facebook *facebook;
@property (nonatomic, assign) PSTextField *searchField;

// Private
+ (void)setupDefaults;

- (void)back;

- (void)startSession;
- (void)startDownloadAlbums;
- (void)tryLogin;

- (void)getMe;
- (void)serializeMeWithResponse:(id)response;
- (void)getFriends;
- (void)serializeFriendsWithResponse:(id)response shouldDownload:(BOOL)shouldDownload;

- (void)updateLoginProgress:(NSNotification *)notification;
- (void)updateLoginProgressOnMainThread:(NSDictionary *)userInfo;

- (void)addNewUserAlbum;

// Facebook
- (void)requestPublishStream;

// Search
- (void)setupSearchField;
- (void)setupSearch;
- (void)filter;
- (void)cancelSearch;
- (void)searchWithText:(NSString *)searchText;

@end
