//
//  SnapViewController.m
//  Scrapboard
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SnapViewController.h"
#import "SnapDataCenter.h"
#import "Album.h"
#import "Snap.h"
#import "HeaderCell.h"

@implementation SnapViewController

@synthesize album = _album;

- (id)init {
  self = [super init];
  if (self) {
    _snapDataCenter = [[SnapDataCenter alloc] init];
    _snapDataCenter.delegate = self;
    _sectionNameKeyPathForFetchedResultsController = @"id";
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Title and Buttons
  _navTitleLabel.text = _album.name;
  
  UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(newSnap)];
  self.navigationItem.rightBarButtonItem = rightButton;
  [rightButton release];
  
  // Table
  CGRect tableFrame = CGRectMake(0, 0, CARD_WIDTH, CARD_HEIGHT);
  [self setupTableViewWithFrame:tableFrame andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  // Pull Refresh
  [self setupPullRefresh];
  
  [self resetFetchedResultsController];
  [self executeFetch];
  [self updateState];
  [self reloadCardController];
}

- (void)reloadCardController {
  [super reloadCardController];
  
  [_snapDataCenter getSnapsForAlbumWithAlbumId:_album.id];
}

- (void)unloadCardController {
  [super unloadCardController];
}

- (void)newSnap {
  
}

#pragma mark -
#pragma mark TableView
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  Snap *snap = [[self.fetchedResultsController fetchedObjects] objectAtIndex:section];

  HeaderCell *headerCell = [[[HeaderCell alloc] initWithFrame:CGRectMake(0, 0, 320, 44)] autorelease];
  [headerCell fillCellWithObject:nil];
  [headerCell loadImage];
  return headerCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 44.0;
}

#pragma mark -
#pragma mark FetchRequest
- (NSFetchRequest *)getFetchRequest {
  return [_snapDataCenter getSnapsFetchRequestWithAlbumId:_album.id];
}

#pragma mark -
#pragma mark PSDataCenterDelegate
- (void)dataCenterDidFinish:(ASIHTTPRequest *)request withResponse:(id)response {
  NSLog(@"DC finish with response: %@", response);
  [self dataSourceDidLoad];
  [self executeFetch];
  [self updateState];
}

- (void)dataCenterDidFail:(ASIHTTPRequest *)request withError:(NSError *)error {
  [self dataSourceDidLoad];
}

- (void)dealloc {
  RELEASE_SAFELY(_album);
  RELEASE_SAFELY(_snapDataCenter);
  [super dealloc];
}

@end
