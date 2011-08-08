//
//  PhotoViewController.m
//  PhotoTime
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
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
#import "UploadViewController.h"

#import <MobileCoreServices/UTCoreTypes.h>

@implementation PhotoViewController (ImagePickerDelegateMethods)

// For responding to the user tapping Cancel.
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [[picker parentViewController] dismissModalViewControllerAnimated:YES];
  [picker release];
}

// For responding to the user accepting a newly-captured picture or movie
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
  
  //  if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
  //    _shouldSaveToAlbum = YES;
  //  } else {
  //    _shouldSaveToAlbum = NO;
  //  }
  
  // Handle a still image capture
  if (CFStringCompare((CFStringRef)mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
    UIImage *originalImage = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
    
    // Use FB High Res (2048x2048)
    // Only use if high res uploads are enabled
//    _uploadImage = [originalImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(2048, 2048) interpolationQuality:kCGInterpolationHigh];
    
    // Use FB Low Res (720x720)
    _uploadImage = [originalImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(720, 720) interpolationQuality:kCGInterpolationHigh];
    
  }
  
  //  if (_snappedImage && _shouldSaveToAlbum) {
  //    UIImageWriteToSavedPhotosAlbum(_snappedImage, nil, nil, nil);
  //  }
  
  UploadViewController *uvc = [[UploadViewController alloc] init];
  uvc.uploadImage = _uploadImage;
  uvc.delegate = self;
  [picker pushViewController:uvc animated:YES];
  [uvc release];
}

@end

@implementation PhotoViewController

@synthesize album = _album;
@synthesize sortKey = _sortKey;

- (id)init {
  self = [super init];
  if (self) {
    _sectionNameKeyPathForFetchedResultsController = nil;
    self.hidesBottomBarWhenPushed = YES;
    _fetchLimit = 25;
    _fetchTotal = _fetchLimit;
    _frcDelegate = nil;
    _sortKey = [@"position" retain];
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
//  [self.navigationController setNavigationBarHidden:NO animated:YES];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCardController) name:kReloadPhotoController object:nil];
  [[PhotoDataCenter defaultCenter] setDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kReloadPhotoController object:nil];
  [[PhotoDataCenter defaultCenter] setDelegate:nil];
  self.navigationItem.leftBarButtonItem = nil;
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
  
  if ([_album.fromId isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"facebookId"]]) {
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem navButtonWithImage:[UIImage imageNamed:@"icon_camera.png"] withTarget:self action:@selector(upload) buttonType:NavButtonTypeGreen];
  } else {
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem navButtonWithTitle:@"Favorite" withTarget:self action:@selector(favorite) buttonType:NavButtonTypeBlue];
  }
  
  // Pull Refresh
//  [self setupPullRefresh];
  
  [self executeFetch:FetchTypeCold];
  
  // Get new from server
  [self reloadCardController];
}

#pragma mark - UploadDelegate
- (void)uploadPhotoWithData:(NSData *)data caption:(NSString *)caption {
  [[PhotoDataCenter defaultCenter] uploadPhotoForAlbumId:_album.id withImageData:data andCaption:caption];
}

#pragma mark - Tagged Friends
- (void)getTaggedFriends {
  NSFetchRequest *fetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:FETCH_PHOTOS substitutionVariables:[NSDictionary dictionaryWithObject:_album.id forKey:@"desiredAlbumId"]];
  [fetchRequest setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"tags"]];
  
  NSArray *allPhotos = [_context executeFetchRequest:fetchRequest error:NULL];
  
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
        [_taggedFriendsView setBackgroundImage:[UIImage stretchableImageNamed:@"bg_rollup.png" withLeftCapWidth:0 topCapWidth:0]];
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

  [[PhotoDataCenter defaultCenter] getPhotosForAlbumId:_album.id];
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

#pragma mark - Actions
- (void)upload {
  UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
  imagePicker.allowsEditing = NO;
  imagePicker.delegate = self;
//  imagePicker.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  
  // Source Type
  imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  
  // Media Types
  //  imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
  imagePicker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
  //  imagePicker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
  
  [self presentModalViewController:imagePicker animated:YES];
}

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
  
  return [PhotoCell rowHeightForObject:photo expanded:[self cellIsSelected:indexPath] forInterfaceOrientation:[self interfaceOrientation]];
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
//  [self commentsSelectedForCell:cell];
  
  Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  CGRect photoFrame = [cell convertRect:cell.photoView.frame toView:self.view];
  
//  CommentViewController *cvc = [[CommentViewController alloc] init];
//  cvc.photo = photo;
//  cvc.photoOffset = photoFrame.origin.y + 44;
//  cvc.photoView.image = cell.photoView.image;
  //  cvc.photoView.image = cell.photoView.image;
  
//  [self.navigationController.view addSubview:cvc.view];
//  [cvc viewWillAppear:YES];
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
  
  // Toggle 'selected' state
	BOOL isSelected = ![self cellIsSelected:indexPath];
	
	// Store cell 'selected' state keyed on indexPath
	NSNumber *selectedIndex = [NSNumber numberWithBool:isSelected];
	[_selectedIndexes setObject:selectedIndex forKey:indexPath];	
  [cell setIsExpanded:isSelected];
  
	// This is where magic happens...
	[_tableView beginUpdates];
	[_tableView endUpdates];
  
//  CGRect photoFrame = [cell convertRect:cell.photoView.frame toView:self.view];
//  
//  CommentViewController *cvc = [[CommentViewController alloc] init];
//  cvc.photo = photo;
//  cvc.photoOffset = photoFrame.origin.y + 44;
//  cvc.photoView.image = cell.photoView.image;
////  cvc.photoView.image = cell.photoView.image;
//  
//  // If there are no comments, compose on appear
//  if ([photo.comments count] == 0) {
//    cvc.composeOnAppear = YES;
//  }
//  
//  [self.navigationController.view addSubview:cvc.view];
//  [cvc viewWillAppear:YES];
}

- (void)addRemoveLikeForCell:(PhotoCell *)cell {
  NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
  Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  // Add or Remove a like on the given photo
  [[PhotoDataCenter defaultCenter] addLikeForPhotoId:photo.id];
  [[PSToastCenter defaultCenter] showToastWithMessage:@"Photo Liked" toastType:PSToastTypeAlert toastDuration:1.0];
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
  BOOL ascending = ([self.sortKey isEqualToString:@"position"]) ? YES : NO;
//  BOOL ascending = YES;

  NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:self.sortKey ascending:ascending] autorelease];
  NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptor, nil] autorelease];
  NSFetchRequest *fetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:FETCH_PHOTOS substitutionVariables:[NSDictionary dictionaryWithObject:_album.id forKey:@"desiredAlbumId"]];
  [fetchRequest setSortDescriptors:sortDescriptors];
  [fetchRequest setFetchBatchSize:5];
  [fetchRequest setFetchLimit:_fetchTotal];
  return fetchRequest;
}

- (void)dealloc {
  RELEASE_SAFELY(_zoomView);
  RELEASE_SAFELY(_taggedFriendsView);
  RELEASE_SAFELY(_sortKey);
  [super dealloc];
}

@end
