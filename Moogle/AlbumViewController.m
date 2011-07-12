//
//  AlbumViewController.m
//  Moogle
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AlbumViewController.h"
#import "AlbumDataCenter.h"
#import "PhotoViewController.h"
#import "FilterViewController.h"
#import "AlbumCell.h"
#import "Album.h"

@implementation AlbumViewController

@synthesize albumType = _albumType;

- (id)init {
  self = [super init];
  if (self) {
    _albumType = AlbumTypeMe;
    _fetchLimit = 25;
    _fetchTotal = _fetchLimit;
    _frcDelegate = nil;
//    _sectionNameKeyPathForFetchedResultsController = [@"daysAgo" retain];
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCardController) name:kReloadAlbumController object:nil];
  [self reloadCardController];
  
  [self.navigationController.navigationBar addSubview:_searchField];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [_searchField removeFromSuperview];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kReloadAlbumController object:nil];
}

- (void)loadView {
  [super loadView];
  
  [self resetFetchedResultsController];
  
  // Table
  CGRect tableFrame = self.view.bounds;
  [self setupTableViewWithFrame:tableFrame andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
//  self.tableView.rowHeight = 120.0;
  
  // Custom Search
  _searchField = [[PSTextField alloc] initWithFrame:CGRectMake(5, 6, 60, 30) withInset:CGSizeMake(30, 7)];
  _searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
  _searchField.font = NORMAL_FONT;
  _searchField.delegate = self;
  _searchField.returnKeyType = UIReturnKeySearch;
  _searchField.background = [UIImage stretchableImageNamed:@"searchbar_textfield_background.png" withLeftCapWidth:30 topCapWidth:0];
  _searchField.placeholder = @"Search for photos...";
  
  _searchEmptyView = [[UIView alloc] initWithFrame:self.view.bounds];
//  _searchEmptyView.height -= 44; // nav bar
//  _searchEmptyView.height -= 216; // minus keyboard
  _searchEmptyView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"weave-bg.png"]];
  _searchEmptyView.alpha = 0.0;
  
  UILabel *searchLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 200)] autorelease];
  searchLabel.numberOfLines = 8;
  searchLabel.text = @"Search for keywords, people, or places.\n\nTypeahead table view here";
  searchLabel.textAlignment = UITextAlignmentCenter;
  searchLabel.textColor = [UIColor whiteColor];
  searchLabel.shadowColor = [UIColor blackColor];
  searchLabel.shadowOffset = CGSizeMake(0, 1);
  searchLabel.backgroundColor = [UIColor clearColor];
  
  [_searchEmptyView addSubview:searchLabel];
  [self.view addSubview:_searchEmptyView];
  
//  [self addButtonWithTitle:@"Logout" andSelector:@selector(logout) isLeft:YES];
//  [self addButtonWithImage:[UIImage imageNamed:@"searchbar_textfield_background.png"] withTarget:self action:@selector(search) isLeft:YES];
  
  _filterButton = [[self navButtonWithTitle:@"Filter" withTarget:self action:@selector(filter)] retain];
  _cancelButton = [[self navButtonWithTitle:@"Cancel" withTarget:self action:@selector(cancelSearch)] retain];
  self.navigationItem.rightBarButtonItem = _filterButton;
  
//  _navTitleLabel.text = @"Moogle";
  
  // Pull Refresh
//  [self setupPullRefresh];
  
//  [self setupLoadMoreView];
  
  [self executeFetch:FetchTypeCold];
}

- (void)updateState {
  [super updateState];
  
  // Update Nav Title
  switch (self.albumType) {
    case AlbumTypeMe:
      _navTitleLabel.text = @"My Photos";
      break;
    case AlbumTypeFriends:
      _navTitleLabel.text = @"My Friends";
      break;
    default:
      break;
  }
  
  [self.navigationController.navigationBar bringSubviewToFront:_searchField];
}

- (void)reloadCardController {
  [super reloadCardController];
  _hasMore = YES;
  _fetchTotal = _fetchLimit;
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"]) {
    [self dataSourceDidLoad];
  }
}

- (void)unloadCardController {
  [super unloadCardController];
}

