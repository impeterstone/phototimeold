//
//  AlbumViewController.h
//  Photomunk
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardCoreDataTableViewController.h"

typedef enum {
  AlbumTypeMe = 0,
  AlbumTypeFriends = 1,
  AlbumTypeMobile = 2,
  AlbumTypeProfile = 3,
  AlbumTypeWall = 4,
  AlbumTypeFavorites = 5,
  AlbumTypeHistory = 6,
  AlbumTypeTimeline = 7
} AlbumType;

@interface AlbumViewController : CardCoreDataTableViewController {
  AlbumType _albumType;
}

@property (nonatomic, assign) AlbumType albumType;

- (void)search;
- (void)logout;

@end
