//
//  PhotoTimeAppDelegate.m
//  PhotoTime
//
//  Created by Peter Shih on 3/23/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import "PhotoTimeAppDelegate.h"
#import "Constants.h"
#import "SplashViewController.h"
#import "LoginViewController.h"
#import "LoginDataCenter.h"
#import "AlbumDataCenter.h"
#import "PSImageCache.h"
#import "PSProgressCenter.h"
#import "PSExposeController.h"
#import "PSAlertCenter.h"

#import "PhotoViewController.h"
#import "AlbumViewController.h"
#import "FriendViewController.h"
#import "PurchaseViewController.h"

#import "SearchTermController.h"
#import "SearchTermDelegate.h"
#import "PSSearchCenter.h"
#import "UIImage+SML.h"
#import "UIBarButtonItem+SML.h"

#import "MKStoreManager.h"

@implementation PhotoTimeAppDelegate

@synthesize window = _window;
@synthesize facebook = _facebook;
@synthesize searchField = _searchField;
@synthesize headerNavItem = _headerNavItem;

+ (void)initialize {
  [self setupDefaults];
}

+ (void)setupDefaults {
  if ([self class] == [PhotoTimeAppDelegate class]) {
    NSString *initialDefaultsPath = [[NSBundle mainBundle] pathForResource:@"InitialDefaults" ofType:@"plist"];
    assert(initialDefaultsPath != nil);
    
    NSDictionary *initialDefaults = [NSDictionary dictionaryWithContentsOfFile:initialDefaultsPath];
    assert(initialDefaults != nil);
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:initialDefaults];
  }
}

#pragma mark - Lifecycle
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
  return [_facebook handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//  NSLog(@"fonts: %@",[UIFont familyNames]);
  
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isResume"];
  
  // MKStoreKit
  [MKStoreManager sharedManager];
  
  // Override StyleSheet
  [PSStyleSheet setStyleSheet:@"AppStyleSheet"];
  
  // Notifications
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLoginProgress:) name:kUpdateLoginProgress object:nil];
  
  // Localytics
  [[LocalyticsSession sharedLocalyticsSession] startSession:@"fa74713016dc9ada26defce-5a840dee-a0e8-11e0-013d-007f58cb3154"];

  // Config
  [[AlbumDataCenter defaultCenter] setDelegate:self];
  
  // We can configure if the imageCache should reside in cache or document directory here
//  [[PSImageCache sharedCache] setCacheDirectory:NSCachesDirectory];
//  [[PSImageCache sharedCache] setCacheDirectory:NSDocumentDirectory];
  

  // Setup Facebook
  _facebook = [[Facebook alloc] initWithAppId:FB_APP_ID];
  
  // Expose Controller
  [[PSExposeController sharedController] setDelegate:self];
  [[PSExposeController sharedController] setDataSource:self];
  
  [self setupAlbums];
  
  // Global Nav Buttons
  _filterButton = [[UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"icon_expose.png"] withTarget:self action:@selector(filter) width:60 height:30 buttonType:BarButtonTypeBlue] retain];
  _cancelButton = [[UIBarButtonItem barButtonWithTitle:@"Cancel" withTarget:self action:@selector(cancelSearch) width:60 height:30 buttonType:BarButtonTypeSilver] retain];
  _logoutButton = [[UIBarButtonItem barButtonWithTitle:@"Logout" withTarget:self action:@selector(logout) width:60 height:30 buttonType:BarButtonTypeNormal] retain];
  _editButton = [[UIBarButtonItem barButtonWithTitle:@"Edit" withTarget:self action:@selector(edit) width:60 height:30 buttonType:BarButtonTypeNormal] retain];
  _doneButton = [[UIBarButtonItem barButtonWithTitle:@"Done" withTarget:self action:@selector(edit) width:60 height:30 buttonType:BarButtonTypeBlue] retain];
  
  // Window
  _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  [self.window addSubview:[[PSExposeController sharedController] view]];
  [self.window makeKeyAndVisible];
  
  // Setup Search Controller
  [_headerNavItem setRightBarButtonItem:_filterButton];
  [self setupSearchField];
  [self setupSearch];
  
  // Login if necessary
  _loginViewController = [[LoginViewController alloc] init];
  _loginViewController.delegate = self;
  [self tryLogin];
  
  return YES;
}

