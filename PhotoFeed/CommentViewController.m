//
//  CommentViewController.m
//  PhotoFeed
//
//  Created by Peter Shih on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CommentViewController.h"
#import "CommentDataCenter.h"
#import "Comment.h"
#import "CommentCell.h"
#import "Photo.h"
#import "ComposeViewController.h"
#import "PhotoDataCenter.h" // for insert

@implementation CommentViewController

@synthesize photo = _photo;
@synthesize photoImage = _photoImage;

- (id)init {
  self = [super init];
  if (self) {
    _commentDataCenter = [[CommentDataCenter alloc] init];
    _commentDataCenter.delegate = self;
    _isHeaderExpanded = NO;
    self.hidesBottomBarWhenPushed = YES;
    _fetchLimit = 100;
    _fetchTotal = _fetchLimit;
    _frcDelegate = self;
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

- (void)loadView {
  [super loadView];
  
  [self resetFetchedResultsController];
  
  // Title and Buttons
  _navTitleLabel.text = _photo.name;
  
  [self addBackButton];
//  [self addButtonWithTitle:@"New" andSelector:@selector(newComment) isLeft:NO];
  
  // Table
  CGRect tableFrame = CGRectMake(0, 0, CARD_WIDTH, CARD_HEIGHT);
  [self setupTableViewWithFrame:tableFrame andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
  
  // Pull Refresh
//  [self setupPullRefresh];
  
  [self setupHeader];
  [self setupTableFooter];
  
  [self setupFooter];
  
  [self executeFetch:FetchTypeCold];
  
  // Get new from server
  // Comments don't need to fetch from server immediately, only after a new post
//  [self reloadCardController];
}

- (void)setupTableFooter {
  UIImageView *footerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_footer_background.png"]];
  _tableView.tableFooterView = footerImage;
  [footerImage release];
}

- (void)setupHeader {
  _headerHeight = 0.0;
  _headerOffset = 0.0;
  _photoHeight = 0.0;
  
  _photoHeaderView = [[[UIImageView alloc] initWithImage:_photoImage] autorelease];
  _photoHeaderView.width = 320;
  _photoHeight = floor((320 / _photoImage.size.width) * _photoImage.size.height);
  _photoHeaderView.height = _photoHeight;
  
  _headerHeight = (_photoHeight >= 120) ? 120 : _photoHeight;
  _headerOffset = floor((_photoHeight - _headerHeight) / 2);
  
  _commentHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, _headerHeight)] autorelease];
  _commentHeaderView.clipsToBounds = YES;
  _photoHeaderView.top = 0 - _headerOffset;
  [_commentHeaderView addSubview:_photoHeaderView];
  _tableView.tableHeaderView = _commentHeaderView;
  
  UITapGestureRecognizer *toggleHeaderTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleHeader:)] autorelease];
  [_commentHeaderView addGestureRecognizer:toggleHeaderTap];
}

- (void)toggleHeader:(UITapGestureRecognizer *)gestureRecognizer {
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
  [UIView setAnimationDuration:0.4];
  [UIView setAnimationDidStopSelector:@selector(toggleHeaderFinished)];
  [UIView setAnimationDelegate:self];
  if (_isHeaderExpanded) {
    _isHeaderExpanded = NO;
    _commentHeaderView.height = _headerHeight;
    _photoHeaderView.top -= _headerOffset;
  } else {
    _isHeaderExpanded = YES;
    _commentHeaderView.height = _photoHeight;
    _photoHeaderView.top = 0;
  }
  _tableView.tableHeaderView = _commentHeaderView;
  [UIView commitAnimations];
}

- (void)toggleHeaderFinished {

}

- (void)setupFooter {
  UIView *footerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44)] autorelease];
  
  // Setup the fake image view
  PSURLCacheImageView *profileImage = [[PSURLCacheImageView alloc] initWithFrame:CGRectMake(10, 7, 30, 30)];
  profileImage.urlPath = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=square", [[NSUserDefaults standardUserDefaults] objectForKey:@"facebookId"]];
  [profileImage loadImageAndDownload:YES];
  profileImage.layer.cornerRadius = 5.0;
  profileImage.layer.masksToBounds = YES;
  [footerView addSubview:profileImage];
  [profileImage release];
  
  // Setup the fake comment button
  UIButton *commentButton = [[UIButton alloc] initWithFrame:CGRectMake(45, 7, 265, 30)];
  commentButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  commentButton.titleLabel.font = [UIFont systemFontOfSize:14];
  [commentButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
  [commentButton setContentEdgeInsets:UIEdgeInsetsMake(0, 15, 0, 0)];
  [commentButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
  [commentButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
  [commentButton setTitle:@"Write a comment..." forState:UIControlStateNormal];
  [commentButton setBackgroundImage:[[UIImage imageNamed:@"bubble.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:15] forState:UIControlStateNormal];
  [commentButton addTarget:self action:@selector(newComment) forControlEvents:UIControlEventTouchUpInside];
  [footerView addSubview:commentButton];
  [commentButton release];
  
  footerView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"navigationbar_bg.png"]];
  
  [self setupFooterWithView:footerView];
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
  ComposeViewController *cvc = [[ComposeViewController alloc] init];
  cvc.photoId = _photo.id;
  cvc.pickedImage = self.photoImage;
  cvc.delegate = self;
  cvc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  [self presentModalViewController:cvc animated:YES];
  [cvc release];
}

#pragma mark - Compose Delegate
- (void)composeDidSendWithUserInfo:(NSDictionary *)userInfo {
  [[PhotoDataCenter defaultCenter] insertCommentWithDictionary:userInfo forPhoto:_photo inContext:[_photo managedObjectContext]];
  
  // Reload
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

#pragma mark -
#pragma mark FetchRequest
- (NSFetchRequest *)getFetchRequest {
  return [_commentDataCenter fetchCommentsForPhoto:_photo];
}

- (void)dealloc {
  _commentDataCenter.delegate = nil;
  RELEASE_SAFELY(_commentDataCenter);
  [super dealloc];
}

@end
