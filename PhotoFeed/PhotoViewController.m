//
//  PhotoViewController.m
//  PhotoFeed
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PhotoViewController.h"
#import "PhotoDataCenter.h"
#import "Album.h"
#import "Photo.h"
#import "HeaderCell.h"
#import "PhotoCell.h"
#import "CameraViewController.h"
#import "PSZoomView.h"
#import "CommentViewController.h"

@implementation PhotoViewController

@synthesize album = _album;

- (id)init {
  self = [super init];
  if (self) {
    _photoDataCenter = [[PhotoDataCenter alloc] init];
    _photoDataCenter.delegate = self;
    _sectionNameKeyPathForFetchedResultsController = [@"position" retain];
    _headerCellCache = [[NSMutableDictionary alloc] init];
    self.hidesBottomBarWhenPushed = YES;
    _fetchLimit = 10;
    _fetchTotal = _fetchLimit;
    _frcDelegate = nil;
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
//  [self.navigationController setNavigationBarHidden:NO animated:YES];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCardController) name:kReloadController object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kReloadController object:nil];
}

- (void)loadView {
  [super loadView];
  
  [self resetFetchedResultsController];
  
  // Title and Buttons
  _navTitleLabel.text = _album.name;
  
  [self addBackButton];
  [self addButtonWithTitle:@"Favorite" andSelector:@selector(favorite) isLeft:NO];
  
  // Table
  CGRect tableFrame = CGRectMake(0, 0, CARD_WIDTH, CARD_HEIGHT);
  [self setupTableViewWithFrame:tableFrame andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  // Search
  [self setupSearchDisplayControllerWithScopeButtonTitles:nil andPlaceholder:@"Tagged Friends..."];
  
  // Pull Refresh
  [self setupPullRefresh];
  
//  [self setupLoadMoreView];
  
  [self executeFetch:FetchTypeCold];
  
  // Get new from server
  [self reloadCardController];
}

- (void)reloadCardController {
  [super reloadCardController];
  
  [_photoDataCenter getPhotosForAlbumId:_album.id];
}

- (void)unloadCardController {
  [super unloadCardController];
}

#pragma mark -
#pragma mark PSDataCenterDelegate
- (void)dataCenterDidFinish:(ASIHTTPRequest *)request withResponse:(id)response {
  [self dataSourceDidLoad];
}

- (void)dataCenterDidFail:(ASIHTTPRequest *)request withError:(NSError *)error {
  [self dataSourceDidLoad];
}

#pragma mark -
#pragma mark Compose
- (void)favorite {
  if ([_album.isFavorite boolValue]) {
    _album.isFavorite = [NSNumber numberWithBool:NO];
  } else {
    _album.isFavorite = [NSNumber numberWithBool:YES];
  }
  [PSCoreDataStack saveInContext:[_album managedObjectContext]];
  
  // Show a Toast
}

#pragma mark -
#pragma mark TableView
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  Photo *photo = [[self.fetchedResultsController fetchedObjects] objectAtIndex:section];
  
  HeaderCell *headerCell = [[[HeaderCell alloc] initWithFrame:CGRectMake(0, 0, 320, 26)] autorelease];
  [headerCell fillCellWithObject:photo];
  //  [headerCell loadImage];
  [_headerCellCache setObject:headerCell forKey:[NSString stringWithFormat:@"%d", section]];
  return headerCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 26.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
  return [PhotoCell rowHeightForObject:photo forInterfaceOrientation:[self interfaceOrientation]];
}

- (void)tableView:(UITableView *)tableView configureCell:(id)cell atIndexPath:(NSIndexPath *)indexPath {
  Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  [cell fillCellWithObject:photo];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  PhotoCell *cell = nil;
  NSString *reuseIdentifier = [PhotoCell reuseIdentifier];
  
  cell = (PhotoCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if(cell == nil) { 
    cell = [[[PhotoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
    cell.delegate = self;
  }
  
  [self tableView:tableView configureCell:cell atIndexPath:indexPath];

  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  PhotoCell *cell = (PhotoCell *)[tableView cellForRowAtIndexPath:indexPath];
  [self zoomPhotoForCell:cell atIndexPath:indexPath];
}

- (void)zoomPhotoForCell:(PhotoCell *)cell atIndexPath:(NSIndexPath *)indexPath {
  if (!_zoomView) {
    _zoomView = [[PSZoomView alloc] initWithFrame:[[[UIApplication sharedApplication] keyWindow] bounds]];
  }
  
  Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
  _zoomView.photo = photo;
  _zoomView.zoomImageView.image = cell.photoView.image;
  _zoomView.zoomImageView.frame = [cell convertRect:cell.photoView.frame toView:nil];
  _zoomView.oldImageFrame = [cell convertRect:cell.photoView.frame toView:nil];
  _zoomView.oldCaptionFrame = [cell convertRect:cell.captionLabel.frame toView:nil];
  _zoomView.caption = [[cell.captionLabel.text copy] autorelease];
  [_zoomView showZoom];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
  [(PhotoCell *)cell loadPhoto];
//  NSLog(@"wdc sec: %d, row: %d", indexPath.section, indexPath.row);
}

#pragma mark -
#pragma mark PhotoCellDelegate
- (void)commentsSelectedForCell:(PhotoCell *)cell {
  NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
  Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
  CommentViewController *cvc = [[CommentViewController alloc] init];
  cvc.photo = photo;
  cvc.photoImage = cell.photoView.image; // copy
  [self.navigationController pushViewController:cvc animated:YES];
  [cvc release];
}

//- (void)pinchZoomTriggeredForCell:(PhotoCell *)cell {
//  [self zoomPhotoForCell:cell];
//}

#pragma mark -
#pragma mark UISearchDisplayDelegate
- (void)delayedFilterContentWithTimer:(NSTimer *)timer {
  NSDictionary *userInfo = [timer userInfo];
  NSString *searchText = [userInfo objectForKey:@"searchText"];
//  NSString *scope = [userInfo objectForKey:@"scope"];
  NSMutableArray *subpredicates = [NSMutableArray arrayWithCapacity:1];
  
  NSArray *searchTerms = [[searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -,/\\+_"]];
  
  for (NSString *searchTerm in searchTerms) {
    NSString *searchValue = [NSString stringWithFormat:@"%@", searchTerm];
    [subpredicates addObject:[NSPredicate predicateWithFormat:@"ANY tags.fromName CONTAINS[cd] %@", searchValue]];
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
  BOOL ascending = ([self.sectionNameKeyPathForFetchedResultsController isEqualToString:@"position"]) ? YES : NO;

  NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:self.sectionNameKeyPathForFetchedResultsController ascending:ascending] autorelease];
  NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptor, nil] autorelease];
  NSFetchRequest *fetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:@"getPhotosForAlbum" substitutionVariables:[NSDictionary dictionaryWithObject:_album.id forKey:@"desiredAlbumId"]];
  [fetchRequest setSortDescriptors:sortDescriptors];
  [fetchRequest setFetchBatchSize:5];
  [fetchRequest setFetchLimit:_fetchTotal];
  return fetchRequest;
}

- (void)dealloc {
  _photoDataCenter.delegate = nil;
  RELEASE_SAFELY(_photoDataCenter);
  RELEASE_SAFELY(_headerCellCache);
  RELEASE_SAFELY(_zoomView);
  [super dealloc];
}

@end
