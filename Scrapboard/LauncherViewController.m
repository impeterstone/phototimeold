//
//  LauncherViewController.m
//  Scrapboard
//
//  Created by Peter Shih on 4/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LauncherViewController.h"
#import "FollowedViewController.h"
#import "FirehoseViewController.h"

@implementation LauncherViewController

@synthesize cards = _cards;

- (id)init {
  self = [super init];
  if (self) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(headerTabSelected:) name:kHeaderTabSelected object:nil];
  }
  return self;
}

- (void)loadView {
  [super loadView];
  self.wantsFullScreenLayout = YES;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.view.opaque = YES;
  self.view.frame = CGRectMake(0, 20, 320, 460);
  self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
  self.view.autoresizesSubviews = YES;
  
  // Set Page State
  _previousPage = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastSelectedCard"]; // Start at last selected card
  _currentPage = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastSelectedCard"]; // Start at last selected card
  
  // Setup Chrome
  [self setupChrome];
  
  // Setup Controllers
  [self setupControllers];
}

- (void)setupChrome { 
  // Setup CardScrollView
  _cardScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CARD_WIDTH, CARD_HEIGHT)];
  _cardScrollView.delegate = self;
  _cardScrollView.contentSize = CGSizeMake(CARD_WIDTH * NUM_CARDS, CARD_HEIGHT);
  _cardScrollView.contentOffset = CGPointMake(CARD_WIDTH * _currentPage, 0); // start at page 1
  _cardScrollView.scrollsToTop = NO;
  _cardScrollView.pagingEnabled = YES;
  _cardScrollView.showsVerticalScrollIndicator = NO;
  _cardScrollView.showsHorizontalScrollIndicator = NO;
  
  [self.view addSubview:_cardScrollView];
}

- (void)setupControllers {
  
  FollowedViewController *followedViewController = [[FollowedViewController alloc] init];
  UINavigationController *followedNavController = [[UINavigationController alloc] initWithRootViewController:followedViewController];
  
  FirehoseViewController *firehoseViewController = [[FirehoseViewController alloc] init];
  UINavigationController *firehoseNavController = [[UINavigationController alloc] initWithRootViewController:firehoseViewController];
  
  // Set nav delegates
  followedNavController.delegate = self;
  firehoseNavController.delegate = self;
  
  // Add controllers to array
  _cards = [[NSArray alloc] initWithObjects:followedNavController, firehoseNavController, nil];
  
  // Set frames for cards and add to card scroll view
  int i = 0;
  for (UINavigationController *card in _cards) {
    card.view.frame = CGRectMake(CARD_WIDTH * i, 0, CARD_WIDTH, CARD_HEIGHT);
    [_cardScrollView addSubview:card.view];
    i++;
  }
  
  [followedViewController release];
  [followedNavController release];
  [firehoseViewController release];
  [firehoseNavController release];
}

#pragma mark UINavigationControllerDelegate
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
  //  DLog(@"nav will show controller: %@", [viewController class]);
  // Tell the new visible controller to reload it's data if it responds to it
  id visibleViewController = [_cards objectAtIndex:_currentPage];
  
  // Disable scrolling if not on top layer
  if ([[visibleViewController viewControllers] count] > 1) {
    _cardScrollView.scrollEnabled = NO;
  } else {
    _cardScrollView.scrollEnabled = YES;
  }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
  //  DLog(@"nav did show controller: %@", [viewController class]);
}

- (void)headerTabSelected:(NSNotification *)note {
  NSDictionary *payload = [note userInfo];
  NSNumber *tabIndex = [payload valueForKey:@"tabIndex"];
  [_cardScrollView scrollRectToVisible:[[[self.cards objectAtIndex:[tabIndex integerValue]] view] frame] animated:YES];
}

#pragma mark -
#pragma mark Card State Machine
- (void)updateScrollsToTop {
  // Because only ONE scrollView can have scrollsToTop set to YES under the entire view hieararchy, we need to loop thru all the cards and disable all scrollViews except for the one that is currently visible.
}

