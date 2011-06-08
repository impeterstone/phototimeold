//
//  AlbumViewController.m
//  PhotoFeed
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AlbumViewController.h"
#import "AlbumDataCenter.h"
#import "PhotoViewController.h"
#import "AlbumCell.h"
#import "Album.h"
#import "CameraViewController.h"

@implementation AlbumViewController

@synthesize albumType = _albumType;

- (id)init {
  self = [super init];
  if (self) {
    _albumType = AlbumTypeMe;
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
//  [self.navigationController setNavigationBarHidden:YES animated:YES];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCardController) name:kReloadAlbumController object:nil];
  [self reloadCardController];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kReloadAlbumController object:nil];
}

- (void)loadView {
  [super loadView];
  
  [self resetFetchedResultsController];
  
  // Table
  CGRect tableFrame = CGRectMake(0, 0, CARD_WIDTH, CARD_HEIGHT);
  [self setupTableViewWithFrame:tableFrame andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  // Album Type
  NSArray *scopeArray = nil;
  NSString *placeholder = nil;
  NSString *navTitle = nil;
  switch (self.albumType) {
    case AlbumTypeMe:
      navTitle = @"My Albums";
      placeholder = @"i.e. Thanksgiving 2011";
      scopeArray = nil;
      _sectionNameKeyPathForFetchedResultsController = [@"daysAgo" retain];
      break;
    case AlbumTypeFriends:
      navTitle = @"Friends Albums";
      placeholder = @"i.e. Mark, Wedding";
      scopeArray = nil;
      _sectionNameKeyPathForFetchedResultsController = [@"daysAgo" retain];
      break;
    case AlbumTypeWall:
      navTitle = @"Wall Photos";
      placeholder = @"Search by Author Name";
      scopeArray = [NSArray arrayWithObjects:@"Author", nil];
      _sectionNameKeyPathForFetchedResultsController = [@"daysAgo" retain];
      break;
    case AlbumTypeMobile:
      navTitle = @"Mobile Uploads";
      placeholder = @"Search by Author Name";
      scopeArray = [NSArray arrayWithObjects:@"Author", nil];
      _sectionNameKeyPathForFetchedResultsController = [@"daysAgo" retain];
      break;
    case AlbumTypeProfile:
      navTitle = @"Profile Pictures";
      placeholder = @"Search by Author Name";
      scopeArray = [NSArray arrayWithObjects:@"Author", nil];
      _sectionNameKeyPathForFetchedResultsController = [@"daysAgo" retain];
      break;
    case AlbumTypeFavorites:
      navTitle = @"Favorites";
      placeholder = @"i.e. Las Vegas";
      scopeArray = nil;
      _sectionNameKeyPathForFetchedResultsController = [@"daysAgo" retain];
      break;
    case AlbumTypeHistory:
      navTitle = @"Recently Viewed";
      placeholder = @"i.e. Techcrunch Disrupt NYC";
      scopeArray = nil;
      _sectionNameKeyPathForFetchedResultsController = nil;
      break;
    case AlbumTypeTimeline:
      navTitle = @"Timeline";
      placeholder = @"Album, Friend, Location...";
      scopeArray = nil;
      _sectionNameKeyPathForFetchedResultsController = [@"daysAgo" retain];
      break;
    default:
      break;
  }
  
  // Search Scope
  if (placeholder) {
    [self setupSearchDisplayControllerWithScopeButtonTitles:scopeArray andPlaceholder:placeholder];
  }
  
  // Title and Buttons
  [self addButtonWithTitle:@"Logout" andSelector:@selector(logout) isLeft:YES];
//  [self addButtonWithTitle:@"Search" andSelector:@selector(search) isLeft:NO];
//  [self addButtonWithImage:[UIImage imageNamed:@"searchbar_textfield_background.png"] andSelector:@selector(search) isLeft:NO];
  _navTitleLabel.text = navTitle;
  
  
  // Pull Refresh
//  [self setupPullRefresh];
  [self setupLoadMoreView];
}

- (void)reloadCardController {
  [super reloadCardController];
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"]) {
    [self dataSourceDidLoad];
  }
}

- (void)unloadCardController {
  [super unloadCardController];
}

- (void)search {
  //  CameraViewController *cvc = [[CameraViewController alloc] init];
  //  UINavigationController *cnc = [[UINavigationController alloc] initWithRootViewController:cvc];
  //  [self presentModalViewController:cnc animated:NO];
  //  [cvc autorelease];
  //  [cnc autorelease];
}

#pragma mark -
#pragma mark TableView
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  Album *album = [self.fetchedResultsController objectAtIndexPath:indexPath];
  return [AlbumCell rowHeightForObject:album forInterfaceOrientation:[self interfaceOrientation]];
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//  return [[[self.fetchedResultsController sections] objectAtIndex:section] name];
//}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  if ([[self.fetchedResultsController sections] count] == 1) return nil;
  
  NSString *sectionName = [[[self.fetchedResultsController sections] objectAtIndex:section] name];
  
  UIView *sectionHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 26)] autorelease];
  sectionHeaderView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"table_plain_header_gray.png"]];
  
  UILabel *sectionHeaderLabel = [[[UILabel alloc] initWithFrame:CGRectMake(5, 0, 310, 26)] autorelease];
  sectionHeaderLabel.backgroundColor = [UIColor clearColor];
  sectionHeaderLabel.text = sectionName;
  sectionHeaderLabel.textColor = [UIColor whiteColor];
  sectionHeaderLabel.shadowColor = [UIColor blackColor];
  sectionHeaderLabel.shadowOffset = CGSizeMake(0, 1);
  sectionHeaderLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0];
  [sectionHeaderView addSubview:sectionHeaderLabel];
  return sectionHeaderView;
}

