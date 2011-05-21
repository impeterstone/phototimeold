//
//  LauncherViewController.m
//  PhotoFeed
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LauncherViewController.h"
#import "AlbumViewController.h"

@implementation LauncherViewController

- (id)init {
  self = [super init];
  if (self) {
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [_tabBarController viewWillAppear:animated];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  _tabBarController = [[UITabBarController alloc] init];
  _tabBarController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  
  // Setup Tabs
  AlbumViewController *me = [[[AlbumViewController alloc] init] autorelease];
  me.albumType = AlbumTypeMe;
  UINavigationController *meNav = [[[UINavigationController alloc] initWithRootViewController:me] autorelease];
  AlbumViewController *friends = [[[AlbumViewController alloc] init] autorelease];
  friends.albumType = AlbumTypeFriends;
  UINavigationController *friendsNav = [[[UINavigationController alloc] initWithRootViewController:friends] autorelease];
  AlbumViewController *mobile = [[[AlbumViewController alloc] init] autorelease];
  mobile.albumType = AlbumTypeMobile;
  UINavigationController *mobileNav = [[[UINavigationController alloc] initWithRootViewController:mobile] autorelease];
  AlbumViewController *profile = [[[AlbumViewController alloc] init] autorelease];
  profile.albumType = AlbumTypeProfile;
  UINavigationController *profileNav = [[[UINavigationController alloc] initWithRootViewController:profile] autorelease];
  
  // Setup Tab Items
  me.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Me" image:[UIImage imageNamed:@"111-user.png"] tag:7000] autorelease];
  friends.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Friends" image:[UIImage imageNamed:@"112-group.png"] tag:7001] autorelease];
  mobile.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Mobile" image:[UIImage imageNamed:@"32-iphone.png"] tag:7002] autorelease];
  profile.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Profile" image:[UIImage imageNamed:@"111-user.png"] tag:7003] autorelease];
  
  // Set Tab Controllers
  _tabBarController.viewControllers = [NSArray arrayWithObjects:meNav, friendsNav, mobileNav, profileNav, nil];
  
  // Add to view
  self.view = _tabBarController.view;
}

- (void)dealloc {
  RELEASE_SAFELY(_tabBarController);
  [super dealloc];
}

@end
