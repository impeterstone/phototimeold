//
//  LoginViewController.m
//  PhotoTime
//
//  Created by Peter Shih on 3/23/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
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
  
  self.view.backgroundColor = [UIColor whiteColor];
  
  // Setup Welcome
  _welcomeView = [[[PSWelcomeView alloc] initWithFrame:CGRectMake(0, 26, self.view.width, self.view.width)] autorelease];
  UIImageView *one = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nux_comic_1.png"]] autorelease];
  UIImageView *two = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nux_comic_2.png"]] autorelease];
  UIImageView *three = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nux_comic_3.png"]] autorelease];
  UIImageView *four = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nux_comic_4.png"]] autorelease];
  NSArray *views = [NSArray arrayWithObjects:one, two, three, four, nil];
  for (UIImageView *iv in views) {
    iv.width = _welcomeView.width;
    iv.height = _welcomeView.height;
  }
  [_welcomeView setViewArray:views];
  [self.view addSubview:_welcomeView];
  
  // Next Button
  _nextButton = [[UIButton alloc] initWithFrame:CGRectZero];
  
  if (isDeviceIPad()) {
    [_nextButton setBackgroundImage:[[UIImage imageNamed:@"button_sketch-pad.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0] forState:UIControlStateNormal];
    _nextButton.titleLabel.font = [UIFont fontWithName:@"Marker Felt" size:36.0];
    _nextButton.height = 114;
  } else {
    [_nextButton setBackgroundImage:[[UIImage imageNamed:@"button_sketch.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0] forState:UIControlStateNormal];
    _nextButton.titleLabel.font = [UIFont fontWithName:@"Marker Felt" size:20.0];
    _nextButton.height = 44;
  }
  
  _nextButton.width = self.view.width - 40;
  _nextButton.top = self.view.height - _nextButton.height - 20;
  _nextButton.left = 20;
  
  [_nextButton setTitle:@"That's smart, tell me more" forState:UIControlStateNormal];
  [_nextButton setTitleColor:COLOR_CHARCOAL forState:UIControlStateNormal];
  [_nextButton setTitleColor:COLOR_CHARCOAL forState:UIControlStateHighlighted];
//  _nextButton.titleLabel.shadowColor = [UIColor blackColor];
//  _nextButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
  [_nextButton addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:_nextButton];
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
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"login.welcome"];
    [self login];
    return;
  } else {
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:[NSString stringWithFormat:@"login.next: %d", _welcomeView.currentPage]];
  }
  
  [_welcomeView next];
  
  [self updateNextButton];
}

- (void)updateNextButton {
  // Set button title
  NSString *nextTitle = nil;
  switch (_welcomeView.currentPage) {
    case 0:
      nextTitle = @"That's smart, tell me more";
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
      nextTitle = @"That's smart, tell me more";
      break;
  }
  
  [_nextButton setTitle:nextTitle forState:UIControlStateNormal];
}

#pragma mark -
#pragma mark FBSessionDelegate
- (void)fbDidLogin {
  // Reset welcome state
  [_welcomeView scrollToPage:0 animated:NO];
  [self updateNextButton];
  
  // Store Access Token
  // ignore the expiration since we request non-expiring offline access
  [[NSUserDefaults standardUserDefaults] setObject:[_facebook.accessToken stringWithPercentEscape] forKey:@"facebookAccessToken"];
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
  if (self.delegate && [self.delegate respondsToSelector:@selector(userDidLogout)]) {
    [self.delegate performSelector:@selector(userDidLogout)];
  }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kLogoutRequested object:nil];
  RELEASE_SAFELY(_nextButton);
  [super dealloc];
}

@end