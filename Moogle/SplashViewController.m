//
//  SplashViewController.m
//  Moogle
//
//  Created by Peter Shih on 7/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
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
  
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Default.png"]];
  
  _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  [_loadingIndicator startAnimating];
  _loadingIndicator.center = self.view.center;
  
  [self.view addSubview:_loadingIndicator];
}

@end
