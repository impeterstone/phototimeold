//
//  AlbumCell.h
//  Photomunk
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSCell.h"
#import "Album.h"
#import "Album+Serialize.h"
#import "PSURLCacheImageView.h"
#import "PSImageViewDelegate.h"

@interface AlbumCell : PSCell <PSImageViewDelegate> {
  PSURLCacheImageView *_photoView;
  UIImageView *_overlayView;
  UIView *_captionView;
  UIView *_ribbonView;
  
  UILabel *_nameLabel;
  UILabel *_captionLabel;
  UILabel *_fromLabel;
  UILabel *_locationLabel;
  UILabel *_countLabel;
  
  CGFloat _photoWidth;
  CGFloat _photoHeight;
  
  Album *_album;
  BOOL _isAnimating;
}

- (void)loadPhoto;
- (void)animateImage;

@end
