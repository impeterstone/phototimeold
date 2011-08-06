//
//  PhotoCell.h
//  PhotoTime
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSCell.h"
#import "Photo.h"
#import "PhotoCellDelegate.h"
#import "PSURLCacheImageView.h"

@class PSRollupView;

@interface PhotoCell : PSCell {
  PSURLCacheImageView *_photoView; // optional
  UILabel *_captionLabel;
  UIImageView *_overlayView;
  UIButton *_commentButton;
  UIButton *_likeButton;
  PSRollupView *_taggedFriendsView;
  
  CGFloat _photoWidth;
  CGFloat _photoHeight;
  
  Photo *_photo;
  id <PhotoCellDelegate> _delegate;
}

@property (nonatomic, assign) PSURLCacheImageView *photoView;
@property (nonatomic, assign) UILabel *captionLabel;
@property (nonatomic, assign) id <PhotoCellDelegate> delegate;

- (void)pinchZoom:(UIPinchGestureRecognizer *)gesture;
- (void)triggerPinch;
- (void)loadPhoto;
- (void)showComments;
- (void)addRemoveLike;

@end
