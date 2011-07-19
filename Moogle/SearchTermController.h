//
//  SearchTermController.h
//  Moogle
//
//  Created by Peter Shih on 7/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardTableViewController.h"
#import "SearchTermDelegate.h"

@interface SearchTermController : CardTableViewController {
  UIView *_noResultsView;
  id <SearchTermDelegate> _delegate;
}

@property (nonatomic, assign) id <SearchTermDelegate> delegate;

- (void)searchWithTerm:(NSString *)term;
- (void)setupNoResultsView;

@end
