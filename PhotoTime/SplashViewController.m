//
//  SplashViewController.m
//  PhotoTime
//
//  Created by Peter Shih on 7/29/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import "SplashViewController.h"

@implementation SplashViewController

- (id)init {
  self = [super init];
  if (self) {
  }
  return self;
}

- (void)dealloc {
  [super dealloc];
  RELEASE_SAFELY(_loadingIndicator);
}

#pragma mark - View
- (void)loadView {
  [super loadView];
  
  if (isDeviceIPad()) {
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_weave-pad.png"]];
  } else {
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_weave.png"]];
  }
  
  _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  [_loadingIndicator startAnimating];
  _loadingIndicator.center = self.view.center;
  
  [self.view addSubview:_loadingIndicator];
}

@end
