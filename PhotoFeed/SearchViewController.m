//
//  SearchViewController.m
//  PhotoFeed
//
//  Created by Peter Shih on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SearchViewController.h"
#import "AlbumDataCenter.h"
#import "Album.h"
#import "AlbumCell.h"
#import "PhotoViewController.h"

@implementation SearchViewController

- (id)init {
  self = [super init];
  if (self) {
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
}

- (void)loadView {
  [super loadView];
  
  self.navigationController.navigationBarHidden = YES;
  
  [self resetFetchedResultsController];
  
  // Table
  CGRect tableFrame = CGRectMake(0, 0, CARD_WIDTH, CARD_HEIGHT);
  [self setupTableViewWithFrame:tableFrame andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  [self setupHeaderView];
  
  [self setupSearch];

  [self setupLoadMoreView];
}

- (void)setupSearch {
  _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
  _searchBar.delegate = self;
  //  _searchBar.tintColor = [UIColor darkGrayColor];
  _searchBar.placeholder = @"Album, Friend, Location...";
  _searchBar.barStyle = UIBarStyleBlackOpaque;
  
  UISearchDisplayController *searchController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
  [searchController setDelegate:self];
  [searchController setSearchResultsDelegate:self];
  [searchController setSearchResultsDataSource:self];
  
  id searchBarTextField = nil;
  id segmentedControl = nil;
  for (UIView *subview in _searchBar.subviews) {
    if ([subview isMemberOfClass:NSClassFromString(@"UISearchBarBackground")]) {
    } else if ([subview isMemberOfClass:NSClassFromString(@"UISegmentedControl")]) {
      segmentedControl = subview;
    } else if ([subview isMemberOfClass:NSClassFromString(@"UISearchBarTextField")]) {
      searchBarTextField = subview;
    }
  }
  [_searchBar removeSubviews];
  
  // Add new background
  UIImageView *searchBackground = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"search_background.png"]] autorelease];
  searchBackground.top -= 1;
  [_searchBar addSubview:searchBackground];
  [_searchBar addSubview:searchBarTextField];
  
}

- (void)reloadCardController {
  [super reloadCardController];
}

- (void)unloadCardController {
  [super unloadCardController];
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
  if ([album.type isEqualToString:@"wall"]) {
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
  
  NSArray *searchTerms = [[searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -,/\\+_"]];
  
  for (NSString *searchTerm in searchTerms) {
    NSString *searchValue = [NSString stringWithFormat:@"%@", searchTerm];
    // search any
    [subpredicates addObject:[NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR fromName CONTAINS[cd] %@ OR location CONTAINS[cd] %@", searchValue, searchValue, searchValue]];
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
  
  fetchTemplate = @"getTimeline";
  substitutionVariables = [NSDictionary dictionary];
  sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
  
  return nil;
}

- (void)dealloc {
  [super dealloc];
}

@end
