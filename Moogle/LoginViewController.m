//
//  LoginViewController.m
//  Moogle
//
//  Created by Peter Shih on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LoginViewController.h"
#import "LoginDataCenter.h"
#import "PSWelcomeView.h"

@implementation LoginViewController

@synthesize delegate = _delegate;
@synthesize loginButton = _loginButton;

- (id)init {
  self = [super init];
  if (self) {
    _facebook = APP_DELEGATE.facebook;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logout) name:kLogoutRequested object:nil];
  }
  return self;
}

- (void)loadView {
  [super loadView];
  
  self.view.backgroundColor = FB_BLUE_COLOR;
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Default.png"]];
  
  // Setup Welcome
  _welcomeView = [[[PSWelcomeView alloc] initWithFrame:CGRectMake(20, 20, 280, 384)] autorelease];
  UIImageView *one = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photos-large.png"]];
  one.frame = CGRectMake(0, 0, 280, 346);
  one.contentMode = UIViewContentModeCenter;
  UIImageView *two = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photos-large.png"]];
  two.frame = CGRectMake(0, 0, 280, 346);
  two.contentMode = UIViewContentModeCenter;
  UIImageView *three = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photos-large.png"]];
  three.frame = CGRectMake(0, 0, 280, 346);
  three.contentMode = UIViewContentModeCenter;
  NSArray *views = [NSArray arrayWithObjects:one, two, three, nil];
  [_welcomeView setViewArray:views];
  [self.view addSubview:_welcomeView];
  
  // Setup Login Buttons
  _loginButton = [[UIButton alloc] initWithFrame:CGRectZero];
  _loginButton.width = 280;
  _loginButton.height = 36;
  _loginButton.left = floor((self.view.width - _loginButton.width) / 2);
  _loginButton.top = self.view.height - _loginButton.height - 20.0;
  [_loginButton setBackgroundImage:[[UIImage imageNamed:@"facebook-connect.png"] stretchableImageWithLeftCapWidth:36 topCapHeight:0] forState:UIControlStateNormal];
  [_loginButton setContentEdgeInsets:UIEdgeInsetsMake(0, 36, 0, 0)];
  [_loginButton setTitle:@"Login with Facebook" forState:UIControlStateNormal];
  [_loginButton setTitle:@"Downloading Photo Albums" forState:UIControlStateDisabled];
  [_loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [_loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
  _loginButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16.0];
  _loginButton.titleLabel.shadowColor = [UIColor blackColor];
  _loginButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
  [_loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:_loginButton];
  
  // Loading Indicator
  _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  _loadingIndicator.hidesWhenStopped = YES;
  _loadingIndicator.center = self.view.center;
//  _loadingIndicator.top = _welcomeView.bottom;
  [self.view addSubview:_loadingIndicator];
  
}

#pragma mark -
#pragma mark Button Actions
- (void)login {
  [_loadingIndicator startAnimating];
  _loginButton.enabled = NO;
  _welcomeView.hidden = YES;
  [_facebook authorize:FB_PERMISSIONS delegate:self];
}

- (void)logout {
  [_facebook logout:self];
}

#pragma mark -
#pragma mark FBSessionDelegate
- (void)fbDidLogin {
  // Store Access Token
  // ignore the expiration since we request non-expiring offline access
  [[NSUserDefaults standardUserDefaults] setObject:_facebook.accessToken forKey:@"facebookAccessToken"];
  [[NSUserDefaults standardUserDefaults] setObject:_facebook.expirationDate forKey:@"facebookExpirationDate"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  if (self.delegate && [self.delegate respondsToSelector:@selector(userDidLogin:)]) {
    [self.delegate performSelector:@selector(userDidLogin:) withObject:nil];
  }
}

- (void)fbDidNotLogin:(BOOL)cancelled {
  [self logout];
  [_loadingIndicator stopAnimating];
  _loginButton.enabled = YES;
  _welcomeView.hidden = NO;
}

- (void)fbDidLogout {
  // Clear all user defaults
  [[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
  
  if (self.delegate && [self.delegate respondsToSelector:@selector(userDidLogout)]) {
    [self.delegate performSelector:@selector(userDidLogout)];
  }
  [_loadingIndicator stopAnimating];
  _loginButton.enabled = YES;
  _welcomeView.hidden = NO;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kLogoutRequested object:nil];
  RELEASE_SAFELY(_loginButton);
  RELEASE_SAFELY(_loadingIndicator);
  [super dealloc];
}

@end