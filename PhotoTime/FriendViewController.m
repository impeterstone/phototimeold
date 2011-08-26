//
//  FriendViewController.m
//  PhotoTime
//
//  Created by Peter Shih on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FriendViewController.h"
#import "FriendCell.h"

@implementation FriendViewController

@synthesize delegate = _delegate;

- (id)init {
  self = [super init];
  if (self) {
    _selectedFriends = [[NSMutableSet alloc] init];
  }
  return self;
}

- (void)dealloc {
  RELEASE_SAFELY(_selectedFriends);
  [super dealloc];
}

#pragma mark - View Config
- (UIView *)backgroundView {
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_weave.png"]] autorelease];
  bg.frame = self.view.bounds;
  bg.autoresizingMask = ~UIViewAutoresizingNone;
  return bg;
}

#pragma mark - View
- (void)loadView {
  [super loadView];
  
  UINavigationBar *navBar = [[[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44)] autorelease];
  navBar.tintColor = RGBACOLOR(80, 80, 80, 1.0);
  navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  UINavigationItem *navItem = [[[UINavigationItem alloc] init] autorelease];
  [navBar setItems:[NSArray arrayWithObject:navItem]];
  [self.view addSubview:navBar];
  
  navItem.rightBarButtonItem = [UIBarButtonItem barButtonWithTitle:@"Save" withTarget:self action:@selector(save) width:60 height:30 buttonType:BarButtonTypeBlue];
  navItem.leftBarButtonItem = [UIBarButtonItem barButtonWithTitle:@"Cancel" withTarget:self action:@selector(cancel) width:60 height:30 buttonType:BarButtonTypeNormal];
  navItem.titleView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"phototime_logo.png"]] autorelease];
  
  [self setupTableViewWithFrame:CGRectMake(0, navBar.height, self.view.width, self.view.height - navBar.height) andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
  
  self.tableView.rowHeight = 44;
  
  // THERE IS A BUG
  // When multi-selecting on a search results table view, it doesnt' match to the real table
  //  [self setupSearchDisplayControllerWithScopeButtonTitles:nil andPlaceholder:@"Search Friends..."];
  
  [self loadDataSource];
  
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isFirstNewStream"]) {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isFirstNewStream"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [[[[UIAlertView alloc] initWithTitle:@"Create a Stream" message:@"Choose the friend(s) that you would like to add to your new stream." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] autorelease] show];
    }];
  }
}

#pragma mark - Actions
- (void)save {
  if ([_selectedFriends count] == 0) return;
  
  TSAlertView *alertView = [[[TSAlertView alloc] init] autorelease];
  alertView.delegate = self;
  alertView.style = TSAlertViewStyleInput;
  alertView.buttonLayout = TSAlertViewButtonLayoutNormal;
  alertView.title = @"Name Your Stream";
  alertView.message = @"e.g. My Family";
  [alertView addButtonWithTitle:@"Okay"];
  [alertView show];
  
}

- (void)cancel {
  [self dismissModalViewControllerAnimated:YES];
}

- (void)alertView:(TSAlertView *)alertView didDismissWithButtonIndex: (NSInteger) buttonIndex {
  if (buttonIndex != alertView.cancelButtonIndex) {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectFriends:withTitle:)]) {
      [self.delegate didSelectFriends:[_selectedFriends allObjects] withTitle:alertView.inputTextField.text];
    }
    [self dismissModalViewControllerAnimated:YES];
  }
}

#pragma mark - State Machine
- (BOOL)dataIsAvailable {
  return YES;
}
- (BOOL)dataIsLoading {
  return NO;
}

- (void)loadDataSource {
  [super loadDataSource];
  
  // Load data
  NSDictionary *facebookFriends = [[NSUserDefaults standardUserDefaults] objectForKey:@"facebookFriends"];
  NSArray *friends = [[facebookFriends allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
  
  // Sort these friends
  NSMutableDictionary *groups = [NSMutableDictionary dictionary];
  for (NSDictionary *friend in friends) {
    NSString *firstInitial = [[[friend objectForKey:@"name"] uppercaseString] substringToIndex:1];
    
    NSMutableArray *section = [groups objectForKey:firstInitial];
    if (!section) {
      section = [NSMutableArray arrayWithCapacity:1];
      [groups setObject:section forKey:firstInitial];
    }
    
    [section addObject:friend];
  }
  
  [_sectionTitles addObjectsFromArray:[[groups allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
  for (NSString *firstInitial in _sectionTitles) {
    [self.items addObject:[groups objectForKey:firstInitial]];
  }
  
  //  [self.items addObject:friends];
  
  [self dataSourceDidLoad];
}

- (void)dataSourceDidLoad {
  [self.tableView reloadData];
  [super dataSourceDidLoad];
}

#pragma mark - TableView
- (void)tableView:(UITableView *)tableView configureCell:(id)cell atIndexPath:(NSIndexPath *)indexPath {
  NSArray *items = nil;
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    items = _searchItems;
  } else {
    items = _items;
  }
  
  NSDictionary *friend = [[items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  [cell fillCellWithObject:friend];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  FriendCell *cell = nil;
  NSString *reuseIdentifier = [FriendCell reuseIdentifier];
  
  cell = (FriendCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if(cell == nil) { 
    cell = [[[FriendCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier] autorelease];
  }
  
  [self tableView:tableView configureCell:cell atIndexPath:indexPath];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  NSDictionary *friend = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  
  // Toggle 'selected' state
	BOOL isSelected = ![self cellIsSelected:indexPath];
  
  // Store cell 'selected' state keyed on indexPath
	NSNumber *selectedIndex = [NSNumber numberWithBool:isSelected];
	[_selectedIndexes setObject:selectedIndex forKey:indexPath];
  
  if (isSelected) {
    [_selectedFriends addObject:friend];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    [_selectedFriends removeObject:friend];
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([self cellIsSelected:indexPath]) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  
  UIView *backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
  backgroundView.backgroundColor = [UIColor whiteColor];
  cell.backgroundView = backgroundView;
  
  UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
  selectedBackgroundView.backgroundColor = CELL_SELECTED_COLOR;
  cell.selectedBackgroundView = selectedBackgroundView;
  
  [backgroundView release];
  [selectedBackgroundView release];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  return [_sectionTitles objectAtIndex:section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
  return _sectionTitles;
}

#pragma mark - Search
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
  NSArray *filteredItems = [[_items objectAtIndex:0] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", searchText]];
  [_searchItems removeAllObjects];
  [_searchItems addObject:filteredItems];
}

@end
