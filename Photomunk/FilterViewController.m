//
//  FilterViewController.m
//  Photomunk
//
//  Created by Peter Shih on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FilterViewController.h"


@implementation FilterViewController

#pragma mark - Init
- (id)init {
  self = [super init];
  if (self) {
  }
  return self;
}

- (void)dealloc {
  [super dealloc];
}

#pragma mark - View
- (void)loadView {
  [super loadView];
  
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  [self addButtonWithTitle:@"Cancel" withTarget:self action:@selector(dismissModalViewControllerAnimated:) isLeft:NO];
  
  // Setup Filters
  [self setupFilters];
  
  [self.tableView reloadData];
  [self updateState];
}

- (void)setupFilters {
  
}

#pragma mark - Table

@end