- (void)updateCards {
  // Tell the previous controller to unload any data if it responds to it
  id previousViewController = [_cards objectAtIndex:_previousPage];
  if ([[previousViewController topViewController] respondsToSelector:@selector(unloadCardController)]) {
    [[previousViewController topViewController] performSelector:@selector(unloadCardController)];
  }
  
  // Tell the new visible controller to reload it's data if it responds to it
  id visibleViewController = [_cards objectAtIndex:_currentPage];
  if ([[visibleViewController topViewController] respondsToSelector:@selector(reloadCardController)]) {
    [[visibleViewController topViewController] performSelector:@selector(reloadCardController)];
  }
  
  // Update scrollsTopTop state
  for (UINavigationController *card in _cards) {
    CardViewController *cardController = (CardViewController *)[card topViewController];
    if ([cardController isEqual:[visibleViewController topViewController]]) {
      // Visible
      [cardController updateScrollsToTop:YES];
    } else {
      [cardController updateScrollsToTop:NO];
    }
  }
}

- (void)clearAllCachedData {
  
}

#pragma mark -
#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)sender {
  // We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
  // which a scroll event generated from the user hitting the page control triggers updates from
  // the delegate method. We use a boolean to disable the delegate logic when the page control is used.
  if (_cardScrollView.contentOffset.x < 0 || _cardScrollView.contentOffset.x > (CARD_WIDTH * (NUM_CARDS - 1))) return;
  
  // Switch the indicator when more than 50% of the previous/next page is visible
  CGFloat pageWidth = _cardScrollView.frame.size.width;
  int page = floor((_cardScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
  _currentPage = page;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {  
  [self zoomOutBeforeScrolling];
}

// At the end of scroll animation, load the active view
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  [self zoomInAfterScrolling];
}

// Sometimes scrollViewDidEndDecelerating doesn't get called but this does instead
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if (!decelerate) {
    [self zoomInAfterScrolling];
  }
}

// This is called when the scrolling stops after tapping a navigation button
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
  [self zoomInAfterScrolling];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
  // Fire off something early (before the scroll view settles)
}

- (void)zoomOutBeforeScrolling {
  _previousPage = _currentPage;
  
  // When the user begins scrolling, zoom into card view
  for (UINavigationController *card in _cards) {
    [self zoomOut:card];
  }
}

- (void)zoomInAfterScrolling {
  // When the card is finished paging, zoom it out to take the full screen
  for (UINavigationController *card in _cards) {
    [self zoomIn:card];
  }
  
  // Only perform unload/reload if the card page actually changed
  if (_currentPage != _previousPage) {    
    [self updateCards];
  }
}

#pragma mark -
#pragma mark Animation
- (void)zoomIn:(UINavigationController *)card {
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.1];
  card.view.transform = CGAffineTransformMakeScale(1,1);
  card.view.layer.cornerRadius = 0;
  card.view.layer.masksToBounds = YES;
  [UIView commitAnimations];
  
  // iOS4 ONLY
  //  [UIView animateWithDuration:0.2
  //      animations:^{
  //        card.navigationBar.hidden = NO;
  //        card.view.transform = CGAffineTransformMakeScale(1,1);
  //        card.topViewController.view.layer.cornerRadius = 0;
  //        card.topViewController.view.layer.masksToBounds = YES;
  //      }
  //      completion:^(BOOL finished){ 
  //        card.navigationBar.hidden = NO;
  //      }];
}

- (void)zoomOut:(UINavigationController *)card {
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.2];
  card.view.transform = CGAffineTransformMakeScale(0.90,0.90);
  card.view.layer.cornerRadius = 10;
  card.view.layer.masksToBounds = YES;
  [UIView commitAnimations];
  
  // iOS4 ONLY
  //  [UIView animateWithDuration:0.2
  //      animations:^{
  //        card.view.transform = CGAffineTransformMakeScale(0.9,0.915);
  //        card.topViewController.view.layer.cornerRadius = 6;
  //        card.topViewController.view.layer.masksToBounds = YES;
  //      }
  //      completion:^(BOOL finished){ 
  //        card.navigationBar.hidden = YES;
  //      }];
}


- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kHeaderTabSelected object:nil];
  RELEASE_SAFELY(_cardScrollView);
  RELEASE_SAFELY(_cards);
  [super dealloc];
}

@end
