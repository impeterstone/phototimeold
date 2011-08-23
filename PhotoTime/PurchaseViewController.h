//
//  PurchaseViewController.h
//  PhotoTime
//
//  Created by Peter Shih on 8/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSBaseViewController.h"

@interface PurchaseViewController : PSBaseViewController {
  UIButton *_buyButton;
  UIButton *_buyUnlimitedButton;
  UIButton *_cancelButton;
}

- (void)buy;
- (void)buyUnlimited;

@end
