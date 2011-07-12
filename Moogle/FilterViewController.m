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
  
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
  
  self.navigationItem.rightBarButtonItem = [self navButtonWithTitle:@"Cancel" withTarget:self action:@selector(dismissModalViewControllerAnimated:)];
  
  _navTitleLabel.text = @"Photos";
  
}

- (void)setupTableFooter {
  // subclass should implement
  UIImageView *footerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg-table-footer.png"]];
  _tableView.tableFooterView = footerImage;
  [footerImage release];
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
  [parent.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
  
  [self dismissModalViewControllerAnimated:YES];
}

@end
