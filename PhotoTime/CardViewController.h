//
//  CardViewController.h
//  PhotoTime
//
//  Created by Peter Shih on 2/10/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSViewController.h"
#import "CardStateMachine.h"
#import "PSDataCenterDelegate.h"

@class PSNullView;

@interface CardViewController : PSViewController <CardStateMachine, PSDataCenterDelegate> {
  UIScrollView *_activeScrollView; // subclasses should set this if they have a scrollView
  UILabel *_navTitleLabel;
  PSNullView *_nullView;
  NSString *_loadingLabel;
  NSString *_emptyLabel;
}

@property (nonatomic, retain) UILabel *navTitleLabel;

- (void)clearCachedData;
- (void)unloadCardController;
- (void)reloadCardController;
- (void)resetCardController;
- (void)dataSourceDidLoad;

- (void)setupNullView;

// Nav buttons
- (void)addBackButton;


// Orientation
- (void)orientationChangedFromNotification:(NSNotification *)notification;

@end