- (void)setupAlbums {
  // Setup the 4 standard streams
  NSMutableArray *albums = [NSMutableArray array];
  
  AlbumViewController *me = [[[AlbumViewController alloc] init] autorelease];
  me.albumType = AlbumTypeMe;
  me.albumTitle = @"My Albums";
  [albums addObject:me];
  
  AlbumViewController *friends = [[[AlbumViewController alloc] init] autorelease];
  friends.albumType = AlbumTypeFriends;
  friends.albumTitle = @"My Friends";
  [albums addObject:friends];
  
  AlbumViewController *mobile = [[[AlbumViewController alloc] init] autorelease];
  mobile.albumType = AlbumTypeMobile;
  mobile.albumTitle = @"Mobile Uploads";
  [albums addObject:mobile];
  
  AlbumViewController *wall = [[[AlbumViewController alloc] init] autorelease];
  wall.albumType = AlbumTypeWall;
  wall.albumTitle = @"Wall Photos";
  [albums addObject:wall];
  
  // Now check to see if the user has any custom streams
  NSArray *userAlbums = [[NSUserDefaults standardUserDefaults] arrayForKey:@"userAlbums"];
  for (NSDictionary *userAlbum in userAlbums) {
    AlbumViewController *avc = [[AlbumViewController alloc] init];
    avc.albumType = AlbumTypeCustom;
    avc.albumConfig = userAlbum;
    avc.albumTitle = [userAlbum objectForKey:@"title"];
    [albums addObject:avc];
    [avc release];
  }
  
  NSMutableArray *navControllers = [NSMutableArray array];
  for (AlbumViewController *avc in albums) {
    UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:avc] autorelease];
    nc.delegate = self;
    nc.navigationBarHidden = YES;
    [navControllers addObject:nc];
  }
  [[PSExposeController sharedController] setViewControllers:navControllers];
}

- (void)resetAlbums {
  NSInteger count = [[[PSExposeController sharedController] viewControllers] count];
  if (count > 4) {
    for (int i = 4; i < count; i++) {
      [[PSExposeController sharedController] deleteViewControllerAtIndex:i animated:NO];
    }
  }
}

- (void)setupSearchField {
  _searchField = [[PSTextField alloc] initWithFrame:CGRectMake(5, 6, 60, 30) withInset:CGSizeMake(30, 0)];
  _searchField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
  _searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
  _searchField.font = NORMAL_FONT;
  _searchField.delegate = self;
  _searchField.returnKeyType = UIReturnKeySearch;
  _searchField.background = [UIImage stretchableImageNamed:@"bg_searchbar_textfield.png" withLeftCapWidth:30 topCapWidth:0];
  _searchField.placeholder = @"Search for photos...";
  [_searchField addTarget:self action:@selector(searchTermChanged:) forControlEvents:UIControlEventEditingChanged];
}

- (void)setupSearch {
  _searchActive = NO;
  
  _searchTermController = [[SearchTermController alloc] init];
  _searchTermController.delegate = self;
  _searchTermController.view.frame = self.window.bounds;
  _searchTermController.view.top = 64;
  _searchTermController.view.height -= 64;
  _searchTermController.view.alpha = 0.0;
  [self.window addSubview:_searchTermController.view];
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  // Localytics
  [[LocalyticsSession sharedLocalyticsSession] close];
	[[LocalyticsSession sharedLocalyticsSession] upload];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isResume"];
  
  // Login if necessary
  [self tryLogin];
  
  // Localytics
  [[LocalyticsSession sharedLocalyticsSession] resume];
	[[LocalyticsSession sharedLocalyticsSession] upload];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  // Localytics
  [[LocalyticsSession sharedLocalyticsSession] close];
  [[LocalyticsSession sharedLocalyticsSession] upload];
}

#pragma mark - PSExposeControllerDelegate
- (void)exposeControllerWillExpand:(PSExposeController *)exposeController {
  [_searchField removeFromSuperview];  
  [_headerNavItem setLeftBarButtonItem:_logoutButton];
  [_headerNavItem setRightBarButtonItem:_editButton];
}

- (void)exposeControllerWillCollapse:(PSExposeController *)exposeController {
  [_headerNavBar addSubview:_searchField];
  [_headerNavItem setLeftBarButtonItem:nil];
  [_headerNavItem setRightBarButtonItem:_filterButton];
}

- (BOOL)exposeController:(PSExposeController *)exposeController shouldHideNavigationBarOnAppearForViewController:(UIViewController *)viewController {
  return YES;
}

