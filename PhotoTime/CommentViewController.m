//
//  CommentViewController.m
//  PhotoTime
//
//  Created by Peter Shih on 5/24/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import "CommentViewController.h"
#import "CommentCell.h"
#import "Photo.h"

@implementation CommentViewController

@synthesize photo = _photo;

- (id)init {
  self = [super init];
  if (self) {
  }
  return self;
}

- (void)loadView {
  [super loadView];  
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
}

- (void)loadComments {
  NSArray *filteredArray = nil;
  filteredArray = [_photo.comments allObjects];
  [self.items addObject:filteredArray];
  [self.tableView reloadData];
}

- (void)unloadComments {
  [self.items removeAllObjects];
  [self.tableView reloadData];
}

#pragma mark - State Machine
- (BOOL)dataIsAvailable {
  return YES; // override
}

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
#pragma mark Table
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  Comment *comment = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  return [CommentCell rowHeightForObject:comment forInterfaceOrientation:[self interfaceOrientation]];
}

- (void)tableView:(UITableView *)tableView configureCell:(id)cell atIndexPath:(NSIndexPath *)indexPath {
  Comment *comment = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  
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

- (void)dealloc {
  [super dealloc];
}

@end
