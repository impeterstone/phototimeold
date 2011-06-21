//
//  PhotoFeedAppDelegate.m
//  PhotoFeed
//
//  Created by Peter Shih on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PhotoFeedAppDelegate.h"
#import "Constants.h"
#import "FBConnect.h"
#import "LoginViewController.h"
#import "LoginDataCenter.h"
#import "AlbumDataCenter.h"
#import "PSImageCache.h"

// Tabs
#import "AlbumViewController.h"
#import "SearchViewController.h"
#import "MoreViewController.h"

@implementation PhotoFeedAppDelegate

@synthesize window = _window;
@synthesize facebook = _facebook;
@synthesize sessionKey = _sessionKey;

+ (void)initialize {
  [self setupDefaults];
}

+ (void)setupDefaults {
  if ([self class] == [PhotoFeedAppDelegate class]) {
    NSString *initialDefaultsPath = [[NSBundle mainBundle] pathForResource:@"InitialDefaults" ofType:@"plist"];
    assert(initialDefaultsPath != nil);
    
    NSDictionary *initialDefaults = [NSDictionary dictionaryWithContentsOfFile:initialDefaultsPath];
    assert(initialDefaults != nil);
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:initialDefaults];
  }
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
  return [_facebook handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  
  [[AlbumDataCenter defaultCenter] setDelegate:self];
  
  NSLog(@"fonts: %@",[UIFont familyNames]);

  // We can configure if the imageCache should reside in cache or document directory here
//  [[PSImageCache sharedCache] setCacheDirectory:NSCachesDirectory];
//  [[PSImageCache sharedCache] setCacheDirectory:NSDocumentDirectory];
  
  _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"weave-bg.png"]];

  
  // Setup Facebook
  _facebook = [[Facebook alloc] initWithAppId:FB_APP_ID];
  
  // LoginVC
  _loginViewController = [[LoginViewController alloc] init];
  _loginViewController.delegate = self;
  
  // Tab Bar Controller
  _tabBarController = [[UITabBarController alloc] init];
  [self setupTabBar];
  
  [self.window addSubview:_tabBarController.view];
  [self.window makeKeyAndVisible];
  
  // Login if necessary
  [self tryLogin];
  
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  /*
   Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
   Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
   */
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  [[NSUserDefaults standardUserDefaults] synchronize];
//  [[PSImageCache sharedCache] flushImageCacheToDisk];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Login if necessary
  [self tryLogin];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  /*
   Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
   */
}

- (void)applicationWillTerminate:(UIApplication *)application {
  [[NSUserDefaults standardUserDefaults] synchronize];
//  [[PSImageCache sharedCache] flushImageCacheToDisk];
}

#pragma mark - Tab Bar
- (void)setupTabBar {
  // Setup Tabs
  AlbumViewController *me = [[[AlbumViewController alloc] init] autorelease];
  me.albumType = AlbumTypeMe;
  UINavigationController *meNav = [[[UINavigationController alloc] initWithRootViewController:me] autorelease];
  
  AlbumViewController *friends = [[[AlbumViewController alloc] init] autorelease];
  friends.albumType = AlbumTypeFriends;
  UINavigationController *friendsNav = [[[UINavigationController alloc] initWithRootViewController:friends] autorelease];
  
  AlbumViewController *favorites = [[[AlbumViewController alloc] init] autorelease];
  favorites.albumType = AlbumTypeFavorites;
  UINavigationController *favoritesNav = [[[UINavigationController alloc] initWithRootViewController:favorites] autorelease];
  
  //  SearchViewController *search = [[[SearchViewController alloc] init] autorelease];
  //  UINavigationController *searchNav = [[[UINavigationController alloc] initWithRootViewController:search] autorelease];
  
  AlbumViewController *history = [[[AlbumViewController alloc] init] autorelease];
  history.albumType = AlbumTypeHistory;
  UINavigationController *historyNav = [[[UINavigationController alloc] initWithRootViewController:history] autorelease];
  
  MoreViewController *more = [[[MoreViewController alloc] init] autorelease];
  UINavigationController *moreNav = [[[UINavigationController alloc] initWithRootViewController:more] autorelease];
  
  // Setup Tab Items
  me.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Me" image:[UIImage imageNamed:@"111-user.png"] tag:7001] autorelease];
  friends.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Friends" image:[UIImage imageNamed:@"112-group.png"] tag:7002] autorelease];
  favorites.tabBarItem = [[[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemFavorites tag:7003] autorelease];
  history.tabBarItem = [[[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemHistory tag:7004] autorelease];
  more.tabBarItem = [[[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemMore tag:7005] autorelease];
  
  // Set Tab Controllers
  _tabBarController.viewControllers = [NSArray arrayWithObjects:meNav, friendsNav, favoritesNav, historyNav, moreNav, nil];
  
  // Select previously chosen tab
  _tabBarController.selectedViewController = [_tabBarController.viewControllers objectAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"lastSelectedTab"]];
}

#pragma mark -
#pragma mark Login
- (void)tryLogin {
  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"]) {
    if (![_tabBarController.modalViewController isEqual:_loginViewController] && _loginViewController != nil) {
      [_tabBarController presentModalViewController:_loginViewController animated:NO];
    }
  } else {
    _facebook.accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"facebookAccessToken"];
    _facebook.expirationDate = [[NSUserDefaults standardUserDefaults] valueForKey:@"facebookExpirationDate"];
    [self startSession];
  }
}

#pragma mark -
#pragma mark LoginDelegate
- (void)userDidLogin:(NSDictionary *)userInfo {
  DLog(@"User Logged In");
  [self getMe];
}