- (void)tableView:(UITableView *)tableView configureCell:(id)cell atIndexPath:(NSIndexPath *)indexPath {
  Album *album = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  [cell fillCellWithObject:album];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  Album *album = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  PhotoViewController *svc = [[PhotoViewController alloc] init];
  svc.album = album;
  if (self.albumType == AlbumTypeWall) {
    svc.sectionNameKeyPathForFetchedResultsController = @"timestamp";
  }
  [self.navigationController pushViewController:svc animated:YES];
  [svc release];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  AlbumCell *cell = nil;
  NSString *reuseIdentifier = [AlbumCell reuseIdentifier];
  
  cell = (AlbumCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if(cell == nil) { 
    cell = [[[AlbumCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
  }
  
  [self tableView:tableView configureCell:cell atIndexPath:indexPath];
  [cell loadPhoto];
  
  return cell;
}

#pragma mark -
#pragma mark UISearchDisplayDelegate
- (void)delayedFilterContentWithTimer:(NSTimer *)timer {
  NSDictionary *userInfo = [timer userInfo];
  NSString *searchText = [userInfo objectForKey:@"searchText"];
  NSString *scope = [userInfo objectForKey:@"scope"];
  NSMutableArray *subpredicates = [NSMutableArray arrayWithCapacity:1];
  //  predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", searchText];
  
  NSCharacterSet *acceptedCharacterSet = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
  NSString *tmp = [[searchText componentsSeparatedByCharactersInSet:acceptedCharacterSet] componentsJoinedByString:@" "];
  NSArray *searchTerms = [tmp componentsSeparatedByString:@" "];
  
  for (NSString *searchTerm in searchTerms) {
    if ([searchTerm length] == 0) continue;
    NSString *searchValue = searchTerm;
    if ([scope isEqualToString:@"Author"]) {
      // search friend's full name
      [subpredicates addObject:[NSPredicate predicateWithFormat:@"fromName CONTAINS[cd] %@", searchValue]];
    } else if ([scope isEqualToString:@"Album"]) {
      // search album name
      [subpredicates addObject:[NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", searchValue]];
    } else if ([scope isEqualToString:@"Location"]) {
      [subpredicates addObject:[NSPredicate predicateWithFormat:@"location CONTAINS[cd] %@", searchValue]];
    } else {
      // search any
      [subpredicates addObject:[NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR fromName CONTAINS[cd] %@ OR location CONTAINS[cd] %@", searchValue, searchValue, searchValue]];
    }
  }
  
  if (_searchPredicate) {
    RELEASE_SAFELY(_searchPredicate);
  }
  _searchPredicate = [[NSCompoundPredicate andPredicateWithSubpredicates:subpredicates] retain];
  
  [self executeFetch];
}

#pragma mark -
#pragma mark FetchRequest
- (NSFetchRequest *)getFetchRequest {
  NSArray *sortDescriptors = nil;
  NSString *fetchTemplate = nil;
  NSDictionary *substitutionVariables = nil;
  NSString *facebookId = [[NSUserDefaults standardUserDefaults] stringForKey:@"facebookId"];
  
  switch (self.albumType) {
    case AlbumTypeMe:
      fetchTemplate = @"getMyAlbums";
      substitutionVariables = [NSDictionary dictionaryWithObject:facebookId forKey:@"desiredFromId"];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    case AlbumTypeFriends:
      fetchTemplate = @"getFriendsAlbums";
      substitutionVariables = [NSDictionary dictionaryWithObject:facebookId forKey:@"desiredFromId"];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    case AlbumTypeWall:
      fetchTemplate = @"getWallAlbums";
      substitutionVariables = [NSDictionary dictionary];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    case AlbumTypeMobile:
      fetchTemplate = @"getMobileAlbums";
      substitutionVariables = [NSDictionary dictionary];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    case AlbumTypeProfile:
      fetchTemplate = @"getProfileAlbums";
      substitutionVariables = [NSDictionary dictionary];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    case AlbumTypeFavorites:
      fetchTemplate = @"getFavorites";
      substitutionVariables = [NSDictionary dictionary];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    case AlbumTypeHistory:
      fetchTemplate = @"getHistory";
      substitutionVariables = [NSDictionary dictionary];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"lastViewed" ascending:NO]];
      break;
    case AlbumTypeTimeline:
      fetchTemplate = @"getTimeline";
      substitutionVariables = [NSDictionary dictionary];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    default:
      break;
  }
  
  return [[AlbumDataCenter defaultCenter] fetchAlbumsWithTemplate:fetchTemplate andSortDescriptors:sortDescriptors andSubstitutionVariables:substitutionVariables andLimit:_limit andOffset:_offset];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutRequested object:nil];
  }
}

- (void)dealloc {
  [super dealloc];
}

@end
