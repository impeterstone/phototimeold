//
//  CommentViewController.m
//  Moogle
//
//  Created by Peter Shih on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CommentViewController.h"
#import "Comment.h"
#import "CommentCell.h"
#import "Photo.h"
#import "PhotoDataCenter.h" // for insert
#import "PSImageView.h"

@implementation CommentViewController

@synthesize photo = _photo;
@synthesize photoOffset = _photoOffset;
@synthesize photoView = _photoView;

- (id)init {
  self = [super init];
  if (self) {
    _fetchLimit = 100;
    _fetchTotal = _fetchLimit;
    _frcDelegate = nil;
    _photoOffset = 0.0;
    _photoView = [[PSImageView alloc] initWithFrame:CGRectZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  CGFloat photoWidth = self.photoView.image.size.width;
  CGFloat photoHeight = self.photoView.image.size.height;
  
  self.photoView.frame = CGRectMake(0, _photoOffset, self.view.width, floor(photoHeight / (photoWidth / self.view.width)));
  
  [self.view insertSubview:self.photoView aboveSubview:self.tableView];
  self.view.alpha = 0.0;
  [UIView animateWithDuration:0.4
                   animations:^{
                     _photoView.frame = CGRectMake(0, 0, _photoView.width, _photoView.height);
                     self.view.alpha = 1.0;
                   }
                   completion:^(BOOL finished) {
                     [self.photoView removeFromSuperview];
                     self.tableView.tableHeaderView = self.photoView;
                   }];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

- (void)loadView {
  [super loadView];  
  [self resetFetchedResultsController];
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
  
  [self executeFetch:FetchTypeCold];
  
  // Get new from server
  // Comments don't need to fetch from server immediately, only after a new post
//  [self reloadCardController];
  
  [self setupFooter];
  
  // Gestures    
  UITapGestureRecognizer *dismissTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)] autorelease];
  dismissTap.delegate = self;
  [self.view addGestureRecognizer:dismissTap];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  if ([touch.view isKindOfClass:[UIButton class]]) {
    return NO;
  } else {
    return YES;
  }
}


- (void)dismiss {
  [_commentField resignFirstResponder];
  [self setupTableHeader];
  [self.view insertSubview:self.photoView aboveSubview:self.tableView];
  [UIView animateWithDuration:0.4
                   animations:^{
                     _photoView.frame = CGRectMake(0, _photoOffset, _photoView.width, _photoView.height);
                     self.view.alpha = 0.0;
                   }
                   completion:^(BOOL finished) {
                     [self.view removeFromSuperview];
                     [self autorelease];
                   }];
}

#pragma mark - Footer
- (void)setupFooter {
  UIView *footerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44)] autorelease];
  footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg-compose-bubble.png"]] autorelease];
  bg.top = -14;
  [footerView insertSubview:bg atIndex:0];
  
  // Field
  _commentField = [[PSTextField alloc] initWithFrame:CGRectMake(5, 5, 245, 34) withInset:CGSizeMake(5, 8)];
