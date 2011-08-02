//
//  CardCoreDataTableViewController.h
//  Orca
//
//  Created by Peter Shih on 2/16/11.
//  Copyright 2011 LinkedIn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "CardTableViewController.h"
#import "PSCoreDataStack.h"

typedef enum {
  FetchTypeCold = 0,
  FetchTypeRefresh = 1,
  FetchTypeLoadMore = 2
} FetchType;

@interface CardCoreDataTableViewController : CardTableViewController <NSFetchedResultsControllerDelegate> {  
  NSManagedObjectContext *_context;
  NSFetchedResultsController * _fetchedResultsController;
  NSString * _sectionNameKeyPathForFetchedResultsController;
  NSTimer *_searchTimer;
  NSPredicate *_searchPredicate;
  NSInteger _fetchLimit;
  NSInteger _fetchTotal;
  id _frcDelegate;
}

@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsController;
@property (nonatomic, retain) NSString * sectionNameKeyPathForFetchedResultsController;


- (void)tableView:(UITableView *)tableView configureCell:(id)cell atIndexPath:(NSIndexPath *)indexPath;

- (void)delayedFilterContentWithTimer:(NSTimer *)timer;

- (void)resetFetchedResultsController;
- (void)executeFetch:(FetchType)fetchType;
- (void)executeFetchOnMainThread;
- (void)executeSearchOnMainThread;
- (NSFetchRequest *)getFetchRequest;
- (void)coreDataDidReset;

@end
