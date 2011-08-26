//
//  CommentView.m
//  PhotoTime
//
//  Created by Peter Shih on 8/8/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import "CommentView.h"
#import "Comment.h"
#import "UIImage+SML.h"

@implementation CommentView

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _frame = [[UIImageView alloc] initWithImage:[UIImage stretchableImageNamed:@"bg_photo_frame.png" withLeftCapWidth:21 topCapWidth:5]];
    _pictureView = [[PSURLCacheImageView alloc] initWithFrame:CGRectZero];
    
    _bubble = [[UIImageView alloc] initWithImage:[UIImage stretchableImageNamed:@"bubble.png" withLeftCapWidth:15 topCapWidth:25]]; 
    _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _messageLabel.backgroundColor = [UIColor clearColor];
    _messageLabel.font = SUBTITLE_FONT;
    _messageLabel.textColor = [UIColor darkTextColor];
    _messageLabel.numberOfLines = 0;
    
    [self addSubview:_frame];
    [self addSubview:_pictureView];
    [self addSubview:_bubble];
    [self addSubview:_messageLabel];
  }
  return self;
}

- (void)dealloc {
  RELEASE_SAFELY(_frame);
  RELEASE_SAFELY(_bubble);
  RELEASE_SAFELY(_pictureView);
  RELEASE_SAFELY(_messageLabel);
  [super dealloc];
}

#pragma mark - View
- (void)layoutSubviews {
  [super layoutSubviews];
  
  CGFloat top = 10;
  CGFloat left = 5;
  CGFloat textWidth = self.width - 10;
//  CGSize desiredSize = CGSizeZero;
  
  // Picture
  _frame.frame = CGRectMake(left, top, 60, 60);
  _pictureView.left = left + 5;
  _pictureView.top = top + 5;
  _pictureView.width = 50;
  _pictureView.height = 50;
  
  left = _pictureView.right + 5;
  textWidth = textWidth - _pictureView.width - 5;
  
  // Comment
  _bubble.frame = CGRectMake(left, top + 2, textWidth, 56);
  
  _messageLabel.left = left + 15;
  _messageLabel.top = top + 5;
  _messageLabel.width = textWidth - 15 - 5;
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
