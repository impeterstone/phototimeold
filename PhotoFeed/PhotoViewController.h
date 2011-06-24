//
//  PhotoViewController.h
//  PhotoFeed
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardCoreDataTableViewController.h"
#import "PhotoCellDelegate.h"

@class PhotoDataCenter;
@class Album;
@class PSZoomView;
@class PSRollupView;

@interface PhotoViewController : CardCoreDataTableViewController <PhotoCellDelegate> {
  PhotoDataCenter *_photoDataCenter;
  Album *_album;
  PSRollupView *_taggedFriendsView;
  PSZoomView *_zoomView;
}

@property (nonatomic, assign) Album *album;

- (void)getTaggedFriends;
- (void)zoomPhotoForCell:(id)cell atIndexPath:(NSIndexPath *)indexPath;

@end
