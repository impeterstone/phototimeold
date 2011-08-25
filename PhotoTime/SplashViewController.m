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

- (void)viewDidUnload {
  [super viewDidUnload];
  RELEASE_SAFELY(_loadingIndicator);
}

- (void)dealloc {
  [super dealloc];
  RELEASE_SAFELY(_loadingIndicator);
}

#pragma mark - View
- (void)loadView {
  [super loadView];
  
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default.png"]] autorelease];
  bg.frame = self.view.bounds;
  bg.autoresizingMask = ~UIViewAutoresizingNone;
  [self.view addSubview:bg];
  
  _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  [_loadingIndicator startAnimating];
  _loadingIndicator.center = self.view.center;
  
  [self.view addSubview:_loadingIndicator];
}

@end
