//
//  SearchTermController.m
//  PhotoTime
//
//  Created by Peter Shih on 7/12/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import "SearchTermController.h"
#import "PSSearchCenter.h"

@implementation SearchTermController

@synthesize delegate = _delegate;

- (id)init {
  self = [super init];
  if (self) {
//    _loadingLabel = [@"Searching..." retain];
//    _emptyLabel = [@"Search for Photos by\nKeywords, Friends, or Places\nTap Search for Results" retain];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
  RELEASE_SAFELY(_dismissGesture);
  [super dealloc];
}

#pragma mark - View Config
- (UIView *)backgroundView {
  NSString *bgName = nil;
  if (isDeviceIPad()) {
    bgName = @"bg_grain_pad.jpg";
  } else {
    bgName = @"bg_grain.jpg";
  }
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:bgName]] autorelease];
  bg.frame = self.view.bounds;
  bg.autoresizingMask = ~UIViewAutoresizingNone;
  return bg;
}

#pragma mark - View
- (void)loadView {
  [super loadView];
  
  // Nullview
  [_nullView setLoadingTitle:nil loadingSubtitle:nil emptyTitle:@"Search Photos" emptySubtitle:@"Try searching for people, places, or things" image:[UIImage imageNamed:@"nullview_search.png"]];
  
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
  
  self.tableView.scrollsToTop = NO;
  
  _dismissGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelSearch)];
  [_nullView addGestureRecognizer:_dismissGesture];
  _dismissGesture.enabled = YES;
  
  [self updateState];
}

#pragma mark - Setup
- (void)setupTableFooter {
  UIView *footerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)] autorelease];
  _tableView.tableFooterView = footerView;
}

- (void)cancelSearch {
  if (self.delegate && [self.delegate respondsToSelector:@selector(cancelSearch)]) {
    [self.delegate searchCancelled];
  }
}

#pragma mark - Search
- (void)searchWithTerm:(NSString *)term {
  [self.items removeAllObjects];
  
  NSArray *filteredArray = [[PSSearchCenter defaultCenter] searchResultsForTerm:term inContainer:@"albums"];

  if ([filteredArray count] > 0) {
    _dismissGesture.enabled = NO;
    [self.items addObject:filteredArray];
  } else {
    _dismissGesture.enabled = YES;
  }
  [self.tableView reloadData];
  [self dataSourceDidLoad];
  [self updateState];
}

#pragma mark - Table
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  
  UIView *sectionHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 26)] autorelease];
//  sectionHeaderView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_table_header.png"]];
  sectionHeaderView.backgroundColor = SECTION_HEADER_COLOR;
  
  UILabel *sectionHeaderLabel = [[[UILabel alloc] initWithFrame:CGRectMake(5, 0, 310, 24)] autorelease];
  sectionHeaderLabel.backgroundColor = [UIColor clearColor];
  sectionHeaderLabel.text = @"Previously Searched...";
  sectionHeaderLabel.textColor = [UIColor whiteColor];
  sectionHeaderLabel.shadowColor = [UIColor blackColor];
  sectionHeaderLabel.shadowOffset = CGSizeMake(0, 1);
  sectionHeaderLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0];
  [sectionHeaderView addSubview:sectionHeaderLabel];
  
  return sectionHeaderView;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (tableView.style == UITableViewStylePlain) {
    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    backgroundView.backgroundColor = LIGHT_GRAY;
    cell.backgroundView = backgroundView;
    
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    selectedBackgroundView.backgroundColor = CELL_SELECTED_COLOR;
    cell.selectedBackgroundView = selectedBackgroundView;
    
    [backgroundView release];
    [selectedBackgroundView release];
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = nil;
  NSString *reuseIdentifier = @"searchTermCell";
  
  cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
  }
  
  NSString *term = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  
  cell.textLabel.text = term;
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  NSString *term = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  
  // Search term selected
  if (self.delegate && [self.delegate respondsToSelector:@selector(searchTermSelected:)]) {
    [self.delegate searchTermSelected:term];
  }
}

#pragma mark UIKeyboard
- (void)keyboardWillShow:(NSNotification *)aNotification {
  [self moveTextViewForKeyboard:aNotification up:YES];
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
  [self moveTextViewForKeyboard:aNotification up:NO]; 
}

- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up {
  NSDictionary* userInfo = [aNotification userInfo];
  
  // Get animation info from userInfo
  NSTimeInterval animationDuration;
  UIViewAnimationCurve animationCurve;
  
  CGRect keyboardEndFrame;
  
  [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
  [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
  
  
  CGRect keyboardFrame = CGRectZero;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 30200
  // code for iOS below 3.2
  [[userInfo objectForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardEndFrame];
  keyboardFrame = keyboardEndFrame;
#else
  // code for iOS 3.2 ++
  [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
  keyboardFrame = [UIScreen convertRect:keyboardEndFrame toView:self.view];
#endif  
  
  // Animate up or down
  NSString *dir = up ? @"up" : @"down";
  [UIView beginAnimations:dir context:nil];
  [UIView setAnimationDuration:animationDuration];
  [UIView setAnimationCurve:animationCurve];
  
  if (up) {
    self.view.height = self.view.height - keyboardFrame.size.height;
  } else {
    self.view.height = self.view.height + keyboardFrame.size.height;
  }
  
  [UIView commitAnimations];
}

@end
