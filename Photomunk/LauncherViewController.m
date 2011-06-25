//
//  LauncherViewController.m
//  Photomunk
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LauncherViewController.h"
#import "AlbumViewController.h"
#import "MoreViewController.h"

static UIImage *_actionImage = nil;


@implementation LauncherViewController

+ (void)initialize {
  _actionImage = [[UIImage imageNamed:@"tab_action.png"] retain];
}

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

- (void)loadView {
  self.wantsFullScreenLayout = NO;
  
  _tabBarController = [[UITabBarController alloc] init];
  _tabBarController.delegate = self;
  _tabBarController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  
  // Setup Tabs
  AlbumViewController *me = [[[AlbumViewController alloc] init] autorelease];
  me.albumType = AlbumTypeMe;
  UINavigationController *meNav = [[[UINavigationController alloc] initWithRootViewController:me] autorelease];
  
  AlbumViewController *friends = [[[AlbumViewController alloc] init] autorelease];
  friends.albumType = AlbumTypeFriends;
  UINavigationController *friendsNav = [[[UINavigationController alloc] initWithRootViewController:friends] autorelease];
  
  AlbumViewController *favorites = [[[AlbumViewController alloc] init] autorelease];
  favorites.albumType = AlbumTypeFavorites;
  UINavigationController *favoritesNav = [[[UINavigationController alloc] initWithRootViewController:favorites] autorelease];
  
//  SearchViewController *search = [[[SearchViewController alloc] init] autorelease];
//  UINavigationController *searchNav = [[[UINavigationController alloc] initWithRootViewController:search] autorelease];
  
  AlbumViewController *history = [[[AlbumViewController alloc] init] autorelease];
  history.albumType = AlbumTypeHistory;
  UINavigationController *historyNav = [[[UINavigationController alloc] initWithRootViewController:history] autorelease];
  
  MoreViewController *more = [[[MoreViewController alloc] init] autorelease];
  UINavigationController *moreNav = [[[UINavigationController alloc] initWithRootViewController:more] autorelease];
  
  // Setup Tab Items
  me.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Me" image:[UIImage imageNamed:@"111-user.png"] tag:7001] autorelease];
  friends.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Friends" image:[UIImage imageNamed:@"112-group.png"] tag:7002] autorelease];
  favorites.tabBarItem = [[[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemFavorites tag:7003] autorelease];
  history.tabBarItem = [[[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemHistory tag:7004] autorelease];
  more.tabBarItem = [[[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemMore tag:7005] autorelease];
  
  // Set Tab Controllers
  _tabBarController.viewControllers = [NSArray arrayWithObjects:meNav, friendsNav, favoritesNav, historyNav, moreNav, nil];
  
  // Add to view
  self.view = _tabBarController.view;
  
  // Select previously chosen tab
  _tabBarController.selectedViewController = [_tabBarController.viewControllers objectAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"lastSelectedTab"]];
  
  // Custom tab action button
//  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
//  button.frame = CGRectMake(130.0, 3.0, _actionImage.size.width, _actionImage.size.height);
//  [button setBackgroundImage:_actionImage forState:UIControlStateNormal];
//  [button addTarget:self action:@selector(selectActionButton) forControlEvents:UIControlEventTouchUpInside];
//  
//  [_tabBarController.tabBar addSubview:button];
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
  NSUInteger tabIndex = [_tabBarController.viewControllers indexOfObject:viewController];
  [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:tabIndex] forKey:@"lastSelectedTab"];
}

- (void)selectActionButton {
  _tabBarController.selectedViewController = [_tabBarController.viewControllers objectAtIndex:2];
}

- (void)dealloc {
  RELEASE_SAFELY(_tabBarController);
  [super dealloc];
}

@end