- (void)userDidLogout {
  // Delete all existing data
  [self tryLogin];
  [PSCoreDataStack resetPersistentStoreCoordinator];
}

- (void)getMe {
  // This is called the first time logging in
  NSURL *meUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/me?fields=id,name,friends&access_token=%@", FB_GRAPH, [[NSUserDefaults standardUserDefaults] valueForKey:@"facebookAccessToken"]]];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:meUrl];
  request.requestMethod = @"GET";
  request.allowCompressedResponse = YES;
  
  // Request Completion Block
  [request setCompletionBlock:^{
    [self serializeMeWithResponse:[[request responseData] JSONValue]];
    [self startDownloadAlbums];
  }];
  [request setFailedBlock:^{
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutRequested object:nil];
  }];
  
  // Start the Request
  [request startAsynchronous];
}

- (void)serializeMeWithResponse:(id)response {
  NSString *facebookId = [response valueForKey:@"id"];
  NSString *facebookName = [response valueForKey:@"name"];
  NSArray *facebookFriends = [response valueForKey:@"friends"] ? [[response valueForKey:@"friends"] valueForKey:@"data"] : [NSArray array];
  
  NSMutableDictionary *friendsDict = [NSMutableDictionary dictionary];
  for (NSDictionary *friend in facebookFriends) {
    [friendsDict setValue:[friend valueForKey:@"name"] forKey:[friend valueForKey:@"id"]];
  }
  
  // Set UserDefaults
  [[NSUserDefaults standardUserDefaults] setObject:facebookId forKey:@"facebookId"];
  [[NSUserDefaults standardUserDefaults] setObject:facebookName forKey:@"facebookName"];
  [[NSUserDefaults standardUserDefaults] setObject:friendsDict forKey:@"facebookFriends"];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isLoggedIn"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)getFriends {
  // This is called subsequent app launches when already logged in
  NSURL *friendsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/me/friends?access_token=%@", FB_GRAPH, [[NSUserDefaults standardUserDefaults] valueForKey:@"facebookAccessToken"]]];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:friendsUrl];
  request.requestMethod = @"GET";
  request.allowCompressedResponse = YES;
  
  // Request Completion Block
  [request setCompletionBlock:^{
    [self serializeFriendsWithResponse:[[request responseData] JSONValue]];
    [self startDownloadAlbums];
  }];
  [request setFailedBlock:^{
    [self startDownloadAlbums];
  }];
  
  // Start the Request
  [request startAsynchronous];
}

- (void)serializeFriendsWithResponse:(id)response {
  NSArray *facebookFriends = [response valueForKey:@"data"] ? [response valueForKey:@"data"] : [NSArray array];
  
  NSDictionary *existingFriends = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"facebookFriends"];
  NSMutableDictionary *friendsDict = existingFriends ? [NSMutableDictionary dictionaryWithDictionary:existingFriends] : [NSMutableDictionary dictionary];
  
  NSMutableArray *newFriendIds = [NSMutableArray array];
  
  for (NSDictionary *friend in facebookFriends) {
    NSString *friendId = [friend valueForKey:@"id"];
    if (![friendsDict valueForKey:friendId]) {
      [newFriendIds addObject:friendId];
    }
    [friendsDict setValue:[friend valueForKey:@"name"] forKey:friendId];
  }
  
  [[NSUserDefaults standardUserDefaults] setObject:friendsDict forKey:@"facebookFriends"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  if ([newFriendIds count] > 0) {
    [[AlbumDataCenter defaultCenter] getAlbumsForFriendIds:newFriendIds];
  }
}

- (void)startDownloadAlbums {
  [[AlbumDataCenter defaultCenter] getAlbums];
}

#pragma mark Session
- (void)startSession {
  // This gets called on subsequent app launches
  [self resetSessionKey];
  [self getFriends];
}

- (void)resetSessionKey {
  // Set Session Key
  NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
  NSInteger currentTimestampInteger = floor(currentTimestamp);
  if (_sessionKey) {
    [_sessionKey release], _sessionKey = nil;
  }
  _sessionKey = [[NSString stringWithFormat:@"%d", currentTimestampInteger] retain];
  
  [[NSUserDefaults standardUserDefaults] setValue:_sessionKey forKey:@"sessionKey"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark PSDataCenterDelegate
- (void)dataCenterDidFinish:(ASIHTTPRequest *)request withResponse:(id)response {  
  // Session/Register request finished
  if ([_tabBarController.modalViewController isEqual:_loginViewController]) {
    [_tabBarController dismissModalViewControllerAnimated:YES];
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:kReloadAlbumController object:nil];
}

- (void)dataCenterDidFail:(ASIHTTPRequest *)request withError:(NSError *)error {
  // Show login again
//  [_loginViewController logout];
}

#pragma mark -
#pragma mark Animations
- (void)animateHideLogin {
  [UIView beginAnimations:@"HideLogin" context:nil];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(animateHideLoginFinished)];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationCurve:UIViewAnimationCurveLinear];
  [UIView setAnimationDuration:0.6]; // Fade out is configurable in seconds (FLOAT)
  [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:self.window cache:YES];
  [self.window exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
  [UIView commitAnimations];
}

- (void)animateHideLoginFinished {
  [_loginViewController.view removeFromSuperview];
}

- (void)dealloc {
  RELEASE_SAFELY(_tabBarController);
  RELEASE_SAFELY(_sessionKey);
  RELEASE_SAFELY(_loginViewController);
  RELEASE_SAFELY(_facebook);
  RELEASE_SAFELY(_window);
  [super dealloc];
}

@end