- (UIView *)headerViewForExposeController:(PSExposeController *)exposeController {
  _headerNavBar = [[[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.window.width, 44)] autorelease];
  _headerNavBar.tintColor = RGBACOLOR(80, 80, 80, 1.0);
  _headerNavBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  _headerNavItem = [[[UINavigationItem alloc] init] autorelease];
  [_headerNavBar setItems:[NSArray arrayWithObject:_headerNavItem]];
  _headerNavItem.titleView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"phototime_logo.png"]] autorelease];
  return _headerNavBar;
}

- (UIView *)backgroundViewForExposeController:(PSExposeController *)exposeController {
  NSString *bgName = nil;
  if (isDeviceIPad()) {
    bgName = @"bg_darkwood_pad.jpg";
  } else {
    bgName = @"bg_darkwood.jpg";
  }
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:bgName]] autorelease];
  bg.frame = [[UIScreen mainScreen] bounds];
  return bg;
}

- (UILabel *)exposeController:(PSExposeController *)exposeController labelForViewController:(UIViewController *)viewController {
  AlbumViewController *avc = (AlbumViewController *)[(UINavigationController *)viewController topViewController];
  UILabel *l = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  l.autoresizingMask = ~UIViewAutoresizingNone;
  l.backgroundColor = [UIColor clearColor];
  l.font = BELLO_FONT;
  l.textColor = BELLO_COLOR;
  l.textAlignment = UITextAlignmentCenter;
  l.text = avc.albumTitle;
  
  return l;
}

- (UIView *)addViewForExposeController:(PSExposeController *)exposeController {
  UIView *addView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  addView.autoresizingMask = ~UIViewAutoresizingNone;
  NSString *bgName = nil;
  if (isDeviceIPad()) {
    bgName = @"bg_add_stream_pad.png";
  } else {
    bgName = @"bg_add_stream.png";
  }
  UIImageView *addBackgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:bgName]] autorelease];
  addBackgroundView.frame = addView.bounds;
  addBackgroundView.autoresizingMask = addView.autoresizingMask;
  [addView addSubview:addBackgroundView];
  return addView;
}

- (void)exposeController:(PSExposeController *)exposeController didDeleteViewController:(UIViewController *)viewController atIndex:(NSUInteger)index {
  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"]) return;
  
  NSUInteger offsetIndex = index - 4; // 4 non-deleteable spaces
  
  NSMutableArray *newUserAlbums = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"userAlbums"]];
  
  [newUserAlbums removeObjectAtIndex:offsetIndex];
  
  [[NSUserDefaults standardUserDefaults] setObject:newUserAlbums forKey:@"userAlbums"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)exposeController:(PSExposeController *)exposeController canDeleteViewController:(UIViewController *)viewController {
  NSUInteger index = [exposeController.viewControllers indexOfObject:viewController];
  if (index > 3) {
    return YES;
  } else {
    return NO;
  }
}

- (BOOL)canAddViewControllersForExposeController:(PSExposeController *)exposeController {
  return YES;
}

- (void)shouldAddViewControllerForExposeController:(PSExposeController *)exposeController {
  // Check to see if this feature is purchased first or if the user hasn't used their freebie
  if ([[[PSExposeController sharedController] viewControllers] count] < [[NSUserDefaults standardUserDefaults] integerForKey:@"availableStreams"]) {
    // Prompt user to configure new stream
    [self addNewStream];
  } else {
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"app.purchase"];
    // Prompt user to buy
    PurchaseViewController *pvc = [[[PurchaseViewController alloc] init] autorelease];
    [[PSExposeController sharedController] presentModalViewController:pvc animated:YES];
  }
}

- (void)addNewStream {
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"app.addStream"];
  FriendViewController *fvc = [[[FriendViewController alloc] init] autorelease];
  fvc.delegate = self;
  [[PSExposeController sharedController] presentModalViewController:fvc animated:YES];
}

#pragma mark - FriendSelectDelegate
- (void)didSelectFriends:(NSArray *)friends withTitle:(NSString *)title {
  NSMutableArray *newUserAlbums = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"userAlbums"]];
  
  NSDictionary *newAlbum = [NSDictionary dictionaryWithObjectsAndKeys:[friends valueForKey:@"id"], @"ids", title, @"title", nil];
  [newUserAlbums addObject:newAlbum];
  
  [[NSUserDefaults standardUserDefaults] setObject:newUserAlbums forKey:@"userAlbums"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  AlbumViewController *avc = [[AlbumViewController alloc] init];
  avc.albumType = AlbumTypeCustom;
  avc.albumTitle = title;
  avc.albumConfig = newAlbum;
  UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:avc] autorelease];
  nc.delegate = self;
  nc.navigationBarHidden = YES;
  
  [[PSExposeController sharedController] addNewViewController:nc];
  [avc release];
}

