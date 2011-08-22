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
#import "PSTextView.h"

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

#pragma mark - View
- (void)loadView {
  [super loadView];
  
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lolcats_money.jpg"]] autorelease];
  bg.frame = self.view.bounds;
  bg.autoresizingMask = ~UIViewAutoresizingNone;
  [self.view addSubview:bg];
  
  PSTextView *tv = [[[PSTextView alloc] initWithFrame:CGRectMake(10, 225, 300, 100)] autorelease];
  tv.editable = NO;
  tv.backgroundColor = RGBACOLOR(0, 0, 0, 0.6);
  tv.textColor = [UIColor whiteColor];
  tv.font = LARGE_FONT;
  tv.text = @"Get the ability to create more groups of albums for the people you care about. Some popular examples are: My Family, My Boys, or My Classmates.";
  tv.layer.masksToBounds = YES;
  tv.layer.cornerRadius = 10.0;
  [self.view addSubview:tv];
  
  _buyButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  _buyButton.frame = CGRectMake(10, 330, 300, 37);
  [_buyButton addTarget:self action:@selector(buy) forControlEvents:UIControlEventTouchUpInside];
  [_buyButton setTitle:@"Buy 1 extra stream for 99¢" forState:UIControlStateNormal];
  [_buyButton.titleLabel setFont:LARGE_FONT];
  [_buyButton setBackgroundImage:[UIImage stretchableImageNamed:@"button_round_green.png" withLeftCapWidth:11 topCapWidth:0] forState:UIControlStateNormal];
  
  _buyUnlimitedButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  _buyUnlimitedButton.frame = CGRectMake(10, 370, 300, 37);
  [_buyUnlimitedButton addTarget:self action:@selector(buy) forControlEvents:UIControlEventTouchUpInside];
  [_buyUnlimitedButton setTitle:@"Buy unlimited streams for $1.99" forState:UIControlStateNormal];
  [_buyUnlimitedButton.titleLabel setFont:LARGE_FONT];
  [_buyUnlimitedButton setBackgroundImage:[UIImage stretchableImageNamed:@"button_round_green.png" withLeftCapWidth:11 topCapWidth:0] forState:UIControlStateNormal];
  
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
  [[MKStoreManager sharedManager] buyFeature:SK_PHOTO_STREAMS 
                                  onComplete:^(NSString *purchasedFeature){
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
