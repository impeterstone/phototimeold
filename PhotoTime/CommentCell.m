//
//  CommentCell.m
//  PhotoTime
//
//  Created by Peter Shih on 5/25/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import "CommentCell.h"
#import "Comment.h"

@implementation CommentCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    _nameLabel = [[UILabel alloc] init];
    _messageLabel = [[UILabel alloc] init];
    _timestampLabel = [[UILabel alloc] init];
    
    _nameLabel.backgroundColor = [UIColor clearColor];
    _messageLabel.backgroundColor = [UIColor clearColor];
    _timestampLabel.backgroundColor = [UIColor clearColor];
    
    _nameLabel.font = TITLE_FONT;
    _messageLabel.font = NORMAL_FONT;
    _timestampLabel.font = SUBTITLE_FONT;
    
    _nameLabel.textColor = FB_COLOR_DARK_GRAY_BLUE;
    _messageLabel.textColor = [UIColor darkTextColor];
    _timestampLabel.textColor = [UIColor darkTextColor];
    
    _timestampLabel.textAlignment = UITextAlignmentRight;
    
    _messageLabel.lineBreakMode = UILineBreakModeWordWrap;
    
    _messageLabel.numberOfLines = 0;
    
    // Add to contentView
    [self.contentView addSubview:_nameLabel];
    [self.contentView addSubview:_messageLabel];
    [self.contentView addSubview:_timestampLabel];
  }
  return self;
}

- (void)prepareForReuse {
  [super prepareForReuse];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  CGFloat top = MARGIN_Y;
  CGFloat left = MARGIN_X + IMAGE_OFFSET;
  CGFloat textWidth = self.contentView.width - MARGIN_X * 2 - IMAGE_OFFSET;
  CGSize desiredSize = CGSizeZero;
  
  // Name/Timestamp
  desiredSize = [UILabel sizeForText:_timestampLabel.text width:textWidth font:_timestampLabel.font numberOfLines:1 lineBreakMode:_timestampLabel.lineBreakMode];
  _timestampLabel.width = desiredSize.width;
  _timestampLabel.height = desiredSize.height;
  _timestampLabel.top = top;
  _timestampLabel.left = self.contentView.width - _timestampLabel.width - MARGIN_X;
  
  desiredSize = [UILabel sizeForText:_nameLabel.text width:(textWidth - _timestampLabel.width - MARGIN_X) font:_nameLabel.font numberOfLines:_nameLabel.numberOfLines lineBreakMode:_nameLabel.lineBreakMode];
  _nameLabel.top = top;
  _nameLabel.left = left;
  _nameLabel.width = desiredSize.width;
  _nameLabel.height = desiredSize.height;
  
  top = _nameLabel.bottom;
  
  // Message
  desiredSize = [UILabel sizeForText:_messageLabel.text width:textWidth font:_messageLabel.font numberOfLines:_messageLabel.numberOfLines lineBreakMode:_messageLabel.lineBreakMode];
  _messageLabel.top = top;
  _messageLabel.left = left;
  _messageLabel.width = desiredSize.width;
  _messageLabel.height = desiredSize.height;
  
}

+ (CGFloat)rowHeightForObject:(id)object forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  Comment *comment = (Comment *)object;
  
  CGSize desiredSize = CGSizeZero;
  CGFloat textWidth = [[self class] rowWidthForInterfaceOrientation:interfaceOrientation] - IMAGE_OFFSET - MARGIN_X * 2; // minus image
  CGFloat desiredHeight = 0.0;
  
  desiredHeight += MARGIN_Y;
  
  // Name/Timestamp
  desiredSize = [UILabel sizeForText:comment.fromName width:textWidth font:TITLE_FONT numberOfLines:1 lineBreakMode:UILineBreakModeTailTruncation];
  desiredHeight += desiredSize.height;
  
  // Message
  desiredSize = [UILabel sizeForText:comment.message width:textWidth font:NORMAL_FONT numberOfLines:0 lineBreakMode:UILineBreakModeWordWrap];
  desiredHeight += desiredSize.height;
  
  desiredHeight += MARGIN_Y;
  
  if (desiredHeight <= IMAGE_OFFSET) {
    desiredHeight = IMAGE_OFFSET;
  }
  
  return desiredHeight;
}

- (void)fillCellWithObject:(id)object {
  Comment *comment = (Comment *)object;
  
  _psImageView.urlPath = [NSString stringWithFormat:@"%@/%@/picture?type=square", FB_GRAPH ,comment.fromId];
  [_psImageView loadImageAndDownload:YES];
  
  _nameLabel.text = comment.fromName;
  _messageLabel.text = comment.message;
  _timestampLabel.text = [NSDate stringForDisplayFromDate:comment.timestamp];
}

- (void)dealloc {
  RELEASE_SAFELY(_nameLabel);
  RELEASE_SAFELY(_messageLabel);
  RELEASE_SAFELY(_timestampLabel);
  [super dealloc];
}

@end