- (void)filter {
  FilterViewController *fvc = [[[FilterViewController alloc] init] autorelease];
  UINavigationController *fnc = [[[UINavigationController alloc] initWithRootViewController:fvc] autorelease];
  [self presentModalViewController:fnc animated:YES];
}

- (void)search {  
}

- (void)cancelSearch {
  [UIView beginAnimations:nil context:NULL];
  _searchField.width = 60;
  [UIView setAnimationDuration:0.4];
  [UIView commitAnimations];
  
  _searchPredicate = nil;
  [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
  [self executeFetchOnMainThread];
  self.navigationItem.rightBarButtonItem = _filterButton;
  [_searchField resignFirstResponder];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  _hasMore = YES;
  _fetchTotal = _fetchLimit;
  self.navigationItem.rightBarButtonItem = _cancelButton;
  
  [UIView beginAnimations:nil context:NULL];
  _searchField.width = 240;
  _searchEmptyView.alpha = 1.0;
  [UIView setAnimationDuration:0.4];
  [UIView commitAnimations];
  
  return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {  
  _hasMore = YES;
  _fetchTotal = _fetchLimit;
  [UIView beginAnimations:nil context:NULL];
  _searchEmptyView.alpha = 0.0;
  [UIView setAnimationDuration:0.4];
  [UIView commitAnimations];
  return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if ([textField.text length] == 0) {
    // Empty search
    [self cancelSearch];
  } else {
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    [self searchWithText:textField.text];
    [textField resignFirstResponder];
  }
  
  return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
//  if (_searchTimer && [_searchTimer isValid]) {
//    INVALIDATE_TIMER(_searchTimer);
//  }
//  NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:textField.text, @"searchText", nil];
//  _searchTimer = [[NSTimer timerWithTimeInterval:0.3 target:self selector:@selector(delayedFilterContentWithTimer:) userInfo:userInfo repeats:NO] retain];
//  [[NSRunLoop currentRunLoop] addTimer:_searchTimer forMode:NSDefaultRunLoopMode];
  
  return YES;
}

- (void)searchWithText:(NSString *)searchText {
  static NSCharacterSet *separatorCharacterSet = nil;
  if (!separatorCharacterSet) {
    separatorCharacterSet = [[[NSCharacterSet alphanumericCharacterSet] invertedSet] retain];
  }

  NSMutableArray *subpredicates = [NSMutableArray arrayWithCapacity:1];
  //  predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", searchText];
  
  NSString *tmp = [[searchText componentsSeparatedByCharactersInSet:separatorCharacterSet] componentsJoinedByString:@" "];
  NSArray *searchTerms = [tmp componentsSeparatedByString:@" "];
  
  for (NSString *searchTerm in searchTerms) {
    if ([searchTerm length] == 0) continue;
    NSString *searchValue = searchTerm;
    // search any
    [subpredicates addObject:[NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR fromName CONTAINS[cd] %@ OR location CONTAINS[cd] %@", searchValue, searchValue, searchValue]];
  }
  
  if (_searchPredicate) {
    RELEASE_SAFELY(_searchPredicate);
  }
  _searchPredicate = [[NSCompoundPredicate andPredicateWithSubpredicates:subpredicates] retain];
  
  [self executeSearchOnMainThread];
//  [self executeFetch:FetchTypeRefresh];
}

#pragma mark - TableView
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  Album *album = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  // Preload all album covers
  NSString *urlPath = album.coverPhoto;
  if (urlPath) {
    [[PSImageCache sharedCache] cacheImageForURLPath:urlPath withDelegate:nil];
  }
  
  return 120.0;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//  return [[[self.fetchedResultsController sections] objectAtIndex:section] name];
//}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//  if ([[self.fetchedResultsController sections] count] == 1) return nil;
//  
//  NSString *sectionName = [[[self.fetchedResultsController sections] objectAtIndex:section] name];
//  
//  UIView *sectionHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 26)] autorelease];
////  sectionHeaderView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-table-header.png"]];
//  sectionHeaderView.backgroundColor = SECTION_HEADER_COLOR;
//  
//  UILabel *sectionHeaderLabel = [[[UILabel alloc] initWithFrame:CGRectMake(5, 0, 310, 24)] autorelease];
//  sectionHeaderLabel.backgroundColor = [UIColor clearColor];
//  sectionHeaderLabel.text = sectionName;
//  sectionHeaderLabel.textColor = [UIColor whiteColor];
//  sectionHeaderLabel.shadowColor = [UIColor blackColor];
//  sectionHeaderLabel.shadowOffset = CGSizeMake(0, 1);
//  sectionHeaderLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0];
//  [sectionHeaderView addSubview:sectionHeaderLabel];
//  
//  return sectionHeaderView;
//}

- (void)tableView:(UITableView *)tableView configureCell:(id)cell atIndexPath:(NSIndexPath *)indexPath {
  Album *album = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  [cell fillCellWithObject:album];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  Album *album = [self.fetchedResultsController objectAtIndexPath:indexPath];
  album.lastViewed = [NSDate date];
  [PSCoreDataStack saveInContext:[album managedObjectContext]];
  
  PhotoViewController *pvc = [[PhotoViewController alloc] init];
  pvc.album = album;
  
  // If this album is WALL, sort by timestamp instead
  if (self.albumType == AlbumTypeWall) {
    pvc.sortKey = @"timestamp";
  }
  
  [self.navigationController pushViewController:pvc animated:YES];
  [pvc release];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  AlbumCell *cell = nil;
  NSString *reuseIdentifier = [AlbumCell reuseIdentifier];
  
  cell = (AlbumCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if(cell == nil) { 
    cell = [[[AlbumCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
  }
  
  [self tableView:tableView configureCell:cell atIndexPath:indexPath];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
  [(AlbumCell *)cell loadPhoto];
}

#pragma mark -
#pragma mark UISearchDisplayDelegate
- (void)delayedFilterContentWithTimer:(NSTimer *)timer {
  static NSCharacterSet *separatorCharacterSet = nil;
  if (!separatorCharacterSet) {
    separatorCharacterSet = [[[NSCharacterSet alphanumericCharacterSet] invertedSet] retain];
  }
  
  NSDictionary *userInfo = [timer userInfo];
  NSString *searchText = [userInfo objectForKey:@"searchText"];
  NSString *scope = [userInfo objectForKey:@"scope"];

  NSMutableArray *subpredicates = [NSMutableArray arrayWithCapacity:1];
  //  predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", searchText];
  
  NSString *tmp = [[searchText componentsSeparatedByCharactersInSet:separatorCharacterSet] componentsJoinedByString:@" "];
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
  
  [self executeFetch:FetchTypeRefresh];
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
      fetchTemplate = FETCH_ME;
      substitutionVariables = [NSDictionary dictionaryWithObject:facebookId forKey:@"desiredFromId"];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    case AlbumTypeFriends:
      fetchTemplate = FETCH_FRIENDS;
      substitutionVariables = [NSDictionary dictionaryWithObject:facebookId forKey:@"desiredFromId"];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    case AlbumTypeMobile:
      fetchTemplate = FETCH_MOBILE;
      substitutionVariables = [NSDictionary dictionary];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    case AlbumTypeWall:
      fetchTemplate = FETCH_WALL;
      substitutionVariables = [NSDictionary dictionary];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    case AlbumTypeProfile:
      fetchTemplate = FETCH_PROFILE;
      substitutionVariables = [NSDictionary dictionary];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    case AlbumTypeFavorites:
      fetchTemplate = FETCH_FAVORITES;
      substitutionVariables = [NSDictionary dictionary];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    default:
      break;
  }
  
  NSFetchRequest *fetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:fetchTemplate substitutionVariables:substitutionVariables];
  [fetchRequest setSortDescriptors:sortDescriptors];
  [fetchRequest setFetchBatchSize:10];
  [fetchRequest setFetchLimit:_fetchTotal];
  return fetchRequest;
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
  RELEASE_SAFELY(_searchField);
  RELEASE_SAFELY(_filterButton);
  RELEASE_SAFELY(_cancelButton);
  RELEASE_SAFELY(_searchEmptyView);
  [super dealloc];
}

@end
