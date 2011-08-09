//
//  AlbumViewController.h
//  PhotoTime
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSCoreDataTableViewController.h"


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
  AlbumTypeClassmates = 9,
  AlbumTypeSearch = 10
} AlbumType;

@interface AlbumViewController : PSCoreDataTableViewController {
  AlbumType _albumType;
}

@property (nonatomic, assign) AlbumType albumType;

- (void)save;

@end