#pragma mark - Login
- (void)tryLogin {
  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"]) {
    // Not Logged In
    if (![self.window.subviews containsObject:_loginViewController.view]) {
      [self.window addSubview:_loginViewController.view];
    }
  } else {
    _facebook.accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"facebookAccessToken"];
    _facebook.expirationDate = [[NSUserDefaults standardUserDefaults] valueForKey:@"facebookExpirationDate"];
    [self startSession];
  }
}

#pragma mark - LoginDelegate
- (void)userDidLogin:(NSDictionary *)userInfo {
  // User managed to actually login, let's show a splash screen while 
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"app.didLogin"];
  
  if (!_splashViewController) {
    _splashViewController = [[SplashViewController alloc] init];
    _splashViewController.view.frame = self.window.bounds;
  }
  
  [self.window addSubview:_splashViewController.view];
  
  [self getMe];
}

- (void)userDidLogout {
  // Clear all user defaults
  [[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
  
  // Reset SearchCenter
  [[PSSearchCenter defaultCenter] resetTerms];
  
  // Reset persistent store
  [PSCoreDataStack resetPersistentStoreCoordinator];
  
  // Reset view controllers
  [_splashViewController.view removeFromSuperview];
  [_loginViewController.view removeFromSuperview];
  
  // Reset Expose Spaces
  [self resetAlbums];
  
  [self tryLogin];
}

#pragma mark - Facebook Permissions
- (void)requestPublishStream {
  UIAlertView *permissionsAlert = [[[UIAlertView alloc] initWithTitle:@"Permission Needed" message:@"We need your permission to upload, comment or like photos." delegate:self cancelButtonTitle:@"Nevermind" otherButtonTitles:@"Okay", nil] autorelease];
  permissionsAlert.tag = PERMISSIONS_ALERT_TAG;
  [permissionsAlert show];
}

- (void)fbDidLogin {
  // Store New Access Token
  // ignore the expiration since we request non-expiring offline access
  [[NSUserDefaults standardUserDefaults] setObject:[_facebook.accessToken stringWithPercentEscape] forKey:@"facebookAccessToken"];
  [[NSUserDefaults standardUserDefaults] setObject:_facebook.expirationDate forKey:@"facebookExpirationDate"];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"facebookCanPublish"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  [self callHome];
}

- (void)fbDidNotLogin:(BOOL)cancelled {
  
}

- (void)callHome {
  // This is called the first time logging in
  NSURL *callHomeUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users", API_BASE_URL]];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:callHomeUrl];
  request.userInfo = [NSDictionary dictionaryWithObject:@"callHome" forKey:@"requestType"];
  request.requestMethod = @"POST";
  request.allowCompressedResponse = YES;
  
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  [params setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"facebookAccessToken"] forKey:@"facebook_access_token"];
  [params setObject:[[UIDevice currentDevice] uniqueIdentifier] forKey:@"udid"];
  [params setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"facebookId"] forKey:@"facebook_id"];
  [params setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"facebookName"] forKey:@"facebook_name"];
  [params setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"facebookCanPublish"] forKey:@"facebook_can_publish"];
  request.postBody = [[PSDataCenter defaultCenter] buildRequestParamsData:params];
  
  [request addRequestHeader:@"X-UDID" value:[[UIDevice currentDevice] uniqueIdentifier]];
  [request addRequestHeader:@"X-Device-Model" value:[[UIDevice currentDevice] model]];
  [request addRequestHeader:@"X-App-Version" value:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
  [request addRequestHeader:@"X-System-Name" value:[[UIDevice currentDevice] systemName]];
  [request addRequestHeader:@"X-System-Version" value:[[UIDevice currentDevice] systemVersion]];
  [request addRequestHeader:@"X-User-Language" value:USER_LANGUAGE];
  [request addRequestHeader:@"X-User-Locale" value:USER_LOCALE];
  
  // Request Completion Block
  [request setCompletionBlock:^{
  }];
  [request setFailedBlock:^{
  }];
  
  // Start the Request
  [request startAsynchronous];
}

