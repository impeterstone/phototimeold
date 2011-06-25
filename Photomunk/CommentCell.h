//
//  CommentCell.h
//  Photomunk
//
//  Created by Peter Shih on 5/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSImageCell.h"

@interface CommentCell : PSImageCell {
  UILabel *_nameLabel;
  UILabel *_messageLabel;
  UILabel *_timestampLabel;
}

@end
