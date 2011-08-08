//
//  CommentView.m
//  PhotoTime
//
//  Created by Peter Shih on 8/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CommentView.h"
#import "Comment.h"

@implementation CommentView

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _pictureView = [[PSURLCacheImageView alloc] initWithFrame:CGRectZero];
    _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    
    _messageLabel.backgroundColor = [UIColor clearColor];
    _messageLabel.font = SUBTITLE_FONT;
    _messageLabel.textColor = [UIColor darkTextColor];
    _messageLabel.numberOfLines = 0;
    
    [self addSubview:_pictureView];
    [self addSubview:_messageLabel];
  }
  return self;
}

- (void)dealloc {
  RELEASE_SAFELY(_pictureView);
  RELEASE_SAFELY(_messageLabel);
  [super dealloc];
}

#pragma mark - View
- (void)layoutSubviews {
  [super layoutSubviews];
  
  CGFloat top = 5;
  CGFloat left = 5;
  CGFloat textWidth = self.width - 10;
//  CGSize desiredSize = CGSizeZero;
  
  // Picture
  _pictureView.left = left;
  _pictureView.top = top + 5;
  _pictureView.width = 40;
  _pictureView.height = 40;
  
  left = _pictureView.right + 5;
  textWidth = textWidth - _pictureView.width - 5;
  
  // Comment
//  desiredSize = [UILabel sizeForText:_messageLabel.text width:textWidth font:_messageLabel.font numberOfLines:_messageLabel.numberOfLines lineBreakMode:_messageLabel.lineBreakMode];
  _messageLabel.left = left;
  _messageLabel.top = top;
  _messageLabel.width = textWidth;
  _messageLabel.height = 50;
}

#pragma mark - Load
- (void)loadCommentsWithObject:(id)object {
  Comment *comment = (Comment *)object;
  _messageLabel.text = comment.message;
  _pictureView.urlPath = [NSString stringWithFormat:@"%@/%@/picture?type=square", FB_GRAPH ,comment.fromId];
  [_pictureView loadImageAndDownload:YES];
}

@end
