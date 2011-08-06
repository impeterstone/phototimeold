//
//  ShareCell.m
//  PhotoTime
//
//  Created by Peter Shih on 3/30/11.
//  Copyright 2011 Seven Minute Labs, Inc.. All rights reserved.
//

#import "ShareCell.h"


@implementation ShareCell

- (void)prepareForReuse {
  [super prepareForReuse];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  self.imageView.layer.cornerRadius = 4.0;
  self.imageView.layer.masksToBounds = YES;
  self.imageView.top = 6;
  self.imageView.left = 6;
  self.imageView.width = 32;
  self.imageView.height = 32;
  
  self.textLabel.left = self.imageView.right + 6;
}

+ (PSCellType)cellType {
  return PSCellTypeGrouped;
}

+ (CGFloat)rowHeight {
  return 44.0;
}

- (void)fillCellWithObject:(id)object {
  NSString *service = object;
  UIImage *serviceIcon = [UIImage imageNamed:[NSString stringWithFormat:@"share_%@.png", service]];
  
  self.imageView.image = serviceIcon;
  self.textLabel.text = [NSString stringWithFormat:@"Share via %@", [service capitalizedString]];
}

@end
