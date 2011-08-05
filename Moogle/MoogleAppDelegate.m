//
//  MoogleAppDelegate.m
//  Moogle
//
//  Created by Peter Shih on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MoogleAppDelegate.h"
#import "Constants.h"
#import "FBConnect.h"
#import "SplashViewController.h"
#import "LoginViewController.h"
#import "LoginDataCenter.h"
#import "AlbumDataCenter.h"
#import "PSImageCache.h"
#import "PSProgressCenter.h"

#import "AlbumViewController.h"

@implementation MoogleAppDelegate

@synthesize window = _window;
@synthesize facebook = _facebook;
@synthesize sessionKey = _sessionKey;

+ (void)initialize {
  [self setupDefaults];
}

+ (void)setupDefaults {
  if ([self class] == [MoogleAppDelegate class]) {
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
  
  // Localytics
  [[LocalyticsSession sharedLocalyticsSession] startSession:@"fa74713016dc9ada26defce-5a840dee-a0e8-11e0-013d-007f58cb3154"];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLoginProgress:) name:kUpdateLoginProgress object:nil];
  
  [[AlbumDataCenter defaultCenter] setDelegate:self];
  
  NSLog(@"fonts: %@",[UIFont familyNames]);

  // We can configure if the imageCache should reside in cache or document directory here
//  [[PSImageCache sharedCache] setCacheDirectory:NSCachesDirectory];
//  [[PSImageCache sharedCache] setCacheDirectory:NSDocumentDirectory];
  
  _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

  // Setup Facebook
  _facebook = [[Facebook alloc] initWithAppId:FB_APP_ID];
  
  // LoginVC
  _loginViewController = [[LoginViewController alloc] init];
  _loginViewController.delegate = self;
  
  // Album VC
  AlbumViewController *avc = [[[AlbumViewController alloc] init] autorelease];
  
  // Nav Controller
  _navController = [[UINavigationController alloc] initWithRootViewController:avc];
  
  [self.window addSubview:_navController.view];
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
  
  // Localytics
  [[LocalyticsSession sharedLocalyticsSession] close];
	[[LocalyticsSession sharedLocalyticsSession] upload];
  
//  [[PSImageCache sharedCache] flushImageCacheToDisk];
//  [[NSNotificationCenter defaultCenter] removeObserver:self name:kUpdateLoginProgress object:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Login if necessary
  [self tryLogin];
  
  // Localytics
  [[LocalyticsSession sharedLocalyticsSession] resume];
	[[LocalyticsSession sharedLocalyticsSession] upload];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  /*
   Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
   */
}

- (void)applicationWillTerminate:(UIApplication *)application {
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  // Localytics
  [[LocalyticsSession sharedLocalyticsSession] close];
  [[LocalyticsSession sharedLocalyticsSession] upload];
  
//  [[PSImageCache sharedCache] flushImageCacheToDisk];
}

#pragma mark - Notifications
- (void)updateLoginProgress:(NSNotification *)notification {
  [self performSelectorOnMainThread:@selector(updateLoginProgressOnMainThread:) withObject:[notification userInfo] waitUntilDone:NO];
}

- (void)updateLoginProgressOnMainThread:(NSDictionary *)userInfo {
  [[PSProgressCenter defaultCenter] setProgress:[[userInfo objectForKey:@"progress"] floatValue]];
  [[PSProgressCenter defaultCenter] setMessage:[NSString stringWithFormat:@"Saving Albums: %@ of %@", [userInfo objectForKey:@"index"], [userInfo objectForKey:@"total"]]];
}

#pragma mark - Login
- (void)tryLogin {
  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"]) {
    if (![_navController.modalViewController isEqual:_loginViewController] && _loginViewController != nil) {
      [_navController presentModalViewController:_loginViewController animated:NO];
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
  // User managed to actually login, let's show a splash screen while 
  
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"User Logged In"];
  
  if (!_splashViewController) {
    _splashViewController = [[SplashViewController alloc] init];
  }
  
  [_loginViewController presentModalViewController:_splashViewController animated:NO];
  
  [self getMe];
}