//  _commentField.clearButtonMode = UITextFieldViewModeWhileEditing;
//  _commentField.borderStyle = UITextBorderStyleNone;
  _commentField.background = [UIImage stretchableImageNamed:@"bg_textfield.png" withLeftCapWidth:12 topCapWidth:15];
  _commentField.font = BOLD_FONT;
  _commentField.placeholder = @"Write a comment...";
  _commentField.returnKeyType = UIReturnKeySend;
  [_commentField addTarget:self action:@selector(commentChanged:) forControlEvents:UIControlEventEditingChanged];
  [footerView addSubview:_commentField];
  
  // Button
  _sendCommentButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  _sendCommentButton.frame = CGRectMake(255, 4, 60, 36);
  [_sendCommentButton setTitle:@"Send" forState:UIControlStateNormal];
  _sendCommentButton.titleLabel.font = TITLE_FONT;
  _sendCommentButton.titleLabel.shadowColor = [UIColor blackColor];
  _sendCommentButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
  [_sendCommentButton setBackgroundImage:[[UIImage imageNamed:@"navbar_blue_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateNormal];
  [_sendCommentButton setBackgroundImage:[[UIImage imageNamed:@"navbar_blue_highlighted_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateHighlighted];
  [_sendCommentButton addTarget:self action:@selector(sendComment) forControlEvents:UIControlEventTouchUpInside];
  _sendCommentButton.enabled = NO;
  [footerView addSubview:_sendCommentButton];
  
  [self setupFooterWithView:footerView];
}

- (void)commentChanged:(UITextField *)textField {
  if ([textField.text length] > 0) {
    _sendCommentButton.enabled = YES;
  } else {
    _sendCommentButton.enabled = NO;
  }
}

- (void)sendComment {
  [[PhotoDataCenter defaultCenter] addCommentForPhotoId:_photo.id withMessage:_commentField.text];
  _commentField.text = nil;
  [_commentField resignFirstResponder];
}

#pragma mark - Table Header/Footer
- (void)setupTableHeader {
  CGFloat photoWidth = self.photoView.image.size.width;
  CGFloat photoHeight = self.photoView.image.size.height;
  
  // Dummy placer view
  self.tableView.tableHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, photoWidth, photoHeight)] autorelease];
}

- (void)setupTableFooter {
  UIImageView *footerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg-table-footer.png"]];
  _tableView.tableFooterView = footerImage;
  [footerImage release];
}

#pragma mark - State Machine
- (void)updateState {
  [super updateState];
}

- (void)reloadCardController {
  [super reloadCardController];
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
- (void)newComment {
//  ComposeViewController *cvc = [[ComposeViewController alloc] init];
//  cvc.photoId = _photo.id;
//  cvc.pickedImage = self.photoImage;
//  cvc.delegate = self;
//  cvc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
//  [self presentModalViewController:cvc animated:YES];
//  [cvc release];
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
    self.view.height = self.view.height - keyboardFrame.size.height;
  } else {
    self.view.height = self.view.height + keyboardFrame.size.height;
  }
  
  [UIView commitAnimations];
}

#pragma mark -
#pragma mark Table
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  Comment *comment = [self.fetchedResultsController objectAtIndexPath:indexPath];
  return [CommentCell rowHeightForObject:comment forInterfaceOrientation:[self interfaceOrientation]];
}

- (void)tableView:(UITableView *)tableView configureCell:(id)cell atIndexPath:(NSIndexPath *)indexPath {
  Comment *comment = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  [cell fillCellWithObject:comment];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  CommentCell *cell = nil;
  NSString *reuseIdentifier = [CommentCell reuseIdentifier];
  
  cell = (CommentCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if(cell == nil) { 
    cell = [[[CommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
  }
  
  [self tableView:tableView configureCell:cell atIndexPath:indexPath];
  
  //  NSLog(@"display");
  return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  UIView *backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
  backgroundView.backgroundColor = CELL_WHITE_COLOR;
  cell.backgroundView = backgroundView;
  
  UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
  selectedBackgroundView.backgroundColor = CELL_SELECTED_COLOR;
  cell.selectedBackgroundView = selectedBackgroundView;
  
  [backgroundView release];
  [selectedBackgroundView release];
}

#pragma mark - FetchRequest
- (NSFetchRequest *)getFetchRequest {
  NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES] autorelease];
  NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptor, nil] autorelease];
  NSFetchRequest *fetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:FETCH_COMMENTS substitutionVariables:[NSDictionary dictionaryWithObject:_photo forKey:@"desiredPhoto"]];
  [fetchRequest setSortDescriptors:sortDescriptors];
  [fetchRequest setFetchBatchSize:10];
  return fetchRequest;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
  
  RELEASE_SAFELY(_photoView);
  RELEASE_SAFELY(_commentField);
  RELEASE_SAFELY(_sendCommentButton);
  [super dealloc];
}

@end
