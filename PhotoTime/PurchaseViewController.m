//
//  PurchaseViewController.m
//  PhotoTime
//
//  Created by Peter Shih on 8/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PurchaseViewController.h"
#import "MKStoreManager.h"
#import "UIImage+SML.h"

@implementation PurchaseViewController

- (id)init {
  self = [super init];
  if (self) {
  }
  return self;
}

- (void)dealloc {
  RELEASE_SAFELY(_buyButton);
  RELEASE_SAFELY(_buyUnlimitedButton);
  RELEASE_SAFELY(_cancelButton);
  [super dealloc];
}

- (void)viewDidUnload {
  [super viewDidUnload];
  
}

#pragma mark - View
- (void)loadView {
  [super loadView];
  
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_purchase.png"]] autorelease];
  bg.frame = self.view.bounds;
  bg.autoresizingMask = ~UIViewAutoresizingNone;
  [self.view addSubview:bg];
  
  _buyButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  if (isDeviceIPad()) {
    _buyButton.frame = CGRectMake(10, 620, self.view.width - 20, 105);
  } else {
    _buyButton.frame = CGRectMake(10, 290, self.view.width - 20, 44);
  }
  [_buyButton addTarget:self action:@selector(buy) forControlEvents:UIControlEventTouchUpInside];
  [_buyButton setBackgroundImage:[UIImage imageNamed:@"button_purchase_one.png"] forState:UIControlStateNormal];
  
  _buyUnlimitedButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  if (isDeviceIPad()) {
    _buyUnlimitedButton.frame = CGRectMake(10, 735, self.view.width - 20, 190);
  } else {
    _buyUnlimitedButton.frame = CGRectMake(10, 340, self.view.width - 20, 79);
  }
  [_buyUnlimitedButton addTarget:self action:@selector(buyUnlimited) forControlEvents:UIControlEventTouchUpInside];
  [_buyUnlimitedButton setBackgroundImage:[UIImage imageNamed:@"button_purchase_unlimited.png"] forState:UIControlStateNormal];
  
  _cancelButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  _cancelButton.frame = CGRectMake(6, 6, 34, 34);
  [_cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
  [_cancelButton setBackgroundImage:[UIImage imageNamed:@"button_delete.png"] forState:UIControlStateNormal];
  
  [self.view addSubview:_buyButton];
  [self.view addSubview:_buyUnlimitedButton];
  [self.view addSubview:_cancelButton];
}

#pragma mark - Actions
- (void)buy {
  _buyButton.enabled = NO;
  _buyUnlimitedButton.enabled = NO;
  _cancelButton.enabled = NO;
  [[MKStoreManager sharedManager] buyFeature:SK_ADD_STREAM 
                                  onComplete:^(NSString *purchasedFeature){
                                    // Purchase complete, increment availableStreams
                                    [[MKStoreManager sharedManager] consumeProduct:SK_ADD_STREAM quantity:1];
                                    NSInteger availableStreams = [[NSUserDefaults standardUserDefaults] integerForKey:@"availableStreams"];
                                    [[NSUserDefaults standardUserDefaults] setInteger:(availableStreams + 1) forKey:@"availableStreams"];
                                    [[NSUserDefaults standardUserDefaults] synchronize];
                                    [self dismissModalViewControllerAnimated:YES];
                                  } 
                                 onCancelled:^{
                                   _buyButton.enabled = YES;
                                   _buyUnlimitedButton.enabled = YES;
                                   _cancelButton.enabled = YES;
                                 }];
}

- (void)buyUnlimited {
  _buyButton.enabled = NO;
  _buyUnlimitedButton.enabled = NO;
  _cancelButton.enabled = NO;
  [[MKStoreManager sharedManager] buyFeature:SK_UNLIMITED_STREAMS 
                                  onComplete:^(NSString *purchasedFeature){
                                    // Purchase complete, increment availableStreams to infinity
                                    [[NSUserDefaults standardUserDefaults] setInteger:INT_MAX forKey:@"availableStreams"];
                                    [[NSUserDefaults standardUserDefaults] synchronize];
                                    [self dismissModalViewControllerAnimated:YES];
                                  } 
                                 onCancelled:^{
                                   _buyButton.enabled = YES;
                                   _buyUnlimitedButton.enabled = YES;
                                   _cancelButton.enabled = YES;
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
