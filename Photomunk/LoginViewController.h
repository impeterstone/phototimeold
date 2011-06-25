//
//  LoginViewController.h
//  Photomunk
//
//  Created by Peter Shih on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSViewController.h"
#import "LoginDelegate.h"
#import "FBConnect.h"

@class DDProgressView;

@interface LoginViewController : PSViewController <FBSessionDelegate, PSDataCenterDelegate> {
  Facebook *_facebook;
  UIButton *_loginButton;
  UIActivityIndicatorView *_loadingIndicator;
  DDProgressView *_progressView;
  id <LoginDelegate> _delegate;
}

@property (nonatomic, assign) id <LoginDelegate> delegate;
@property (nonatomic, retain) UIButton *loginButton;

- (void)logout;

- (void)updateLoginProgress:(NSNotification *)notification;
- (void)updateLoginProgressOnMainThread:(NSNumber *)progress;

@end
