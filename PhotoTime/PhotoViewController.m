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
#import "ZoomViewController.h"

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
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
  
  // Comment Field
  _commentView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height - 44, self.view.width, 44)];
  _commentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
  _commentView.alpha = 0.0;
  
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage stretchableImageNamed:@"bg_footer_44.png" withLeftCapWidth:1 topCapWidth:0]] autorelease];
  bg.width = _commentView.width;
  [_commentView insertSubview:bg atIndex:0];
  
  // Field (310 <-> 245)
  _commentField = [[PSTextField alloc] initWithFrame:CGRectMake(5, 6, self.view.width, 32) withInset:CGSizeMake(5, 7)];
  //  _commentField.clearButtonMode = UITextFieldViewModeWhileEditing;
  //  _commentField.borderStyle = UITextBorderStyleNone;
  _commentField.background = [UIImage stretchableImageNamed:@"bg_textfield.png" withLeftCapWidth:12 topCapWidth:15];
  _commentField.font = NORMAL_FONT;
  _commentField.placeholder = @"Write a comment...";
  _commentField.returnKeyType = UIReturnKeySend;
  [_commentField addTarget:self action:@selector(commentChanged:) forControlEvents:UIControlEventEditingChanged];
  _commentField.delegate = self;
  [_commentView addSubview:_commentField];
  
  _cancelButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  _cancelButton.frame = CGRectMake(255, 6, 60, 32);
  [_cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
  _cancelButton.titleLabel.font = BOLD_FONT;
  _cancelButton.titleLabel.shadowColor = [UIColor blackColor];
  _cancelButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
  [_cancelButton setBackgroundImage:[[UIImage imageNamed:@"navbar_focus_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateNormal];
  [_cancelButton setBackgroundImage:[[UIImage imageNamed:@"navbar_focus_highlighted_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateHighlighted];
  [_cancelButton addTarget:_commentField action:@selector(resignFirstResponder) forControlEvents:UIControlEventTouchUpInside];
  _cancelButton.alpha = 0.0;
  [_commentView addSubview:_cancelButton];
  
  [self.view addSubview:_commentView];
  
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
  
  ZoomViewController *zvc = [[ZoomViewController alloc] init];
  [self presentModalViewController:zvc animated:YES];
  zvc.imageView.image = [cell.photoView.image copy];
  [zvc release];
  
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

- (void)commentChanged:(UITextField *)textField {
  //  if ([textField.text length] > 0) {
  //    _sendCommentButton.enabled = YES;
  //  } else {
  //    _sendCommentButton.enabled = NO;
  //  }
}

- (void)sendComment {
  [_commentField resignFirstResponder];
  [[PhotoDataCenter defaultCenter] addCommentForPhotoId:_photoToComment.id withMessage:_commentField.text];
  _commentField.text = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self sendComment];
  return YES;
}

#pragma mark -
#pragma mark PhotoCellDelegate
- (void)addCommentForCell:(PhotoCell *)cell {
  NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
  Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
  _photoToComment = photo;
  [_commentField becomeFirstResponder];
}

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

#pragma mark UIKeyboard
- (void)keyboardWillShow:(NSNotification *)aNotification {
  [self moveTextViewForKeyboard:aNotification up:YES];
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
  [self moveTextViewForKeyboard:aNotification up:NO]; 
}

- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up {
  NSDictionary* userInfo = [aNotification userInfo];
  
  // Get animation info from userInfo
  NSTimeInterval animationDuration;
  UIViewAnimationCurve animationCurve;
  
  CGRect keyboardEndFrame;
  
  [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
  [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
  
  
  CGRect keyboardFrame = CGRectZero;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 30200
  // code for iOS below 3.2
  [[userInfo objectForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardEndFrame];
  keyboardFrame = keyboardEndFrame;
#else
  // code for iOS 3.2 ++
  [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
  keyboardFrame = [UIScreen convertRect:keyboardEndFrame toView:self.view];
#endif  
  
  // Animate up or down
  NSString *dir = up ? @"up" : @"down";
  [UIView beginAnimations:dir context:nil];
  [UIView setAnimationDuration:animationDuration];
  [UIView setAnimationCurve:animationCurve];
  
  if (up) {
    _commentView.alpha = 1.0;
    _commentField.width = self.view.width - 75;
    _cancelButton.alpha = 1.0;
    self.view.height = self.view.height - keyboardFrame.size.height;
  } else {
    _commentView.alpha = 0.0;
    _commentField.width = self.view.width - 10;
    _cancelButton.alpha = 0.0;
    self.view.height = self.view.height + keyboardFrame.size.height;
  }
  
  [UIView commitAnimations];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

  RELEASE_SAFELY(_commentField);
  RELEASE_SAFELY(_cancelButton);
  RELEASE_SAFELY(_commentView);
  RELEASE_SAFELY(_zoomView);
  RELEASE_SAFELY(_taggedFriendsView);
  RELEASE_SAFELY(_sortKey);
  [super dealloc];
}

@end
