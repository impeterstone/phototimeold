//
//  LoginViewController.h
//  PhotoTime
//
//  Created by Peter Shih on 3/23/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSViewController.h"
#import "LoginDelegate.h"
#import "FBConnect.h"

@class PSWelcomeView;

@interface LoginViewController : PSViewController <FBSessionDelegate, PSDataCenterDelegate> {
  Facebook *_facebook;
  UIButton *_nextButton;
  PSWelcomeView *_welcomeView;
  id <LoginDelegate> _delegate;
}

@property (nonatomic, assign) id <LoginDelegate> delegate;

- (void)logout;
- (void)next;
//- (void)prev;
- (void)updateNextButton;

@end
