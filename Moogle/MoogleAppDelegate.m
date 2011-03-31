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
#import "LICoreDataStack.h"
#import "LoginViewController.h"
#import "LauncherViewController.h"
#import "PodViewController.h"
#import "LoginDataCenter.h"

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
  _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.backgroundColor = FB_COLOR_DARK_GRAY_BLUE;
  
  // Login/Session/Register data center
  _loginDataCenter = [[LoginDataCenter alloc] init];
  _loginDataCenter.delegate = self;

  // Setup Facebook
  _facebook = [[Facebook alloc] initWithAppId:FB_APP_ID];
  
  _podViewController = [[PodViewController alloc] init];
  
  // NavigationController
  _navigationController = [[UINavigationController alloc] initWithRootViewController:_podViewController];
  
  // LoginVC
  _loginViewController = [[LoginViewController alloc] init];
  _loginViewController.delegate = self;
  
  [self.window addSubview:_navigationController.view];
  [self.window makeKeyAndVisible];
  
  // Login if necessary
  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"]) {
    [_navigationController presentModalViewController:_loginViewController animated:NO];
  } else {
    [self startSession];
  }
  
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  /*
   Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
   Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
   */
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  /*
   Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
   If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
   */
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  /*
   Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
   */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  /*
   Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
   */
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Saves changes in the application's managed object context before the application terminates.
  [self saveContext];
}

- (void)saveContext {
  NSError *error = nil;
  NSManagedObjectContext *managedObjectContext = [LICoreDataStack managedObjectContext];
  if (managedObjectContext != nil) {
    if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
      /*
       Replace this implementation with code to handle the error appropriately.
       
       abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
       */
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    } 
  }
}

#pragma mark -
#pragma mark LoginDelegate
- (void)moogleDidLogin {
  DLog(@"Moogle Logged In");
  
  // Change login screen to edu walkthru / loading
  
  [self startRegister];
}

#pragma mark Session
- (void)startSession {
  // This gets called on subsequent app launches
  [_loginDataCenter resetSessionKey];
  [_loginDataCenter startSession];
}

- (void)startRegister {
  // This gets called] if it is the first time logging in
  [_loginDataCenter resetSessionKey];
  [_loginDataCenter startRegister];
}

#pragma mark MoogleDataCenterDelegate
- (void)dataCenterDidFinish:(LINetworkOperation *)operation {
  // Determine if this is register or session
  NSString *requestUrlString = [[operation requestURL] absoluteString];
  if ([requestUrlString rangeOfString:@"register"].location != NSNotFound) {  
    // Moogle server will send user ID, name, and array of friend ids
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isLoggedIn"];
    [[NSUserDefaults standardUserDefaults] setObject:[_loginDataCenter.response valueForKey:@"facebook_id"] forKey:@"facebookId"];
    [[NSUserDefaults standardUserDefaults] setObject:[_loginDataCenter.response valueForKey:@"name"] forKey:@"facebookName"];
    [[NSUserDefaults standardUserDefaults] setObject:[_loginDataCenter.response valueForKey:@"friends"] forKey:@"friends"];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
  
  // Session/Register request finished
  if ([_navigationController.modalViewController isEqual:_loginViewController]) {
    [_navigationController dismissModalViewControllerAnimated:YES];
  }
}

- (void)dataCenterDidFail:(LINetworkOperation *)operation {
  // Session/Register request failed
  // Show login again
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
  RELEASE_SAFELY(_sessionKey);
  RELEASE_SAFELY(_loginDataCenter);
  RELEASE_SAFELY(_loginViewController);
  RELEASE_SAFELY(_launcherViewcontroller);
  RELEASE_SAFELY(_podViewController);
  RELEASE_SAFELY(_navigationController);
  RELEASE_SAFELY(_facebook);
  RELEASE_SAFELY(_window);
  [super dealloc];
}

@end
