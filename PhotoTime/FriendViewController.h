//
//  FriendViewController.h
//  PhotoTime
//
//  Created by Peter Shih on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSTableViewController.h"
#import "FriendSelectDelegate.h"

@interface FriendViewController : PSTableViewController {
  NSMutableSet *_selectedFriends;
  id <FriendSelectDelegate> _delegate;
}

@property (nonatomic, assign) id <FriendSelectDelegate> delegate;

@end
