//
//  CardViewController.h
//  Moogle
//
//  Created by Peter Shih on 2/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSViewController.h"
#import "CardStateMachine.h"
#import "PSDataCenterDelegate.h"
#import "HeaderTabView.h"
#import "HeaderTabViewDelegate.h"

@class PSNullView;

@interface CardViewController : PSViewController <CardStateMachine, PSDataCenterDelegate, HeaderTabViewDelegate> {
  UIScrollView *_activeScrollView; // subclasses should set this if they have a scrollView
  UILabel *_navTitleLabel;
  HeaderTabView *_headerTabView;
  PSNullView *_nullView;
}

- (void)clearCachedData;
- (void)unloadCardController;
- (void)reloadCardController;
- (void)resetCardController;
- (void)dataSourceDidLoad;

- (void)setupNullView;
- (void)setupHeaderTabViewWithFrame:(CGRect)frame;

// Nav buttons
- (void)addBackButton;
- (UIBarButtonItem *)navButtonWithTitle:(NSString *)title withTarget:(id)target action:(SEL)action;
- (UIBarButtonItem *)navButtonWithImage:(UIImage *)image withTarget:(id)target action:(SEL)action isLeft:(BOOL)isLeft;

// Orientation
- (void)orientationChangedFromNotification:(NSNotification *)notification;

@end