- (void)getMe {
  // This is called the first time logging in
  NSURL *meUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/me?fields=id,name,friends&access_token=%@", FB_GRAPH, [[NSUserDefaults standardUserDefaults] valueForKey:@"facebookAccessToken"]]];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:meUrl];
  request.userInfo = [NSDictionary dictionaryWithObject:@"me" forKey:@"requestType"];
  request.requestMethod = @"GET";
  request.allowCompressedResponse = YES;
  
  // Request Completion Block
  [request setCompletionBlock:^{
    [self serializeMeWithResponse:[[request responseData] objectFromJSONData]];
    [self startDownloadAlbums];
    [self callHome];
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
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:friendsUrl];
  request.userInfo = [NSDictionary dictionaryWithObject:@"friends" forKey:@"requestType"];
  request.requestMethod = @"GET";
  request.allowCompressedResponse = YES;
  
  // Request Completion Block
  [request setCompletionBlock:^{
    [self serializeFriendsWithResponse:[[request responseData] objectFromJSONData] shouldDownload:YES];
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
      [friendDict setObject:[friend objectForKey:@"id"] forKey:@"id"];
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
  [self getFriends];
  
}

#pragma mark PSDataCenterDelegate
- (void)dataCenterDidFinish:(ASIHTTPRequest *)request withResponse:(id)response {  
  // Session/Register request finished
  [_splashViewController.view removeFromSuperview];
  [_loginViewController.view removeFromSuperview];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:kReloadAlbumController object:nil];
  
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"isFirstLogin"]) {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isFirstLogin"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [[[[UIAlertView alloc] initWithTitle:@"Welcome!" message:@"We are still downloading albums from your friends. You can browse your own photos in the meantime." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] autorelease] show];
    }];
  }
}

- (void)dataCenterDidFail:(ASIHTTPRequest *)request withError:(NSError *)error {
}

- (void)filter {
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"app.expose"];
  //  FilterViewController *fvc = [[[FilterViewController alloc] init] autorelease];
  //  UINavigationController *fnc = [[[UINavigationController alloc] initWithRootViewController:fvc] autorelease];
  //  [self presentModalViewController:fnc animated:YES];
  
  [[PSExposeController sharedController] toggleExpose];
}

- (void)logout {
  UIAlertView *logoutAlert = [[UIAlertView alloc] initWithTitle:@"Logout?" message:LOGOUT_ALERT delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
  logoutAlert.tag = LOGOUT_ALERT_TAG;
  [logoutAlert show];
  [logoutAlert autorelease];
}

- (void)edit {
  BOOL isEditing = [[PSExposeController sharedController] isEditing];
  if (isEditing) {
    [_headerNavItem setRightBarButtonItem:_editButton];
  } else {
    [_headerNavItem setRightBarButtonItem:_doneButton];
  }
  
  [[PSExposeController sharedController] toggleEditing:!isEditing];
}

#pragma mark - AlertView
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex != alertView.cancelButtonIndex) {
    if (alertView.tag == LOGOUT_ALERT_TAG) {
      [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"app.logout"];
      [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutRequested object:nil];
      [[PSExposeController sharedController] toggleExpose];
    } else if (alertView.tag == PERMISSIONS_ALERT_TAG) {
      [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"app.requestMorePermissions"];
      [_facebook authorize:FB_PERMISSIONS_EXTENDED delegate:self];
    } else if (alertView.tag == FB_ERROR_ALERT_TAG) {
      [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutRequested object:nil];
    }
  }
}

#pragma mark - Search
- (void)cancelSearch {
  [UIView animateWithDuration:0.4
                   animations:^{
                     _searchField.width = 60;
                   }
                   completion:^(BOOL finished) {
                   }];
  
  [_headerNavItem setRightBarButtonItem:_filterButton];
  [_searchField resignFirstResponder];
  _searchActive = NO;
}

#pragma mark - Navigation Delegate
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
  if ([[PSExposeController sharedController] isShowing]) return;
  
  if ([[navigationController viewControllers] count] > 1) {
    _activeNavController = navigationController;
    [_searchField removeFromSuperview];
    [_headerNavItem setLeftBarButtonItem:[UIBarButtonItem navBackButtonWithTarget:self action:@selector(back)]];
    if ([viewController isKindOfClass:[PhotoViewController class]]) {
      [_headerNavItem setRightBarButtonItem:[(PhotoViewController *)viewController rightBarButton]];
    } else {
      [_headerNavItem setRightBarButtonItem:nil];
    }
  } else {
    [_headerNavItem setLeftBarButtonItem:nil];
    [_headerNavItem setRightBarButtonItem:_filterButton];
    _searchField.alpha = 0.0;
    [_headerNavBar addSubview:_searchField];
    [UIView animateWithDuration:0.4
                          delay:0.0
                      
                        options:UIViewAnimationCurveEaseOut
                     animations:^{
                       _searchField.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                     }];
    
    if (_searchActive) {
      [_searchField becomeFirstResponder];
    }
  }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
  if ([[navigationController viewControllers] count] == 1) {
    [_headerNavBar bringSubviewToFront:_searchField];
  }
}

