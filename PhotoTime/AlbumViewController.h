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
  AlbumTypeWall = 4,
  AlbumTypeSearch = 5,
  AlbumTypeCustom = 6
} AlbumType;

@interface AlbumViewController : PSCoreDataTableViewController {
  AlbumType _albumType;
  NSDictionary *_albumConfig;
  NSString *_albumTitle;
}

@property (nonatomic, assign) AlbumType albumType;
@property (nonatomic, retain) NSDictionary *albumConfig;
@property (nonatomic, retain) NSString *albumTitle;

- (void)save;

@end
