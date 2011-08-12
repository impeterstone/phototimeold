//
//  PhotoTimeAppDelegate.m
//  PhotoTime
//
//  Created by Peter Shih on 3/23/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import "PhotoTimeAppDelegate.h"
#import "Constants.h"
#import "FBConnect.h"
#import "SplashViewController.h"
#import "LoginViewController.h"
#import "LoginDataCenter.h"
#import "AlbumDataCenter.h"
#import "PSImageCache.h"
#import "PSProgressCenter.h"
#import "PSExposeController.h"

#import "AlbumViewController.h"

#import "SearchTermController.h"
#import "SearchTermDelegate.h"
#import "PSSearchCenter.h"
#import "UIImage+SML.h"
#import "UIBarButtonItem+SML.h"

@implementation PhotoTimeAppDelegate

@synthesize window = _window;
@synthesize facebook = _facebook;

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
  
  // Setup View Controllers
  // This should include customizeable spaces people have added
  AlbumViewController *me = [[[AlbumViewController alloc] init] autorelease];
  me.albumType = AlbumTypeMe;
  
  AlbumViewController *friends = [[[AlbumViewController alloc] init] autorelease];
  friends.albumType = AlbumTypeFriends;
  
  AlbumViewController *mobile = [[[AlbumViewController alloc] init] autorelease];
  mobile.albumType = AlbumTypeMobile;
  
  AlbumViewController *wall = [[[AlbumViewController alloc] init] autorelease];
  wall.albumType = AlbumTypeWall;
  
  AlbumViewController *profile = [[[AlbumViewController alloc] init] autorelease];
  profile.albumType = AlbumTypeProfile;
  
  AlbumViewController *favorites = [[[AlbumViewController alloc] init] autorelease];
  favorites.albumType = AlbumTypeFavorites;

  [[PSExposeController sharedController] setViewControllers:[NSMutableArray arrayWithObjects:me, friends, mobile, wall, profile, nil]];
  
  [self setupSearchField];
  
  // Window
  _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  [self.window addSubview:[[PSExposeController sharedController] view]];
  [self.window makeKeyAndVisible];
  
  // Config ExposeController after it's view has loaded
  [[[PSExposeController sharedController] navigationController] setDelegate:self];
  _filterButton = [[UIBarButtonItem navButtonWithImage:[UIImage imageNamed:@"icon_expose.png"] withTarget:self action:@selector(filter) buttonType:NavButtonTypeBlue] retain];
  //  _filterButton = [[self navButtonWithTitle:@"More" withTarget:self action:@selector(filter) buttonType:NavButtonTypeBlue] retain];
  _cancelButton = [[UIBarButtonItem navButtonWithTitle:@"Cancel" withTarget:self action:@selector(cancelSearch) buttonType:NavButtonTypeSilver] retain];
  [[[PSExposeController sharedController] navItem] setRightBarButtonItem:_filterButton];
  [[[PSExposeController sharedController] navItem] setTitleView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"phototime_logo.png"]] autorelease]];
  
  // Setup Search Controller
  [self setupSearch];
  
  // Login if necessary
  _loginViewController = [[LoginViewController alloc] init];
  _loginViewController.delegate = self;
  [self tryLogin];
  
  return YES;
}

- (void)setupSearchField {
  _searchField = [[PSTextField alloc] initWithFrame:CGRectMake(5, 6, 60, 30) withInset:CGSizeMake(30, 6)];
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
  [[[PSExposeController sharedController] navItem] setLeftBarButtonItem:[UIBarButtonItem navButtonWithTitle:@"Logout" withTarget:self action:@selector(logout) buttonType:NavButtonTypeNormal]];
  [_searchField removeFromSuperview];
}

- (void)exposeControllerWillCollapse:(PSExposeController *)exposeController {
  [[[PSExposeController sharedController] navItem] setLeftBarButtonItem:nil];
  [[[[PSExposeController sharedController] navigationController] navigationBar] addSubview:_searchField];
}

- (UIView *)backgroundViewForExposeController:(PSExposeController *)exposeController {
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_weave.png"]] autorelease];
  bg.frame = [[UIScreen mainScreen] bounds];
  return bg;
}

- (NSString *)exposeController:(PSExposeController *)exposeController labelTextForViewController:(UIViewController *)viewController {
  NSString *label = nil;
  if ([viewController isKindOfClass:[AlbumViewController class]]) {
    label = [(AlbumViewController *)viewController navTitleLabel].text;
  } else {
    label = @"Bacon!";
  }
  return label;
}

