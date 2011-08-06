//
//  CardTableViewController.m
//  PhotoTime
//
//  Created by Peter Shih on 2/14/11.
//  Copyright 2011 Seven Minute Labs, Inc.. All rights reserved.
//

#import "CardTableViewController.h"
#import "PSCell.h"
#import "PSImageCell.h"

@interface CardTableViewController (Private)

@end

@implementation CardTableViewController

@synthesize tableView = _tableView;
@synthesize items = _items;
@synthesize searchItems = _searchItems;

- (id)init {
  self = [super init];
  if (self) {    
    _items = [[NSMutableArray alloc] initWithCapacity:1];
    _sectionTitles = [[NSMutableArray alloc] initWithCapacity:1];
    _loadingMore = NO;
    _hasMore = YES;
  }
  return self;
}

- (void)loadView {
  [super loadView];
  [self updateState];
}

// SUBCLASS CAN OPTIONALLY IMPLEMENT IF THEY WANT A SEARCH BAR
- (void)setupSearchDisplayControllerWithScopeButtonTitles:(NSArray *)scopeButtonTitles {
  [self setupSearchDisplayControllerWithScopeButtonTitles:scopeButtonTitles andPlaceholder:nil];
}

- (void)setupSearchDisplayControllerWithScopeButtonTitles:(NSArray *)scopeButtonTitles andPlaceholder:(NSString *)placeholder {
  _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44)];
  _searchBar.delegate = self;
  //  _searchBar.tintColor = [UIColor darkGrayColor];
  _searchBar.placeholder = placeholder;
  _searchBar.barStyle = UIBarStyleBlackOpaque;
  //  _searchBar.backgroundColor = [UIColor clearColor];
  
  if (scopeButtonTitles) {
    _searchBar.scopeButtonTitles = scopeButtonTitles;
  }
  
  _tableView.tableHeaderView = _searchBar;
  
  UISearchDisplayController *searchController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
  [searchController setDelegate:self];
  [searchController setSearchResultsDelegate:self];
  [searchController setSearchResultsDataSource:self];
  
  // SUBCLASSES MUST IMPLEMENT THE DELEGATE METHODS
  _searchItems = [[NSMutableArray alloc] initWithCapacity:1];
  
  // UITableViewCellSeparatorStyleNone
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
  
  //  UIImageView *scopeBackground = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"search_background.png"]] autorelease];
  //  scopeBackground.top -= 1;
  //  [segmentedControl insertSubview:scopeBackground atIndex:0];
  //  [segmentedControl setSegmentedControlStyle:UISegmentedControlStyleBar];
  //  [segmentedControl setTintColor:[UIColor blueColor]];
  
  // Add new background
  UIImageView *searchBackground = [[[UIImageView alloc] initWithImage:[UIImage stretchableImageNamed:@"bg_searchbar.png" withLeftCapWidth:0 topCapWidth:0]] autorelease];
  searchBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  searchBackground.top -= 1;
  searchBackground.width = _searchBar.width;
  [_searchBar addSubview:searchBackground];
  [_searchBar addSubview:searchBarTextField];
}

// SUBCLASS SHOULD CALL THIS
- (void)setupTableViewWithFrame:(CGRect)frame andStyle:(UITableViewStyle)style andSeparatorStyle:(UITableViewCellSeparatorStyle)separatorStyle {
  _tableView = [[UITableView alloc] initWithFrame:frame style:style];
  _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  _tableView.separatorStyle = separatorStyle;
  _tableView.delegate = self;
  _tableView.dataSource = self;
  if (style == UITableViewStylePlain) {
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorColor = SEPARATOR_COLOR;
  }
  //  [self.view insertSubview:_tableView atIndex:0];
  [self.view addSubview:_tableView];
  
  // Setup optional header/footer
  [self setupTableHeader];
  [self setupTableFooter];
  
  // Set the active scrollView
  _activeScrollView = _tableView;
  
//  [_tableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
}

// SUBCLASS SHOULD IMPLEMENT
- (void)setupDataSource {
  
}

- (void)reloadDataSource {
  
}

// SUBCLASS CAN OPTIONALLY CALL
- (void)setupPullRefresh {
  if (_refreshHeaderView == nil) {
    _refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - _tableView.bounds.size.height, self.view.frame.size.width, _tableView.bounds.size.height)];
    _refreshHeaderView.delegate = self;
		[_tableView addSubview:_refreshHeaderView];		
	}
	
  //  update the last update date
  [_refreshHeaderView refreshLastUpdatedDate];
}

// Optional table header
- (void)setupTableHeader {
  // subclass should implement
}

// Optional table footer
- (void)setupTableFooter {
  // subclass should implement
}

// Optional Header View
- (void)setupHeaderWithView:(UIView *)headerView {
  _tableView.frame = CGRectMake(_tableView.left, _tableView.top + headerView.height, _tableView.width, _tableView.height - headerView.height);  
  headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
  [self.view addSubview:headerView];
}

