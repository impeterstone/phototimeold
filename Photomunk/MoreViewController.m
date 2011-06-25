//
//  MoreViewController.m
//  Photomunk
//
//  Created by Peter Shih on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MoreViewController.h"

@implementation MoreViewController

- (id)init {
  self = [super init];
  if (self) {
  }
  return self;
}

- (void)loadView {
  [super loadView];
  
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStyleGrouped andSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
  
  [self.items addObject:[NSArray arrayWithObject:@"test"]];
}

- (void)dealloc {
  [super dealloc];
}

@end