- (void)userDidLogout {
  // Clear all user defaults
  [[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
  
  // Reset persistent store
  [PSCoreDataStack resetPersistentStoreCoordinator];
  
  // Reset view controllers
  
  [self tryLogin];
}

- (void)getMe {
  // This is called the first time logging in
  NSURL *meUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/me?fields=id,name,friends&access_token=%@", FB_GRAPH, [[NSUserDefaults standardUserDefaults] valueForKey:@"facebookAccessToken"]]];
  
#warning don't use blocks
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:meUrl];
  request.userInfo = [NSDictionary dictionaryWithObject:@"me" forKey:@"requestType"];
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
  
  [self serializeFriendsWithResponse:[response valueForKey:@"friends"] shouldDownload:NO];
  
  // Set UserDefaults
  [[NSUserDefaults standardUserDefaults] setObject:facebookId forKey:@"facebookId"];
  [[NSUserDefaults standardUserDefaults] setObject:facebookName forKey:@"facebookName"];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isLoggedIn"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)getFriends {
  // This is called subsequent app launches when already logged in
  NSURL *friendsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/me/friends?fields=name,gender&access_token=%@", FB_GRAPH, [[NSUserDefaults standardUserDefaults] valueForKey:@"facebookAccessToken"]]];
  
#warning don't use blocks
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:friendsUrl];
  request.userInfo = [NSDictionary dictionaryWithObject:@"friends" forKey:@"requestType"];
  request.requestMethod = @"GET";
  request.allowCompressedResponse = YES;
  
  // Request Completion Block
  [request setCompletionBlock:^{
    [self serializeFriendsWithResponse:[[request responseData] JSONValue] shouldDownload:YES];
    [self startDownloadAlbums];
  }];
  [request setFailedBlock:^{
    [self startDownloadAlbums];
  }];
  
  // Start the Request
  [request startAsynchronous];
}

- (void)serializeFriendsWithResponse:(id)response shouldDownload:(BOOL)shouldDownload {
  NSArray *facebookFriends = [response valueForKey:@"data"] ? [response valueForKey:@"data"] : [NSArray array];
  
  NSDictionary *existingFriends = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"facebookFriends"];
  NSMutableDictionary *friendsDict = existingFriends ? [NSMutableDictionary dictionaryWithDictionary:existingFriends] : [NSMutableDictionary dictionary];
  
  NSMutableArray *newFriendIds = [NSMutableArray array];
  
  for (NSDictionary *friend in facebookFriends) {
    NSString *friendId = [friend objectForKey:@"id"];
    if (![friendsDict objectForKey:friendId]) {
      [newFriendIds addObject:friendId];
      
      NSMutableDictionary *friendDict = [NSMutableDictionary dictionaryWithCapacity:2];
      if ([friend objectForKey:@"gender"]) {
        [friendDict setObject:[friend objectForKey:@"gender"] forKey:@"gender"];
      }
      [friendDict setObject:[friend objectForKey:@"name"] forKey:@"name"];
      [friendsDict setObject:friendDict forKey:friendId];
    }
  }
  
  [[NSUserDefaults standardUserDefaults] setObject:friendsDict forKey:@"facebookFriends"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  if (shouldDownload) {
    if ([newFriendIds count] > 0) {
      [[AlbumDataCenter defaultCenter] getAlbumsForFriendIds:newFriendIds];
    }
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
  if ([_navController.modalViewController isEqual:_loginViewController]) {
    [_navController dismissModalViewControllerAnimated:YES];
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:kReloadAlbumController object:nil];
}

- (void)dataCenterDidFail:(ASIHTTPRequest *)request withError:(NSError *)error {
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
  RELEASE_SAFELY(_navController);
  RELEASE_SAFELY(_sessionKey);
  RELEASE_SAFELY(_splashViewController);
  RELEASE_SAFELY(_loginViewController);
  RELEASE_SAFELY(_facebook);
  RELEASE_SAFELY(_window);
  [super dealloc];
}

@end