- (void)back {
  if (_activeNavController) {
    [_activeNavController popViewControllerAnimated:YES];
  }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  [_headerNavItem setRightBarButtonItem:_cancelButton];

  [UIView animateWithDuration:0.4
                   animations:^{
                     _searchField.width = self.window.width - 80;
                     _searchTermController.view.alpha = 1.0;
                   }
                   completion:^(BOOL finished) {
                   }];
  
  return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {  
  _searchTermController.view.alpha = 0.0;  
  return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  if (![textField isEditing]) {
    [textField becomeFirstResponder];
  }
  if ([textField.text length] == 0) {
    // Empty search
    [self cancelSearch];
  } else {
    [self searchWithText:textField.text];
  }
  
  return YES;
}

- (void)searchTermChanged:(UITextField *)textField {
  [_searchTermController searchWithTerm:textField.text];
}

//- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
//  return YES;
//}

- (void)searchWithText:(NSString *)searchText {
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"app.searchWithText"];
  _searchActive = YES;
  
  [_searchField resignFirstResponder];
  
  // Store search term
  [[PSSearchCenter defaultCenter] addTerm:searchText inContainer:@"albums"];
  
  static NSCharacterSet *separatorCharacterSet = nil;
  if (!separatorCharacterSet) {
    separatorCharacterSet = [[[NSCharacterSet alphanumericCharacterSet] invertedSet] retain];
  }
  
  NSMutableArray *subpredicates = [NSMutableArray arrayWithCapacity:1];
  //  predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", searchText];
  
  NSString *tmp = [[searchText componentsSeparatedByCharactersInSet:separatorCharacterSet] componentsJoinedByString:@" "];
  NSArray *searchTerms = [tmp componentsSeparatedByString:@" "];
  
  for (NSString *searchTerm in searchTerms) {
    if ([searchTerm length] == 0) continue;
    NSString *searchValue = searchTerm;
    // search any
    [subpredicates addObject:[NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR fromName CONTAINS[cd] %@ OR caption CONTAINS[cd] %@ OR location CONTAINS[cd] %@", searchValue, searchValue, searchValue, searchValue]];
  }

  AlbumViewController *avc = [[AlbumViewController alloc] init];
  avc.albumType = AlbumTypeSearch;
  avc.searchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];
  [[[PSExposeController sharedController] selectedNavigationController] pushViewController:avc animated:YES];
  [avc release];
}

#pragma mark - SearchTermDelegate
- (void)searchTermSelected:(NSString *)searchTerm {
  _searchField.text = searchTerm;
  [self searchWithText:_searchField.text];
}

- (void)searchCancelled {
  [self cancelSearch];
}

#pragma mark - Notifications
- (void)updateLoginProgress:(NSNotification *)notification {
  [self performSelectorOnMainThread:@selector(updateLoginProgressOnMainThread:) withObject:[notification userInfo] waitUntilDone:NO];
}

- (void)updateLoginProgressOnMainThread:(NSDictionary *)userInfo {
  [[PSProgressCenter defaultCenter] setProgress:[[userInfo objectForKey:@"progress"] floatValue]];
  [[PSProgressCenter defaultCenter] setMessage:[NSString stringWithFormat:@"Saving Albums: %@ of %@", [userInfo objectForKey:@"index"], [userInfo objectForKey:@"total"]]];
  
  // We finished
  if ([[userInfo objectForKey:@"index"] integerValue] == [[userInfo objectForKey:@"total"] integerValue]) {
    [[PSProgressCenter defaultCenter] hideProgress];
  }
}

- (void)dealloc {
  RELEASE_SAFELY(_searchTermController);
  RELEASE_SAFELY(_searchField);
  RELEASE_SAFELY(_logoutButton);
  RELEASE_SAFELY(_editButton);
  RELEASE_SAFELY(_doneButton);
  RELEASE_SAFELY(_filterButton);
  RELEASE_SAFELY(_cancelButton);
  RELEASE_SAFELY(_navController);
  RELEASE_SAFELY(_splashViewController);
  RELEASE_SAFELY(_loginViewController);
  RELEASE_SAFELY(_facebook);
  RELEASE_SAFELY(_window);
  [super dealloc];
}

@end
