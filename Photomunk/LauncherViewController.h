//
//  LauncherViewController.h
//  Photomunk
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSViewController.h"

@interface LauncherViewController : PSViewController <UITabBarControllerDelegate> {
  UITabBarController *_tabBarController;
}

- (void)selectActionButton;

@end
