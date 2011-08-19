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
//    _sectionNameKeyPathForFetchedResultsController = [@"daysAgo" retain];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadDataSource) name:kReloadAlbumController object:nil];
  }
  return self;
}

- (void)dealloc {
  RELEASE_SAFELY(_albumTitle);
  RELEASE_SAFELY(_albumConfig);
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kReloadAlbumController object:nil];
  [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"logoutRequested"]) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutRequested object:nil];
    }];
  }
  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"isFirstLogin"]) {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isFirstLogin"];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [[PSAlertCenter defaultCenter] postAlertWithTitle:@"Welcome!" andMessage:@"We are still downloading albums from your friends. You can browse your own photos in the meantime." andDelegate:nil];
    }];
  }
}

- (void)loadView {
  [super loadView];
  
  // Nullview
  [_nullView setLoadingTitle:@"Loading" loadingSubtitle:@"Getting albums from Facebook..." emptyTitle:@"No Photos Found" emptySubtitle:@"Epic Fail Time!" image:[UIImage imageNamed:@"nullview_search.png"]];
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  if (self.albumType == AlbumTypeSearch) {
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem navButtonWithTitle:@"Save" withTarget:self action:@selector(save) buttonType:NavButtonTypeBlue];
  }
  
  self.navigationItem.titleView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"phototime_logo.png"]] autorelease];
  
  [self loadDataSource];
}

#pragma mark - State Machine
- (void)loadDataSource {
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"]) {
    [super loadDataSource];
    [self dataSourceDidLoad];
  }
}

- (void)dataSourceDidLoad {
  [super dataSourceDidLoad];
  _hasMore = YES;
  _fetchTotal = _fetchLimit;
  [self executeFetch:FetchTypeCold];
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
#pragma mark FetchRequest
- (NSFetchRequest *)getFetchRequestInContext:(NSManagedObjectContext *)context {
  NSArray *sortDescriptors = nil;
  NSString *fetchTemplate = nil;
  NSDictionary *substitutionVariables = nil;
  NSString *facebookId = [[NSUserDefaults standardUserDefaults] stringForKey:@"facebookId"] ? [[NSUserDefaults standardUserDefaults] stringForKey:@"facebookId"] : @"";
  
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

@end
