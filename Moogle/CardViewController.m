//
//  CardViewController.m
//  Moogle
//
//  Created by Peter Shih on 2/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CardViewController.h"
#import "PSNullView.h"

#define NAV_BUTTON_FONT [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0]

@interface CardViewController (Private)

@end

@implementation CardViewController

- (id)init {
  self = [super init];
  if (self) {
    _activeScrollView = nil;
  }
  return self;
}

- (void)loadView {
  [super loadView];
  
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"weave-bg.png"]];
  
  // Background View
  //  UIImageView *backgroundView = [[UIImageView alloc] initWithImage:_backgroundImage];
  //  backgroundView.frame = self.view.bounds;
  //  [self.view addSubview:backgroundView];
  //  [backgroundView release];
  
  _nullView = [[PSNullView alloc] initWithFrame:self.view.bounds];
  [self.view addSubview:_nullView];
  
  //  self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];
  
  // Setup Nav Bar
  UIView *navTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, self.navigationController.navigationBar.height)];
  navTitleView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  _navTitleLabel = [[UILabel alloc] initWithFrame:navTitleView.bounds];
  _navTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  _navTitleLabel.textAlignment = UITextAlignmentCenter;
  _navTitleLabel.textColor = FB_COLOR_VERY_LIGHT_BLUE;
  _navTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
  _navTitleLabel.numberOfLines = 3;
  _navTitleLabel.shadowColor = [UIColor blackColor];
  _navTitleLabel.shadowOffset = CGSizeMake(0, 1);
  _navTitleLabel.backgroundColor = [UIColor clearColor];
  [navTitleView addSubview:_navTitleLabel];
  
  self.navigationItem.titleView = navTitleView;
  [navTitleView release];
  
  self.navigationController.navigationBar.tintColor = [UIColor darkGrayColor];
  
  //  self.navigationItem.titleView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav-logo.png"]] autorelease];
}

//- (void)viewDidAppear:(BOOL)animated {
//  [super viewDidAppear:animated];
//  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
//  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChangedFromNotification:) name:UIDeviceOrientationDidChangeNotification object:nil];
//}
//
//- (void)viewDidDisappear:(BOOL)animated {
//  [super viewDidDisappear:animated];
//  [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
//  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
//}

- (void)orientationChangedFromNotification:(NSNotification *)notification {
  // may should implement
}

- (void)back {
  [self.navigationController popViewControllerAnimated:YES];
}

// Optional Implementation
- (void)addBackButton {
  UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
  back.frame = CGRectMake(0, 0, 60, self.navigationController.navigationBar.height - 14);
  [back setTitle:@"Back" forState:UIControlStateNormal];
  [back setTitleEdgeInsets:UIEdgeInsetsMake(0, 9, 0, 0)];
  back.titleLabel.font = NAV_BUTTON_FONT;
  back.titleLabel.shadowColor = [UIColor blackColor];
  back.titleLabel.shadowOffset = CGSizeMake(0, 1);
  UIImage *backImage = [[UIImage imageNamed:@"navbar_back_button.png"] stretchableImageWithLeftCapWidth:19 topCapHeight:0];
  UIImage *backHighlightedImage = [[UIImage imageNamed:@"navbar_back_highlighted_button.png"] stretchableImageWithLeftCapWidth:19 topCapHeight:0];  
  [back setBackgroundImage:backImage forState:UIControlStateNormal];
  [back setBackgroundImage:backHighlightedImage forState:UIControlStateHighlighted];
  [back addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];  
  UIBarButtonItem *backButton = [[[UIBarButtonItem alloc] initWithCustomView:back] autorelease];
  self.navigationItem.leftBarButtonItem = backButton;
}

