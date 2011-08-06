//
//  CardModalTableViewController.m
//  PhotoTime
//
//  Created by Peter Shih on 3/30/11.
//  Copyright 2011 Seven Minute Labs, Inc.. All rights reserved.
//

#import "CardModalTableViewController.h"

@implementation CardModalTableViewController

- (id)init {
  self = [super init];
  if (self) {
  }
  return self;
}

- (void)loadView {
  [super loadView];
  
}

- (void)showDismissButton {
  // Dismiss Button
  UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
  self.navigationItem.leftBarButtonItem = dismissButton;
  [dismissButton release];
}

- (void)dismiss {
  [self dismissModalViewControllerAnimated:YES];
}

- (void)dealloc {
  [super dealloc];
}

@end
