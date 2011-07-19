//
//  PhotoViewController.h
//  Moogle
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardCoreDataTableViewController.h"
#import "PhotoCellDelegate.h"

@class Album;
@class PSZoomView;
@class PSRollupView;

@interface PhotoViewController : CardCoreDataTableViewController <PhotoCellDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
  Album *_album;
  PSRollupView *_taggedFriendsView;
  PSZoomView *_zoomView;
  NSString *_sortKey;
  UIImage *_uploadImage;
}

@property (nonatomic, assign) Album *album;
@property (nonatomic, retain) NSString *sortKey;

- (void)getTaggedFriends;

@end
