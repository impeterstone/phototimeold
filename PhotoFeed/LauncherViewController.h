//
//  LauncherViewController.h
//  PhotoFeed
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSViewController.h"

@class AlbumViewController;

@interface LauncherViewController : UIViewController {
  AlbumViewController *_avc;
  UINavigationController *_anc;
}

@end
