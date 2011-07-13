//
//  AlbumViewController.h
//  Moogle
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardCoreDataTableViewController.h"
#import "SearchTermDelegate.h"

typedef enum {
  AlbumTypeMe = 0,
  AlbumTypeFriends = 1,
  AlbumTypeMobile = 2,
  AlbumTypeProfile = 3,
  AlbumTypeWall = 4,
  AlbumTypeFavorites = 5,
  AlbumTypeHistory = 6,
  AlbumTypeBoys = 7,
  AlbumTypeGirls = 8,
  AlbumTypeClassmates = 9
} AlbumType;

@class SearchTermController;

@interface AlbumViewController : CardCoreDataTableViewController <UITextFieldDelegate, SearchTermDelegate> {
  AlbumType _albumType;
  PSTextField *_searchField;
  UIBarButtonItem *_filterButton;
  UIBarButtonItem *_cancelButton;
  SearchTermController *_searchTermController;
}

@property (nonatomic, assign) AlbumType albumType;

- (void)filter;
- (void)search;
- (void)cancelSearch;
- (void)searchWithText:(NSString *)searchText;

@end
