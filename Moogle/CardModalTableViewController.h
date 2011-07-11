//
//  CardModalTableViewController.h
//  Moogle
//
//  Created by Peter Shih on 3/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardTableViewController.h"

@interface CardModalTableViewController : CardTableViewController {
}

- (void)showDismissButton;
- (void)dismiss;

@end
