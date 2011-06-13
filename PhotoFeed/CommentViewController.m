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
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
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
  
  [self setupFooterView];
  
  [self executeFetch:YES];
  
  // Get new from server
  // Comments don't need to fetch from server immediately, only after a new post
//  [self reloadCardController];
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

- (void)setupFooterView {
  [super setupFooterView];
  
  // Setup the fake image view
  PSURLCacheImageView *profileImage = [[PSURLCacheImageView alloc] initWithFrame:CGRectMake(10, 7, 30, 30)];
  profileImage.urlPath = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=square", [[NSUserDefaults standardUserDefaults] objectForKey:@"facebookId"]];
  [profileImage loadImageAndDownload:YES];
  profileImage.layer.cornerRadius = 5.0;
  profileImage.layer.masksToBounds = YES;
  [_footerView addSubview:profileImage];
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
  [_footerView addSubview:commentButton];
  [commentButton release];
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
  //  CameraViewController *cvc = [[CameraViewController alloc] init];
  //  UINavigationController *cnc = [[UINavigationController alloc] initWithRootViewController:cvc];
  //  [self presentModalViewController:cnc animated:YES];
  //  [cvc autorelease];
  //  [cnc autorelease];
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
