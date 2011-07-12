//
//  PhotoViewController.m
//  Moogle
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PhotoViewController.h"
#import "PhotoDataCenter.h"
#import "Album.h"
#import "Photo.h"
#import "Tag.h"
#import "HeaderCell.h"
#import "PhotoCell.h"
#import "PSZoomView.h"
#import "CommentViewController.h"
#import "PSRollupView.h"
#import "PSToastCenter.h"

@implementation PhotoViewController

@synthesize album = _album;

- (id)init {
  self = [super init];
  if (self) {
    _photoDataCenter = [[PhotoDataCenter alloc] init];
    _photoDataCenter.delegate = self;
    _sectionNameKeyPathForFetchedResultsController = nil;
    self.hidesBottomBarWhenPushed = YES;
    _fetchLimit = 25;
    _fetchTotal = _fetchLimit;
    _frcDelegate = nil;
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
//  [self.navigationController setNavigationBarHidden:NO animated:YES];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCardController) name:kReloadPhotoController object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kReloadPhotoController object:nil];
}

- (void)loadView {
  [super loadView];
  
  [self resetFetchedResultsController];
  
  // Title and Buttons
  _navTitleLabel.text = _album.name;
  
  [self addBackButton];
  
  // Table
  CGRect tableFrame = self.view.bounds;
  [self setupTableViewWithFrame:tableFrame andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  // Search
//  [self setupSearchDisplayControllerWithScopeButtonTitles:nil andPlaceholder:@"Tagged Friends..."];
  
  // Pull Refresh
  [self setupPullRefresh];
  
  [self executeFetch:FetchTypeCold];
  
  // Get new from server
  [self reloadCardController];
}

#pragma mark - Tagged Friends
- (void)getTaggedFriends {
  NSFetchRequest *fetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:@"getPhotosForAlbum" substitutionVariables:[NSDictionary dictionaryWithObject:_album.id forKey:@"desiredAlbumId"]];
  [fetchRequest setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"tags"]];
  
  NSArray *allPhotos = [self.context executeFetchRequest:fetchRequest error:NULL];
  
  if (allPhotos && [allPhotos count] > 0) {
    NSArray *taggedFriendIds = [allPhotos valueForKeyPath:@"@distinctUnionOfArrays.tags.fromId"];
    NSArray *taggedFriendNames = [allPhotos valueForKeyPath:@"@distinctUnionOfArrays.tags.fromName"];
    
    // Only create a rollup if there are more than 0 friends tagged
    if ([taggedFriendIds count] > 0) {    
      NSRange excerptRange;
      excerptRange.location = 0;
      excerptRange.length = [taggedFriendNames count] < 5 ? [taggedFriendNames count] : 5;
      NSArray *excerptTaggedFriendNames = [taggedFriendNames subarrayWithRange:excerptRange];
      
      if ([taggedFriendIds count] > 0) {
        NSMutableArray *taggedFriendPictures = [NSMutableArray array];
        for (NSString *friendId in taggedFriendIds) {
          [taggedFriendPictures addObject:[NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=square", friendId]];
        }
        
        // Create Rollup
        _taggedFriendsView = [[PSRollupView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 0)];
        [_taggedFriendsView setBackgroundImage:[UIImage stretchableImageNamed:@"bg-rollup.png" withLeftCapWidth:0 topCapWidth:0]];
  //      [_taggedFriendsView setHeaderText:[NSString stringWithFormat:@"In this album: %@.", [NSString stringWithFormat:@"%@", [taggedFriendNames componentsJoinedByString:@", "]]]];
        [_taggedFriendsView setHeaderText:[NSString stringWithFormat:@"%@ and %d more friends are tagged in this album.", [excerptTaggedFriendNames componentsJoinedByString:@", "], [taggedFriendIds count]]];
        
        [_taggedFriendsView setPictureURLArray:taggedFriendPictures];
        [_taggedFriendsView layoutIfNeeded];
        self.tableView.tableHeaderView = _taggedFriendsView;
      }
    }
  }
}

#pragma mark - State Machine
- (void)updateState {
  [super updateState];
  [self getTaggedFriends];
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
    [[PSToastCenter defaultCenter] showToastWithMessage:@"Favorite Removed" toastType:PSToastTypeAlert toastDuration:1.0];
  } else {
    _album.isFavorite = [NSNumber numberWithBool:YES];
    [[PSToastCenter defaultCenter] showToastWithMessage:@"Favorite Added" toastType:PSToastTypeAlert toastDuration:1.0];
  }
  [PSCoreDataStack saveInContext:[_album managedObjectContext]];
}

#pragma mark -
#pragma mark TableView
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  // Preload all photos
  NSString *urlPath = photo.source;
  if (urlPath) {
    [[PSImageCache sharedCache] cacheImageForURLPath:urlPath withDelegate:nil];
  }

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
  if (!cell.photoView.image) return;
  
  Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
  CommentViewController *cvc = [[CommentViewController alloc] init];
  cvc.photo = photo;
  cvc.photoImage = cell.photoView.image; // assign
  [self.navigationController pushViewController:cvc animated:YES];
  [cvc release];
  

//  [self zoomPhotoForCell:cell atIndexPath:indexPath];
}

- (void)zoomPhotoForCell:(PhotoCell *)cell atIndexPath:(NSIndexPath *)indexPath {
  if (!_zoomView) {
    _zoomView = [[PSZoomView alloc] initWithFrame:[[[UIApplication sharedApplication] keyWindow] bounds]];
  }
  
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
//  BOOL ascending = ([self.sectionNameKeyPathForFetchedResultsController isEqualToString:@"position"]) ? YES : NO;
  BOOL ascending = YES;

  NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"position" ascending:ascending] autorelease];
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
  RELEASE_SAFELY(_zoomView);
  RELEASE_SAFELY(_taggedFriendsView);
  [super dealloc];
}

@end
