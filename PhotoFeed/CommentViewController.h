//
//  CommentViewController.h
//  PhotoFeed
//
//  Created by Peter Shih on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardCoreDataTableViewController.h"
#import "ComposeDelegate.h"

@class CommentDataCenter;
@class Photo;

@interface CommentViewController : CardCoreDataTableViewController <ComposeDelegate> {
  CommentDataCenter *_commentDataCenter;
  Photo *_photo;
  UIView *_commentHeaderView;
  UIImage *_photoImage;
  UIImageView *_photoHeaderView;
  
  CGFloat _headerHeight;
  CGFloat _headerOffset;
  CGFloat _photoHeight;
  BOOL _isHeaderExpanded;
}

@property (nonatomic, assign) Photo *photo;
@property (nonatomic, assign) UIImage *photoImage;

- (void)newComment;
- (void)setupHeader;
- (void)setupFooter;
- (void)toggleHeader:(UITapGestureRecognizer *)gestureRecognizer;

@end
