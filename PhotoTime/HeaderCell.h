//
//  HeaderCell.h
//  PhotoTime
//
//  Created by Peter Shih on 4/26/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSView.h"
#import "Photo.h"
#import "Photo+Serialize.h"

@interface HeaderCell : PSView {
  UILabel *_userNameLabel;
  UILabel *_timestampLabel;
}

- (void)fillCellWithObject:(id)object;

@end