- (UIView *)exposeController:(PSExposeController *)exposeController overlayViewForViewController:(UIViewController *)viewController {
  AlbumType albumType = [(AlbumViewController *)viewController albumType];
  NSString *img = nil;
  switch (albumType) {
    case AlbumTypeMe:
      img = @"icon_me.png";
      break;
    case AlbumTypeFriends:
      img = @"icon_friends.png";
      break;
    case AlbumTypeMobile:
      img = @"icon_mobile.png";
      break;
    case AlbumTypeWall:
      img = @"icon_wall.png";
      break;
    case AlbumTypeProfile:
      img = @"icon_profile.png";
      break;
    default:
      img = @"icon_me.png";
      break;
  }
  UIImageView *overlayView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:img]] autorelease];
  overlayView.autoresizingMask = ~UIViewAutoresizingNone;
  overlayView.contentMode = UIViewContentModeScaleAspectFit;
  return overlayView;
}

- (BOOL)exposeController:(PSExposeController *)exposeController canDeleteViewController:(UIViewController *)viewController {
  return YES;
}

- (BOOL)canAddViewControllersForExposeController:(PSExposeController *)exposeController {
  return YES;
}

- (UIViewController *)newViewControllerForExposeController:(PSExposeController *)exposeController {
  AlbumViewController *avc = [[AlbumViewController alloc] init];
  return [avc autorelease];
}

#pragma mark - Login
- (void)tryLogin {
  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"]) {
    if (![[PSExposeController sharedController].navigationController.modalViewController isEqual:_loginViewController] && _loginViewController != nil) {
      [[PSExposeController sharedController].navigationController presentModalViewController:_loginViewController animated:NO];
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
  [self getFriends];
}

#pragma mark PSDataCenterDelegate
- (void)dataCenterDidFinish:(ASIHTTPRequest *)request withResponse:(id)response {  
  // Session/Register request finished
  if ([[PSExposeController sharedController].navigationController.modalViewController isEqual:_loginViewController]) {
    [[PSExposeController sharedController].navigationController dismissModalViewControllerAnimated:YES];
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:kReloadAlbumController object:nil];
}

- (void)dataCenterDidFail:(ASIHTTPRequest *)request withError:(NSError *)error {
}

- (void)filter {
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Expose"];
  //  FilterViewController *fvc = [[[FilterViewController alloc] init] autorelease];
  //  UINavigationController *fnc = [[[UINavigationController alloc] initWithRootViewController:fvc] autorelease];
  //  [self presentModalViewController:fnc animated:YES];
  
  [[PSExposeController sharedController] toggleExpose];
}

- (void)logout {
  UIAlertView *logoutAlert = [[UIAlertView alloc] initWithTitle:@"Logout?" message:LOGOUT_ALERT delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
  [logoutAlert show];
  [logoutAlert autorelease];
}

#pragma mark - AlertView
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex != alertView.cancelButtonIndex) {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"logoutRequested"];
    [[PSExposeController sharedController] toggleExpose];
  }
}

#pragma mark - Search
- (void)search {  
}

- (void)cancelSearch {
  [UIView animateWithDuration:0.4
                   animations:^{
                     _searchField.width = 60;
                   }
                   completion:^(BOOL finished) {
                   }];
  
  [[[PSExposeController sharedController] navItem] setRightBarButtonItem:_filterButton];
  [_searchField resignFirstResponder];
  _searchActive = NO;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
  if ([[navigationController viewControllers] count] > 1) {
    [_searchField removeFromSuperview];
  } else {
    [[[[PSExposeController sharedController] navigationController] navigationBar] addSubview:_searchField];
    _searchField.alpha = 0.0;
    [UIView animateWithDuration:0.4
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
    [[[[PSExposeController sharedController] navigationController] navigationBar] bringSubviewToFront:_searchField];
  }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  [[[PSExposeController sharedController] navItem] setRightBarButtonItem:_cancelButton];

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
  
  //  [UIView animateWithDuration:0.4
  //                   animations:^{
  //                     _searchTermController.view.alpha = 0.0;
  //                   }
  //                   completion:^(BOOL finished) {
  //                   }];
  
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
  _searchActive = YES;
  
  [_searchField resignFirstResponder];
  
  // Store search term
  [[PSSearchCenter defaultCenter] addTerm:searchText];
  
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
    [subpredicates addObject:[NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR fromName CONTAINS[cd] %@ OR location CONTAINS[cd] %@", searchValue, searchValue, searchValue]];
  }

  AlbumViewController *avc = [[AlbumViewController alloc] init];
  avc.albumType = AlbumTypeSearch;
  avc.searchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];
  [[PSExposeController sharedController] pushViewController:avc animated:YES];
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
}

- (void)dealloc {
  RELEASE_SAFELY(_searchTermController);
  RELEASE_SAFELY(_searchField);
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
