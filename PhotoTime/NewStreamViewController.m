//
//  NewStreamViewController.m
//  PhotoTime
//
//  Created by Peter Shih on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NewStreamViewController.h"
#import "FriendCell.h"

@implementation NewStreamViewController

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
  
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
  
  self.tableView.rowHeight = 60;
  
  [self loadDataSource];
}

#pragma mark - State Machine
- (void)loadDataSource {
  [super loadDataSource];
  
  // Load data
  NSDictionary *facebookFriends = [[NSUserDefaults standardUserDefaults] objectForKey:@"facebookFriends"];
  NSArray *friends = [[facebookFriends allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
  
  [self dataSourceDidLoad];
}

- (void)dataSourceDidLoad {
  [self.tableView reloadData];
  [super dataSourceDidLoad];
}

#pragma mark - TableView
- (void)tableView:(UITableView *)tableView configureCell:(id)cell atIndexPath:(NSIndexPath *)indexPath {
//  Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
//  
//  [cell fillCellWithObject:photo];
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


@end
