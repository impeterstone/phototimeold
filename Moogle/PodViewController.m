//
//  PodViewController.m
//  Moogle
//
//  Created by Peter Shih on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PodViewController.h"
#import "PodDataCenter.h"
#import "FeedViewController.h"
#import "Pod.h"
#import "PodCell.h"

// Test
#import "LINetworkQueue.h"
#import "LINetworkOperation.h"

@implementation PodViewController

- (id)init {
  self = [super init];
  if (self) {
    _podDataCenter = [[PodDataCenter alloc] init];
    _podDataCenter.delegate = self;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Add Profile Button
  UIButton *profile = [UIButton buttonWithType:UIButtonTypeCustom];
  profile.frame = CGRectMake(0, 0, 44, 32);
  [profile setTitle:@"Profile" forState:UIControlStateNormal];
//  [back setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 0)];
  [profile setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
  profile.titleLabel.font = [UIFont boldSystemFontOfSize:10];
  UIImage *profileImage = [[UIImage imageNamed:@"navigationbar_button_standard.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];  
  [profile setBackgroundImage:profileImage forState:UIControlStateNormal];  
  [profile addTarget:self action:@selector(profile) forControlEvents:UIControlEventTouchUpInside];  
  UIBarButtonItem *profileButton = [[[UIBarButtonItem alloc] initWithCustomView:profile] autorelease];
  self.navigationItem.leftBarButtonItem = profileButton;
  
  // Add Check-In Button
  UIButton *checkin = [UIButton buttonWithType:UIButtonTypeCustom];
  checkin.frame = CGRectMake(0, 0, 60, 32);
  [checkin setTitle:@"Check-In" forState:UIControlStateNormal];
  //  [back setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 0)];
  [checkin setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
  checkin.titleLabel.font = [UIFont boldSystemFontOfSize:10];
  UIImage *checkinImage = [[UIImage imageNamed:@"navigationbar_button_standard.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];  
  [checkin setBackgroundImage:checkinImage forState:UIControlStateNormal];  
  [checkin addTarget:self action:@selector(checkin) forControlEvents:UIControlEventTouchUpInside];  
  UIBarButtonItem *checkinButton = [[[UIBarButtonItem alloc] initWithCustomView:checkin] autorelease];
  self.navigationItem.rightBarButtonItem = checkinButton;
  
  // Nav Title
  _navTitleLabel.text = @"Places";
  
  // Table
  CGRect tableFrame = CGRectMake(0, 0, CARD_WIDTH, CARD_HEIGHT_WITH_NAV);
  [self setupTableViewWithFrame:tableFrame andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
  
  // Pull Refresh
  [self setupPullRefresh];
  
//  UIBarButtonItem *post = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(post)];
//  self.navigationItem.rightBarButtonItem = post;
//  [post release];
}

// Test post
- (void)post {
  NSString *baseURLString = [NSString stringWithFormat:@"%@/%@/moogle/test", MOOGLE_BASE_URL, API_VERSION];
  
  LINetworkOperation *op = [[LINetworkOperation alloc] initWithURL:[NSURL URLWithString:baseURLString]];
  op.delegate = self;
  op.requestMethod = POST;
  op.isFormData = YES;
  
  [op addRequestParam:@"comment" value:@"hello world!"];
  [op addRequestParam:@"timestamp" value:[NSString stringWithFormat:@"%0.0f", [[NSDate date] timeIntervalSince1970]]];
  [op addRequestParam:@"photo" value:[UIImage imageNamed:@"Icon.png"]];
  
  [[LINetworkQueue sharedQueue] addOperation:op];
}

- (void)networkOperationDidFinish:(LINetworkOperation *)operation {
  
}

#pragma mark -
#pragma mark TableView
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  Pod *pod = [self.fetchedResultsController objectAtIndexPath:indexPath];
  return [PodCell variableRowHeightWithPod:pod];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  Pod *pod = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  FeedViewController *fvc = [[FeedViewController alloc] init];
  fvc.pod = pod;
  [self.navigationController pushViewController:fvc animated:YES];
  [fvc release];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  PodCell *cell = nil;
  NSString *reuseIdentifier = [NSString stringWithFormat:@"%@_TableViewCell_%d", [self class], indexPath.section];
  
  cell = (PodCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if(cell == nil) { 
    cell = [[[PodCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
  }
  
  Pod *pod = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  [cell fillCellWithPod:pod];
  
  return cell;
}

#pragma mark -
#pragma mark CardViewController
- (void)reloadCardController {
  [super reloadCardController];
  [_podDataCenter loadPodsFromFixture];
}

- (void)unloadCardController {
  [super unloadCardController];
}

#pragma mark -
#pragma mark MoogleDataCenterDelegate
- (void)dataCenterDidFinish:(LINetworkOperation *)operation {
  [self resetFetchedResultsController];
  [self.tableView reloadData];
  [self dataSourceDidLoad];
}

- (void)dataCenterDidFail:(LINetworkOperation *)operation {
  [self resetFetchedResultsController];
  [self.tableView reloadData];
  [self dataSourceDidLoad];
}

#pragma mark -
#pragma mark FetchRequest
- (NSFetchRequest *)getFetchRequest {
  return [_podDataCenter getPodsFetchRequest];
}

- (void)dealloc {
  RELEASE_SAFELY(_podDataCenter);
  [super dealloc];
}

@end