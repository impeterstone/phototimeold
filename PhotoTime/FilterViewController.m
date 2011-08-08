//
//  FilterViewController.m
//  PhotoTime
//
//  Created by Peter Shih on 7/10/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import "FilterViewController.h"
#import "AlbumViewController.h"
#import "PSAlertCenter.h"

@implementation FilterViewController

#pragma mark - Init
- (id)init {
  self = [super init];
  if (self) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAlbumCounts:) name:kAlbumDownloadComplete object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kAlbumDownloadComplete object:nil];
  [super dealloc];
}

#pragma mark - Notifications
- (void)updateAlbumCounts:(NSNotification *)notification {
  [self performSelectorOnMainThread:@selector(updateAlbumCountsOnMainThread:) withObject:[notification userInfo] waitUntilDone:NO];
}

- (void)updateAlbumCountsOnMainThread:(NSDictionary *)userInfo {
  [self reloadDataSource];
}

#pragma mark - View
- (void)loadView {
  [super loadView];
  
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
  
//  self.navigationItem.leftBarButtonItem = [self navButtonWithImage:[UIImage imageNamed:@"icon_gear.png"] withTarget:self action:@selector(logout) buttonType:NavButtonTypeNormal];
  self.navigationItem.leftBarButtonItem = [UIBarButtonItem navButtonWithTitle:@"Logout" withTarget:self action:@selector(logout) buttonType:NavButtonTypeNormal];
  
  self.navigationItem.rightBarButtonItem = [UIBarButtonItem navButtonWithTitle:@"Cancel" withTarget:self action:@selector(dismissModalViewControllerAnimated:) buttonType:NavButtonTypeRed];
  
  _navTitleLabel.text = @"Photo Albums";
  
  // Setup Data Source if implmeneted
  [self setupDataSource];
}

#pragma mark - Actions
- (void)settings {
  [[PSAlertCenter defaultCenter] postAlertWithTitle:@"Not Implemented" andMessage:@"In the future this will be the settings/logout screen" andDelegate:nil];
}

- (void)logout {
  UIAlertView *logoutAlert = [[UIAlertView alloc] initWithTitle:@"Logout?" message:LOGOUT_ALERT delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
  [logoutAlert show];
  [logoutAlert autorelease];
}

#pragma mark -
#pragma mark AlertView
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex != alertView.cancelButtonIndex) {
    [self dismissModalViewControllerAnimated:YES];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"logoutRequested"];
  }
}

#pragma mark - Setup
- (void)setupTableFooter {
  UIView *footerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)] autorelease];
  _tableView.tableFooterView = footerView;
}

- (void)reloadDataSource {
  [self setupDataSource];
}

- (void)setupDataSource {
  // Create all the rows
  NSMutableArray *rows = [NSMutableArray array];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSDictionary *rowData = nil;
    NSFetchRequest *countFetchRequest = nil;
    NSUInteger count = 0;
    NSString *facebookId = [[NSUserDefaults standardUserDefaults] stringForKey:@"facebookId"];
    NSManagedObjectContext *context = [PSCoreDataStack newManagedObjectContext];
    
    // My Photos
    countFetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:FETCH_ME substitutionVariables:[NSDictionary dictionaryWithObject:facebookId forKey:@"desiredFromId"]];
    count = [context countForFetchRequest:countFetchRequest error:nil];
    rowData = [NSDictionary dictionaryWithObjectsAndKeys:@"Your Albums", @"title", @"icon_filter_me.png", @"icon", [NSNumber numberWithInteger:count], @"count", [NSNumber numberWithInteger:AlbumTypeMe], @"albumType", nil];
    [rows addObject:rowData];
    
    // My Friends
    countFetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:FETCH_FRIENDS substitutionVariables:[NSDictionary dictionaryWithObject:facebookId forKey:@"desiredFromId"]];
    count = [context countForFetchRequest:countFetchRequest error:nil];
    rowData = [NSDictionary dictionaryWithObjectsAndKeys:@"Your Friends", @"title", @"icon_filter_friends.png", @"icon", [NSNumber numberWithInteger:count], @"count", [NSNumber numberWithInteger:AlbumTypeFriends], @"albumType", nil];
    [rows addObject:rowData];
    
    // Mobile Albums
    countFetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:FETCH_MOBILE substitutionVariables:[NSDictionary dictionary]];
    count = [context countForFetchRequest:countFetchRequest error:nil];
    rowData = [NSDictionary dictionaryWithObjectsAndKeys:@"Mobile Uploads", @"title", @"icon_filter_mobile.png", @"icon", [NSNumber numberWithInteger:count], @"count", [NSNumber numberWithInteger:AlbumTypeMobile], @"albumType", nil];
    [rows addObject:rowData];
    
    // Profile Pictures
    countFetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:FETCH_PROFILE substitutionVariables:[NSDictionary dictionary]];
    count = [context countForFetchRequest:countFetchRequest error:nil];
    rowData = [NSDictionary dictionaryWithObjectsAndKeys:@"Profile Pictures", @"title", @"icon_filter_profile.png", @"icon", [NSNumber numberWithInteger:count], @"count", [NSNumber numberWithInteger:AlbumTypeProfile], @"albumType", nil];
    [rows addObject:rowData];
    
    // Wall
    countFetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:FETCH_WALL substitutionVariables:[NSDictionary dictionary]];
    count = [context countForFetchRequest:countFetchRequest error:nil];
    rowData = [NSDictionary dictionaryWithObjectsAndKeys:@"Wall Photos", @"title", @"icon_filter_wall.png", @"icon", [NSNumber numberWithInteger:count], @"count", [NSNumber numberWithInteger:AlbumTypeWall], @"albumType", nil];
    [rows addObject:rowData];
    
    // Favorites
    countFetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:FETCH_FAVORITES substitutionVariables:[NSDictionary dictionary]];
    count = [context countForFetchRequest:countFetchRequest error:nil];
    rowData = [NSDictionary dictionaryWithObjectsAndKeys:@"Favorites", @"title", @"icon_filter_favorites.png", @"icon", [NSNumber numberWithInteger:count], @"count", [NSNumber numberWithInteger:AlbumTypeFavorites], @"albumType", nil];
    [rows addObject:rowData];
    
    // Release context
    [context release];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      // Add rows to data source
      [self.items removeAllObjects];
      [self.items addObject:rows];
      [self.tableView reloadData];
      [self dataSourceDidLoad];
      [self updateState];
    });
  });
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