- (UIBarButtonItem *)navButtonWithTitle:(NSString *)title withTarget:(id)target action:(SEL)action buttonType:(NavButtonType)buttonType {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.frame = CGRectMake(0, 0, 60, self.navigationController.navigationBar.height - 14);
  [button setTitle:title forState:UIControlStateNormal];
  button.titleLabel.font = NAV_BUTTON_FONT;
  button.titleLabel.shadowColor = [UIColor blackColor];
  button.titleLabel.shadowOffset = CGSizeMake(0, 1);
  
  UIImage *bg = nil;
  UIImage *bgHighlighted = nil;
  switch (buttonType) {
    case NavButtonTypeNormal:
      bg = [[UIImage imageNamed:@"navbar_normal_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      bgHighlighted = [[UIImage imageNamed:@"navbar_normal_highlighted_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      break;
    case NavButtonTypeBlue:
      bg = [[UIImage imageNamed:@"navbar_blue_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      bgHighlighted = [[UIImage imageNamed:@"navbar_blue_highlighted_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      break;
    case NavButtonTypeRed:
      bg = [[UIImage imageNamed:@"navbar_red_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      bgHighlighted = [[UIImage imageNamed:@"navbar_red_highlighted_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      break;
    case NavButtonTypeGreen:
      bg = [[UIImage imageNamed:@"navbar_green_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      bgHighlighted = [[UIImage imageNamed:@"navbar_green_highlighted_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      break;
    case NavButtonTypeSilver:
      bg = [[UIImage imageNamed:@"navbar_focus_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      bgHighlighted = [[UIImage imageNamed:@"navbar_focus_highlighted_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      break;
    default:
      bg = [[UIImage imageNamed:@"navbar_normal_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      bgHighlighted = [[UIImage imageNamed:@"navbar_normal_highlighted_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      break;
  }
  
  [button setBackgroundImage:bg forState:UIControlStateNormal];
  [button setBackgroundImage:bgHighlighted forState:UIControlStateHighlighted];
  [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];  
  UIBarButtonItem *navButton = [[[UIBarButtonItem alloc] initWithCustomView:button] autorelease];
  return navButton;
}

- (UIBarButtonItem *)navButtonWithImage:(UIImage *)image withTarget:(id)target action:(SEL)action buttonType:(NavButtonType)buttonType {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.frame = CGRectMake(0, 0, 60, self.navigationController.navigationBar.height - 14);
  [button setImage:image forState:UIControlStateNormal];
  [button setImage:image forState:UIControlStateHighlighted];
  
  UIImage *bg = nil;
  UIImage *bgHighlighted = nil;
  switch (buttonType) {
    case NavButtonTypeNormal:
      bg = [[UIImage imageNamed:@"navbar_normal_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      bgHighlighted = [[UIImage imageNamed:@"navbar_normal_highlighted_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      break;
    case NavButtonTypeBlue:
      bg = [[UIImage imageNamed:@"navbar_blue_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      bgHighlighted = [[UIImage imageNamed:@"navbar_blue_highlighted_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      break;
    case NavButtonTypeRed:
      bg = [[UIImage imageNamed:@"navbar_red_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      bgHighlighted = [[UIImage imageNamed:@"navbar_red_highlighted_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      break;
    case NavButtonTypeGreen:
      bg = [[UIImage imageNamed:@"navbar_green_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      bgHighlighted = [[UIImage imageNamed:@"navbar_green_highlighted_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      break;
    case NavButtonTypeSilver:
      bg = [[UIImage imageNamed:@"navbar_focus_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      bgHighlighted = [[UIImage imageNamed:@"navbar_focus_highlighted_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      break;
    default:
      bg = [[UIImage imageNamed:@"navbar_normal_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      bgHighlighted = [[UIImage imageNamed:@"navbar_normal_highlighted_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
      break;
  }
  
  [button setBackgroundImage:bg forState:UIControlStateNormal];
  [button setBackgroundImage:bgHighlighted forState:UIControlStateHighlighted];
  [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];  
  UIBarButtonItem *navButton = [[[UIBarButtonItem alloc] initWithCustomView:button] autorelease];
  return navButton;
}

// Subclasses may implement
- (void)setupNullView {
  
}

#pragma mark HeaderTabView
// Subclasses may call
// Subclasses must implement the delegate
- (void)setupHeaderTabViewWithFrame:(CGRect)frame {
  _headerTabView = [[HeaderTabView alloc] initWithFrame:frame andButtonTitles:[NSArray arrayWithObjects:@"Followed", @"Firehose", nil]];
  _headerTabView.delegate = self;
  [self.view addSubview:_headerTabView];
}

// Called when the user logs out and we need to clear all cached data
// Subclasses should override this method
- (void)clearCachedData {
}

// Called when this card controller leaves active view
// Subclasses should override this method
- (void)unloadCardController {
  DLog(@"Called by class: %@", [self class]);
}

// Called when this card controller comes into active view
// Subclasses should override this method
- (void)reloadCardController {
  DLog(@"Called by class: %@", [self class]);
  [self updateState];
}

- (void)resetCardController {
  DLog(@"Called by class: %@", [self class]);
  [self updateState];  
}

// Subclass
- (void)dataSourceDidLoad {
}

#pragma mark CardStateMachine
/**
 If dataIsAvailable and !dataIsLoading and dataSourceIsReady, remove empty/loading screens
 If !dataIsAvailable and !dataIsLoading and dataSourceIsReady, show empty screen
 If dataIsLoading and !dataSourceIsReady, show loading screen
 If !dataIsLoading and !dataSourceIsReady, show empty/error screen
 */
//- (BOOL)dataIsAvailable;
//- (BOOL)dataIsLoading;
//- (BOOL)dataSourceIsReady;
//- (void)updateState;

- (BOOL)dataSourceIsReady {
  return YES;
}

- (BOOL)dataIsAvailable {
  return YES;
}

- (BOOL)dataIsLoading {
  return NO;
}

- (void)updateState {
  if ([self dataIsAvailable]) {
    // We have real data to display
    _nullView.state = PSNullViewStateDisabled;
  } else {
    if ([self dataIsLoading]) {
      // We are loading for the first time
      _nullView.state = PSNullViewStateLoading;
    } else {
      // We have no data to display, show the empty screen
      _nullView.state = PSNullViewStateEmpty;
    }
  }
}

- (void)updateScrollsToTop:(BOOL)isEnabled {
  if (_activeScrollView) {
    _activeScrollView.scrollsToTop = isEnabled;
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
  [super viewDidUnload];
}

- (void)dealloc {
  RELEASE_SAFELY(_headerTabView);
  RELEASE_SAFELY(_nullView);
  RELEASE_SAFELY(_navTitleLabel);
  [super dealloc];
}


@end