// Optional footer view
- (void)setupFooterWithView:(UIView *)footerView {
  _tableView.frame = CGRectMake(_tableView.left, _tableView.top, _tableView.width, _tableView.height - footerView.height);
  footerView.top = self.view.height - footerView.height; // 44 navbar
  footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
  [self.view addSubview:footerView];
}

// This is the button load more style
//- (void)setupLoadMoreView {
//  _loadMoreView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44)];
//  _loadMoreView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//  _loadMoreView.backgroundColor = FB_COLOR_VERY_LIGHT_BLUE;
//  
//  // Button
//  _loadMoreButton = [[UIButton alloc] initWithFrame:_loadMoreView.frame];
//  _loadMoreButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//  _loadMoreButton.userInteractionEnabled = NO;
//  [_loadMoreButton setBackgroundImage:[UIImage imageNamed:@"search_background.png"] forState:UIControlStateNormal];
//  [_loadMoreButton addTarget:self action:@selector(loadMore) forControlEvents:UIControlEventTouchUpInside];
//  [_loadMoreButton setTitle:@"Load More..." forState:UIControlStateNormal];
//  [_loadMoreButton setTitle:@"Loading More..." forState:UIControlStateSelected];
//  [_loadMoreButton.titleLabel setShadowColor:[UIColor blackColor]];
//  [_loadMoreButton.titleLabel setShadowOffset:CGSizeMake(0, 1)];
//  [_loadMoreButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:16.0]];
//  
//  // Activity
//  _loadMoreActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
//  _loadMoreActivity.frame = CGRectMake(12, 12, 20, 20);
//  _loadMoreActivity.hidesWhenStopped = YES;
//  
//  // Add to subview
//  [_loadMoreView addSubview:_loadMoreButton];
//  [_loadMoreView addSubview:_loadMoreActivity];
//  
//  // Always show
//  //  [self showLoadMoreView];
//}

// This is the automatic load more style
- (void)setupLoadMoreView {
  _loadMoreView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44)];
  _loadMoreView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  _loadMoreView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-darkgray-320x44.png"]];
  UILabel *loadMoreLabel = [[[UILabel alloc] initWithFrame:_loadMoreView.bounds] autorelease];
  loadMoreLabel.backgroundColor = [UIColor clearColor];
  loadMoreLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  loadMoreLabel.text = @"Loading More...";
  loadMoreLabel.shadowColor = [UIColor blackColor];
  loadMoreLabel.shadowOffset = CGSizeMake(0, 1);
  loadMoreLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:16.0];
  loadMoreLabel.textColor = [UIColor whiteColor];
  loadMoreLabel.textAlignment = UITextAlignmentCenter;
  
  // Activity
  _loadMoreActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
  _loadMoreActivity.frame = CGRectMake(12, 12, 20, 20);
  _loadMoreActivity.hidesWhenStopped = YES;
  
  // Add to subview
  [_loadMoreView addSubview:loadMoreLabel];
  [_loadMoreView addSubview:_loadMoreActivity];
}

- (void)showLoadMoreView {
  if (_loadMoreView) {
    [_loadMoreActivity startAnimating];
    _tableView.tableFooterView = _loadMoreView;
  }
}

- (void)hideLoadMoreView {
  if (_loadMoreView) {
    _tableView.tableFooterView = nil;
  }
}

// Subclasses should override
- (void)updateLoadMore {
  _loadingMore = NO;
}

- (void)loadMore {
  _loadingMore = YES;
}

- (void)updateState {
  [super updateState];
}

// Called when the user logs out and we need to clear all cached data
// Subclasses should override this method
- (void)clearCachedData {
  [_items removeAllObjects];
  [self dataSourceDidLoad];
}

- (void)reloadCardController {
  [super reloadCardController];
  _reloading = YES;
  if (_refreshHeaderView) {
    [_refreshHeaderView setState:EGOOPullRefreshLoading];
  }
}

- (void)unloadCardController {
  [super unloadCardController];
}

- (void)dataSourceDidLoad {
  [super dataSourceDidLoad];
  _reloading = NO;
  if (_refreshHeaderView) {
    [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
  }
}

#pragma mark CardStateMachine
- (BOOL)dataIsAvailable {
  if (_tableView == self.searchDisplayController.searchResultsTableView) {
    return ([_searchItems count] > 0);
  } else {
    if ([_items count] > 0) {
      return YES;
    } else {
      return NO;
    }
  }
}

- (BOOL)dataSourceIsReady {
  return YES;
}

- (BOOL)dataIsLoading {
  return _reloading;
}


#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    return 1;
  } else {
    return [_items count];
  }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    return [_searchItems count];
  } else {
    return [[_items objectAtIndex:section] count];
  }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (tableView.style == UITableViewStylePlain) {
    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    backgroundView.backgroundColor = CELL_BACKGROUND_COLOR;
    cell.backgroundView = backgroundView;
    
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    selectedBackgroundView.backgroundColor = CELL_SELECTED_COLOR;
    cell.selectedBackgroundView = selectedBackgroundView;
    
    [backgroundView release];
    [selectedBackgroundView release];
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *reuseIdentifier = [NSString stringWithFormat:@"%@_TableViewCell", [self class]];
  UITableViewCell *cell = nil;
  cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier] autorelease];
  }
  
  cell.textLabel.text = @"Oops! Forgot to override this method?";
  cell.detailTextLabel.text = reuseIdentifier;
  return cell;
}

