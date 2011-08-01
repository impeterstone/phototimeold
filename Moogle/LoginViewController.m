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
  
//  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"weave-bg.png"]];
  self.view.backgroundColor = [UIColor whiteColor];
  
  // Setup Welcome
  _welcomeView = [[[PSWelcomeView alloc] initWithFrame:CGRectMake(0, 26, 320, 320)] autorelease];
  UIImageView *one = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nux_comic_1.png"]] autorelease];
  UIImageView *two = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nux_comic_2.png"]] autorelease];
  UIImageView *three = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nux_comic_3.png"]] autorelease];
  UIImageView *four = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nux_comic_4.png"]] autorelease];
  NSArray *views = [NSArray arrayWithObjects:one, two, three, four, nil];
  [_welcomeView setViewArray:views];
  [self.view addSubview:_welcomeView];
  
  // Next Button
  _nextButton = [[UIButton alloc] initWithFrame:CGRectZero];
  _nextButton.width = 280;
  _nextButton.height = 41;
  _nextButton.top = self.view.height - _nextButton.height - 20;
  _nextButton.left = 20;
  
  [_nextButton setBackgroundImage:[[UIImage imageNamed:@"button_round_blue.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:0] forState:UIControlStateNormal];
  //  [_loginButton setContentEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
  [_nextButton setTitle:@"Learn More About Moogle" forState:UIControlStateNormal];
  [_nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [_nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
  _nextButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16.0];
  _nextButton.titleLabel.shadowColor = [UIColor blackColor];
  _nextButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
  [_nextButton addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:_nextButton];
  
  // Setup Login Buttons
  _loginButton = [[UIButton alloc] initWithFrame:CGRectZero];
  _loginButton.width = 320;
  _loginButton.height = 44;
  _loginButton.top = _nextButton.bottom;
  
  [_loginButton setBackgroundImage:[[UIImage imageNamed:@"gradient_gray.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0] forState:UIControlStateNormal];
  //  [_loginButton setContentEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
  [_loginButton setTitle:@"Connect with Facebook" forState:UIControlStateNormal];
  [_loginButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [_loginButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
  _loginButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16.0];
  _loginButton.titleLabel.shadowColor = [UIColor whiteColor];
//  _loginButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
  [_loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
//  [self.view addSubview:_loginButton];
  
}

#pragma mark -
#pragma mark Button Actions
- (void)login {
  [_facebook authorize:FB_PERMISSIONS delegate:self];
}

- (void)logout {
  [_facebook logout:self];
}

- (void)next {
  if (_welcomeView.currentPage == (_welcomeView.numPages - 1)) {
    [self login];
    return;
  }
  
  [_welcomeView next];
  
  // Set button title
  NSString *nextTitle = nil;
  switch (_welcomeView.currentPage) {
    case 0:
      nextTitle = @"Moogle to the rescue";
      break;
    case 1:
      nextTitle = @"There's an app for that";
      break;
    case 2:
      nextTitle = @"This changes everything";
      break;
    case 3:
      nextTitle = @"Connect With Facebook";
      break;
    default:
      nextTitle = @"Moogle to the rescue";
      break;
  }
  
  [_nextButton setTitle:nextTitle forState:UIControlStateNormal];
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
}

- (void)fbDidLogout {
  // Clear all user defaults
  [[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
  
  if (self.delegate && [self.delegate respondsToSelector:@selector(userDidLogout)]) {
    [self.delegate performSelector:@selector(userDidLogout)];
  }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kLogoutRequested object:nil];
  RELEASE_SAFELY(_nextButton);
  RELEASE_SAFELY(_loginButton);
  [super dealloc];
}

@end