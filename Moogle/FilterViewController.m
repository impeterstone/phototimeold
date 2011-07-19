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
  
  self.navigationItem.leftBarButtonItem = [self navButtonWithImage:[UIImage imageNamed:@"icon_gear.png"] withTarget:self action:@selector(settings) buttonType:NavButtonTypeNormal];
  self.navigationItem.rightBarButtonItem = [self navButtonWithTitle:@"Cancel" withTarget:self action:@selector(dismissModalViewControllerAnimated:) buttonType:NavButtonTypeRed];
  
  _navTitleLabel.text = @"Photo Albums";
  
  // Setup Data Source if implmeneted
  [self setupDataSource];
}

#pragma mark - Actions
- (void)settings {
  
}

#pragma mark - Setup
- (void)setupTableFooter {
  UIView *footerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)] autorelease];
  _tableView.tableFooterView = footerView;
}

- (void)setupDataSource {
  // Create all the rows
  NSMutableArray *rows = [NSMutableArray array];
  NSDictionary *rowData = nil;
  NSFetchRequest *countFetchRequest = nil;
  NSUInteger count = 0;
  NSString *facebookId = [[NSUserDefaults standardUserDefaults] stringForKey:@"facebookId"];
  
  // My Photos
  countFetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:FETCH_ME substitutionVariables:[NSDictionary dictionaryWithObject:facebookId forKey:@"desiredFromId"]];
  count = [[PSCoreDataStack mainThreadContext] countForFetchRequest:countFetchRequest error:nil];
  rowData = [NSDictionary dictionaryWithObjectsAndKeys:@"Your Albums", @"title", @"icon_filter_me.png", @"icon", [NSNumber numberWithInteger:count], @"count", [NSNumber numberWithInteger:AlbumTypeMe], @"albumType", nil];
  [rows addObject:rowData];
  
  // My Friends
  countFetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:FETCH_FRIENDS substitutionVariables:[NSDictionary dictionaryWithObject:facebookId forKey:@"desiredFromId"]];
  count = [[PSCoreDataStack mainThreadContext] countForFetchRequest:countFetchRequest error:nil];
  rowData = [NSDictionary dictionaryWithObjectsAndKeys:@"Your Friends", @"title", @"icon_filter_friends.png", @"icon", [NSNumber numberWithInteger:count], @"count", [NSNumber numberWithInteger:AlbumTypeFriends], @"albumType", nil];
  [rows addObject:rowData];
  
  // Mobile Albums
  countFetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:FETCH_MOBILE substitutionVariables:[NSDictionary dictionary]];
  count = [[PSCoreDataStack mainThreadContext] countForFetchRequest:countFetchRequest error:nil];
  rowData = [NSDictionary dictionaryWithObjectsAndKeys:@"Mobile Uploads", @"title", @"icon_filter_mobile.png", @"icon", [NSNumber numberWithInteger:count], @"count", [NSNumber numberWithInteger:AlbumTypeMobile], @"albumType", nil];
  [rows addObject:rowData];
  
  // Profile Pictures
  countFetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:FETCH_PROFILE substitutionVariables:[NSDictionary dictionary]];
  count = [[PSCoreDataStack mainThreadContext] countForFetchRequest:countFetchRequest error:nil];
  rowData = [NSDictionary dictionaryWithObjectsAndKeys:@"Profile Pictures", @"title", @"icon_filter_profile.png", @"icon", [NSNumber numberWithInteger:count], @"count", [NSNumber numberWithInteger:AlbumTypeProfile], @"albumType", nil];
  [rows addObject:rowData];
  
  // Wall
  countFetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:FETCH_WALL substitutionVariables:[NSDictionary dictionary]];
  count = [[PSCoreDataStack mainThreadContext] countForFetchRequest:countFetchRequest error:nil];
  rowData = [NSDictionary dictionaryWithObjectsAndKeys:@"Wall Photos", @"title", @"icon_filter_wall.png", @"icon", [NSNumber numberWithInteger:count], @"count", [NSNumber numberWithInteger:AlbumTypeWall], @"albumType", nil];
  [rows addObject:rowData];
  
  // Favorites
  countFetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:FETCH_FAVORITES substitutionVariables:[NSDictionary dictionary]];
  count = [[PSCoreDataStack mainThreadContext] countForFetchRequest:countFetchRequest error:nil];
  rowData = [NSDictionary dictionaryWithObjectsAndKeys:@"Favorites", @"title", @"icon_filter_favorites.png", @"icon", [NSNumber numberWithInteger:count], @"count", [NSNumber numberWithInteger:AlbumTypeFavorites], @"albumType", nil];
  [rows addObject:rowData];
  
  // Add rows to data source
  [self.items addObject:rows];
  [self.tableView reloadData];
  [self dataSourceDidLoad];
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
  cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [rowData objectForKey:@"count"]];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  NSDictionary *rowData = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

  AlbumViewController *parent = (AlbumViewController *)[(UINavigationController *)[[self navigationController] parentViewController] topViewController];
  
  parent.albumType = [[rowData objectForKey:@"albumType"] integerValue];
  [parent.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
  [parent reloadCardController];
  
  // Set userDefaults
  [[NSUserDefaults standardUserDefaults] setInteger:parent.albumType forKey:@"lastAlbumType"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [self dismissModalViewControllerAnimated:YES];
}

@end