#pragma mark UISearchDisplayDelegate
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
  // SUBCLASS MUST IMPLEMENT
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
  [self filterContentForSearchText:searchString scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
  
  // Return YES to cause the search result table view to be reloaded.
  return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
  [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
  
  // Return YES to cause the search result table view to be reloaded.
  return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
  [tableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
  tableView.rowHeight = 120.0;
  tableView.backgroundColor = SEPARATOR_COLOR;
  tableView.separatorColor = SEPARATOR_COLOR;
  tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView {
  [tableView removeObserver:self forKeyPath:@"contentOffset"];
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
  // Subclass may implement
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
  // Subclass may implement
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if (!decelerate) {
//    [self scrollEndedTrigger];
  }
  if (!self.searchDisplayController.active) {
    if (_refreshHeaderView) {
      [_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    }
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//  [self scrollEndedTrigger];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{	
  if (_refreshHeaderView) {
    [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
  }
  
  if ([scrollView isKindOfClass:[UITableView class]]) {
    UITableView *tableView = (UITableView *)scrollView;
    if (!_loadingMore && _hasMore && [[tableView visibleCells] count] > 0) {
      CGFloat tableOffset = tableView.contentOffset.y + tableView.height;
      CGFloat tableBottom = tableView.contentSize.height - tableView.rowHeight;
      
      if (tableOffset >= tableBottom) {
        [self loadMore];
      }
    }
  }
}

- (void)scrollEndedTrigger {
  //  [self loadImagesForOnScreenRows];
//  [self loadMoreIfAvailable];
}

// Scrolling observer
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//  if ([keyPath isEqualToString:@"contentOffset"] && [object isKindOfClass:[UITableView class]]) {
//    // Make sure we are showing the footer first before attempting to load more
//    // Once we begin loading more, this should no longer trigger
//    //  NSLog(@"check to load more: %@", NSStringFromCGPoint(_tableView.contentOffset));
//    UITableView *tableView = (UITableView *)object;
//    if (!_loadingMore && _hasMore && [[tableView visibleCells] count] > 0) {
//      CGFloat tableOffset = tableView.contentOffset.y + tableView.height;
//      CGFloat tableBottom = tableView.contentSize.height - tableView.rowHeight;
//      
//      if (tableOffset >= tableBottom) {
//        [self loadMore];
//      }
//    }
//  }
//}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods
- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view {
  [self reloadCardController];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view {
	return _reloading; // should return if data source model is reloading
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view {
	return [NSDate date]; // should return date data source was last changed
}

#pragma mark -
#pragma mark Image Lazy Loading
- (void)loadImagesForOnScreenRows {
  //  NSArray *visibleIndexPaths = nil;
  //  if (self.searchDisplayController.active) {
  //    _visibleCells = [[self.searchDisplayController.searchResultsTableView visibleCells] retain];
  //    _visibleIndexPaths = [[self.searchDisplayController.searchResultsTableView indexPathsForVisibleRows] retain];
  //  } else {
  //    _visibleCells = [[self.tableView visibleCells] retain];
  //    _visibleIndexPaths = [[self.tableView indexPathsForVisibleRows] retain];
  //  }
  
  // Subclass SHOULD IMPLEMENT
  
  //  for (id cell in visibleCells) {
  //    if ([cell isKindOfClass:[PSImageCell class]]) {
  //      [(PSImageCell *)cell loadImage];
  //    }
  //  }
}

- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
}

- (void)dealloc {
  // Remove scrolling observer
//  [_tableView removeObserver:self forKeyPath:@"contentOffset"];
  
  RELEASE_SAFELY(_tableView);
  RELEASE_SAFELY(_sectionTitles);
  RELEASE_SAFELY(_items);
  RELEASE_SAFELY(_searchItems);
  RELEASE_SAFELY(_searchBar);
  RELEASE_SAFELY(_visibleCells);
  RELEASE_SAFELY(_visibleIndexPaths);
  RELEASE_SAFELY(_refreshHeaderView);
  RELEASE_SAFELY(_loadMoreView);
  RELEASE_SAFELY(_loadMoreButton);
  RELEASE_SAFELY(_loadMoreActivity);
  [super dealloc];
}

@end