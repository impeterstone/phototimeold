//
//  AlbumViewController.m
//  PhotoTime
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import "AlbumViewController.h"
#import "AlbumDataCenter.h"
#import "PhotoViewController.h"
#import "AlbumCell.h"
#import "Album.h"
#import "PSAlertCenter.h"

@implementation AlbumViewController

@synthesize albumType = _albumType;
@synthesize albumConfig = _albumConfig;
@synthesize albumTitle = _albumTitle;

- (id)init {
  self = [super init];
  if (self) {
    _albumType = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastAlbumType"];
    _fetchLimit = 25;
    _fetchTotal = _fetchLimit;
    _frcDelegate = nil;
    _scrollCount = 0;
    _cellCache = [[NSMutableArray alloc] init];
    
//    _sectionNameKeyPathForFetchedResultsController = [@"daysAgo" retain];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDataSource) name:kReloadAlbumController object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetAlbums) name:kLogoutRequested object:nil];
  }
  return self;
}

- (void)viewDidUnload {
  [super viewDidUnload];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kReloadAlbumController object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kLogoutRequested object:nil];
  RELEASE_SAFELY(_cellCache);
  RELEASE_SAFELY(_albumTitle);
  RELEASE_SAFELY(_albumConfig);
  [super dealloc];
}

#pragma mark - View Config
- (UIView *)backgroundView {
  NSString *bgName = nil;
  if (isDeviceIPad()) {
    bgName = @"bg_grain_pad.jpg";
  } else {
    bgName = @"bg_grain.jpg";
  }
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:bgName]] autorelease];
  bg.frame = self.view.bounds;
  bg.autoresizingMask = ~UIViewAutoresizingNone;
  return bg;
}

- (void)resetAlbums {
  _hasMore = YES;
  _fetchTotal = _fetchLimit;
}

#pragma mark - View
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
//  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"]) {
//    [self loadDataSource];
//  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  [_cellCache makeObjectsPerformSelector:@selector(resumeAnimations)];
  
//  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"logoutRequested"]) {
//    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//      [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutRequested object:nil];
//    }];
//  }
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  
  [_cellCache makeObjectsPerformSelector:@selector(pauseAnimations)];
}

- (void)loadView {
  [super loadView];
  
  // Nullview
  [_nullView setLoadingTitle:@"Loading..." loadingSubtitle:@"Getting albums from Facebook" emptyTitle:@"Oh Noes!" emptySubtitle:@"No Albums Found" image:[UIImage imageNamed:@"nullview_photos.png"]];
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  self.navigationItem.titleView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"phototime_logo.png"]] autorelease];
  
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"]) {
    [self loadDataSource];
  }
}

#pragma mark - State Machine
- (BOOL)shouldLoadMore {
  return YES;
}

- (void)reloadDataSource {
  [super loadDataSource];
  [self executeFetch:FetchTypeRefresh];
}

- (void)loadDataSource {
  [super loadDataSource];
  [self executeFetch:FetchTypeCold];
}

- (void)dataSourceDidLoad {
  [super dataSourceDidLoad];
  if (![self isEqual:[[PSExposeController sharedController] selectedViewController]]) {
    [_cellCache makeObjectsPerformSelector:@selector(pauseAnimations)];
  }
}

- (void)dataSourceDidFetch {
  [self dataSourceDidLoad];
}

- (void)updateState {
  [super updateState];
}

- (void)save {
  
}

#pragma mark - TableView
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  Album *album = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  // Preload all album covers
  NSString *urlPath = album.coverPhoto;
  if (urlPath) {
    [[PSImageCache sharedCache] cacheImageForURLPath:urlPath withDelegate:nil];
  }
  
  if (isDeviceIPad()) {
    return 288.0;
  } else {
    return 120.0;
  }
}

- (void)tableView:(UITableView *)tableView configureCell:(id)cell atIndexPath:(NSIndexPath *)indexPath {
  Album *album = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  [cell fillCellWithObject:album];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"album.select"];
  
  Album *album = [self.fetchedResultsController objectAtIndexPath:indexPath];
  album.lastViewed = [NSDate date];
  [PSCoreDataStack saveInContext:[album managedObjectContext]];
  
  PhotoViewController *pvc = [[PhotoViewController alloc] init];
  pvc.album = album;
  
  // If this album is WALL, sort by timestamp instead
  if ([album.type isEqualToString:@"wall"] || [album.name isEqualToString:@"Wall Photos"]) {
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
    [_cellCache addObject:cell];
  }
  
  [self tableView:tableView configureCell:cell atIndexPath:indexPath];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
  [(AlbumCell *)cell loadPhoto];
}

#pragma mark -
#pragma mark FetchRequest
- (NSFetchRequest *)getFetchRequestInContext:(NSManagedObjectContext *)context {
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
      fetchTemplate = FETCH_FRIENDS_FILTERED;
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
    case AlbumTypeSearch:
      fetchTemplate = FETCH_SEARCH;
      substitutionVariables = [NSDictionary dictionary];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    default:
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
  }
  
  NSFetchRequest *fetchRequest = nil;
  if (self.albumType == AlbumTypeCustom) {
    fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Album" inManagedObjectContext:context]];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"fromId IN %@", [self.albumConfig objectForKey:@"ids"]];
    [fetchRequest setPredicate:pred];
  } else {
    fetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:fetchTemplate substitutionVariables:substitutionVariables];
  }
  
  [fetchRequest setSortDescriptors:sortDescriptors];
  [fetchRequest setFetchBatchSize:10];
  [fetchRequest setFetchLimit:_fetchTotal];
  return fetchRequest;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  [super scrollViewDidScroll:scrollView];
  
  if (_scrollCount == 0) {
    _scrollCount++;
    [_cellCache makeObjectsPerformSelector:@selector(pauseAnimations)];
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  [super scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
  
  if (!decelerate && (_scrollCount == 1)) {
    _scrollCount--;
    [_cellCache makeObjectsPerformSelector:@selector(resumeAnimations)];
  }

}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  [super scrollViewDidEndDecelerating:scrollView];
  
  if (_scrollCount == 1) {
    _scrollCount--;
    [_cellCache makeObjectsPerformSelector:@selector(resumeAnimations)];
  }
}

@end
