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

enum {
  NavButtonTypeNormal = 0,
  NavButtonTypeBlue = 1,
  NavButtonTypeRed = 2,
  NavButtonTypeGreen = 3,
  NavButtonTypeSilver = 4
};
typedef uint32_t NavButtonType;

@class PSNullView;

@interface CardViewController : PSViewController <CardStateMachine, PSDataCenterDelegate> {
  UIScrollView *_activeScrollView; // subclasses should set this if they have a scrollView
  UILabel *_navTitleLabel;
  PSNullView *_nullView;
  NSString *_loadingLabel;
  NSString *_emptyLabel;
}

- (void)clearCachedData;
- (void)unloadCardController;
- (void)reloadCardController;
- (void)resetCardController;
- (void)dataSourceDidLoad;

- (void)setupNullView;

// Nav buttons
- (void)addBackButton;
- (UIBarButtonItem *)navButtonWithTitle:(NSString *)title withTarget:(id)target action:(SEL)action buttonType:(NavButtonType)buttonType;
- (UIBarButtonItem *)navButtonWithImage:(UIImage *)image withTarget:(id)target action:(SEL)action buttonType:(NavButtonType)buttonType;

// Orientation
- (void)orientationChangedFromNotification:(NSNotification *)notification;

@end
