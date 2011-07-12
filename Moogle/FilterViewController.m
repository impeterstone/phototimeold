//
//  FilterViewController.m
//  Moogle
//
//  Created by Peter Shih on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FilterViewController.h"
#import "AlbumViewController.h"

@implementation FilterViewController

#pragma mark - Init
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
  
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  self.navigationItem.rightBarButtonItem = [self navButtonWithTitle:@"Cancel" withTarget:self action:@selector(dismissModalViewControllerAnimated:)];
  
  _navTitleLabel.text = @"Photos";
  
}

- (void)setupDataSource {
  // Create all the rows
  NSMutableArray *rows = [NSMutableArray array];
  NSDictionary *rowData = nil;
  
  // My Photos
  rowData = [NSDictionary dictionaryWithObjectsAndKeys:@"My Photos", @"title", @"icon_my_photos.png", @"icon", @"23", @"count", [NSNumber numberWithInteger:AlbumTypeMe], @"albumType", nil];
  [rows addObject:rowData];
  
  // My Friends
  rowData = [NSDictionary dictionaryWithObjectsAndKeys:@"My Friends", @"title", @"icon_my_friends.png", @"icon", @"1337", @"count", [NSNumber numberWithInteger:AlbumTypeFriends], @"albumType", nil];
  [rows addObject:rowData];
  
  
  // Add rows to data source
  [self.items addObject:rows];
  [self.tableView reloadData];
}

#pragma mark - Table
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = nil;
  NSString *reuseIdentifier = @"filterCell";
  
  cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier] autorelease];
  }
  
  NSDictionary *rowData = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  
  cell.textLabel.text = [rowData objectForKey:@"title"];
  cell.detailTextLabel.text = [rowData objectForKey:@"count"];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  NSDictionary *rowData = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

  AlbumViewController *parent = (AlbumViewController *)[(UINavigationController *)[[self navigationController] parentViewController] topViewController];
  
  parent.albumType = [[rowData objectForKey:@"albumType"] integerValue];
  
  [self dismissModalViewControllerAnimated:YES];
}

@end
