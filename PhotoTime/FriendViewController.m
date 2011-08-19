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

- (id)init {
  self = [super init];
  if (self) {
  }
  return self;
}

- (void)dealloc {
  [super dealloc];
}

#pragma mark - View
- (void)loadView {
  [super loadView];
  
  UINavigationBar *navBar = [[[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44)] autorelease];
  navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  UINavigationItem *navItem = [[[UINavigationItem alloc] init] autorelease];
  [navBar setItems:[NSArray arrayWithObject:navItem]];
  [self.view addSubview:navBar];
  
  navItem.rightBarButtonItem = [UIBarButtonItem navButtonWithTitle:@"Save" withTarget:self action:@selector(save) buttonType:NavButtonTypeBlue];
  navItem.leftBarButtonItem = [UIBarButtonItem navButtonWithTitle:@"Cancel" withTarget:self action:@selector(cancel) buttonType:NavButtonTypeNormal];
  navItem.titleView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"phototime_logo.png"]] autorelease];
  
  [self setupTableViewWithFrame:CGRectMake(0, navBar.height, self.view.width, self.view.height - navBar.height) andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
  
  self.tableView.rowHeight = 44;
  
  [self setupSearchDisplayControllerWithScopeButtonTitles:nil andPlaceholder:@"Search Friends..."];
  
  [self loadDataSource];
}

- (void)save {
  
}

- (void)cancel {
  [self dismissModalViewControllerAnimated:YES];
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
  
  [self.items addObject:friends];
  
  [self dataSourceDidLoad];
}

- (void)dataSourceDidLoad {
  [self.tableView reloadData];
  [super dataSourceDidLoad];
}

#pragma mark - TableView
- (void)tableView:(UITableView *)tableView configureCell:(id)cell atIndexPath:(NSIndexPath *)indexPath {
  NSDictionary *friend = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  [cell fillCellWithObject:friend];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  FriendCell *cell = nil;
  NSString *reuseIdentifier = [FriendCell reuseIdentifier];
  
  cell = (FriendCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if(cell == nil) { 
    cell = [[[FriendCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
  }
  
  [self tableView:tableView configureCell:cell atIndexPath:indexPath];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  
  // Toggle 'selected' state
	BOOL isSelected = ![self cellIsSelected:indexPath];
 
  // Store cell 'selected' state keyed on indexPath
	NSNumber *selectedIndex = [NSNumber numberWithBool:isSelected];
	[_selectedIndexes setObject:selectedIndex forKey:indexPath];
  
  if (isSelected) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  UIView *backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
  backgroundView.backgroundColor = [UIColor whiteColor];
  cell.backgroundView = backgroundView;
  
  UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
  selectedBackgroundView.backgroundColor = CELL_SELECTED_COLOR;
  cell.selectedBackgroundView = selectedBackgroundView;
  
  [backgroundView release];
  [selectedBackgroundView release];
}


@end
