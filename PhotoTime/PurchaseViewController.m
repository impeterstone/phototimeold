//
//  PurchaseViewController.m
//  PhotoTime
//
//  Created by Peter Shih on 8/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PurchaseViewController.h"
#import "MKStoreManager.h"

@implementation PurchaseViewController

- (id)init {
  self = [super init];
  if (self) {
  }
  return self;
}

- (void)dealloc {
  [super dealloc];
}

#pragma mark - View
- (void)loadView {
  [super loadView];
  
  UINavigationBar *navBar = [[[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44)] autorelease];
  navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  _navItem = [[[UINavigationItem alloc] init] autorelease];
  [navBar setItems:[NSArray arrayWithObject:_navItem]];
  [self.view addSubview:navBar];
  
  _navItem.rightBarButtonItem = [UIBarButtonItem navButtonWithTitle:@"Buy" withTarget:self action:@selector(buy) buttonType:NavButtonTypeBlue];
  _navItem.leftBarButtonItem = [UIBarButtonItem navButtonWithTitle:@"Cancel" withTarget:self action:@selector(cancel) buttonType:NavButtonTypeNormal];
  _navItem.titleView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"phototime_logo.png"]] autorelease];
}

#pragma mark - Actions
- (void)buy {
  _navItem.leftBarButtonItem.enabled = NO;
  _navItem.rightBarButtonItem.enabled = NO;
  [[MKStoreManager sharedManager] buyFeature:SK_PHOTO_STREAMS 
                                  onComplete:^(NSString *purchasedFeature){
                                    _navItem.leftBarButtonItem.enabled = NO;
                                    _navItem.rightBarButtonItem.enabled = NO;
                                    [self dismissModalViewControllerAnimated:YES];
                                  } 
                                 onCancelled:^{
                                   _navItem.leftBarButtonItem.enabled = YES;
                                   _navItem.rightBarButtonItem.enabled = YES;
                                 }];
}

- (void)cancel {
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - State Machine
- (BOOL)dataIsAvailable {
  return YES;
}
- (BOOL)dataIsLoading {
  return NO;
}

@end
