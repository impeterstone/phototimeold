//
//  CardTableViewController.h
//  Photomunk
//
//  Created by Peter Shih on 2/14/11.
//  Copyright 2011 LinkedIn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardViewController.h"
#import "HeaderTabView.h"
#import "EGORefreshTableHeaderView.h"

@interface CardTableViewController : CardViewController <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate, UISearchBarDelegate, EGORefreshTableHeaderDelegate> {
  UITableView *_tableView;
  NSMutableArray *_sectionTitles;
  NSMutableArray *_items;
  NSMutableArray *_searchItems;
  NSArray *_visibleCells;
  NSArray *_visibleIndexPaths;
  
  UISearchBar *_searchBar;
  EGORefreshTableHeaderView *_refreshHeaderView;
  UIView *_loadMoreView;
  UIButton *_loadMoreButton;
  UIActivityIndicatorView *_loadMoreActivity;
  BOOL _reloading;
  BOOL _loadingMore;
  BOOL _hasMore;
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, retain) NSMutableArray *searchItems;

- (void)setupTableViewWithFrame:(CGRect)frame andStyle:(UITableViewStyle)style andSeparatorStyle:(UITableViewCellSeparatorStyle)separatorStyle;
- (void)setupPullRefresh;
- (void)setupTableHeader;
- (void)setupTableFooter;
- (void)setupHeaderWithView:(UIView *)headerView;
- (void)setupFooterWithView:(UIView *)footerView;
- (void)setupLoadMoreView;
- (void)setupSearchDisplayControllerWithScopeButtonTitles:(NSArray *)scopeButtonTitles;
- (void)setupSearchDisplayControllerWithScopeButtonTitles:(NSArray *)scopeButtonTitles andPlaceholder:(NSString *)placeholder;

- (void)showLoadMoreView;
- (void)hideLoadMoreView;

- (void)updateLoadMore;
- (void)loadMore;

- (void)loadImagesForOnScreenRows;

- (void)scrollEndedTrigger;

@end
