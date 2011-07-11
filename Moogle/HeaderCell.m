//
//  HeaderCell.m
//  Moogle
//
//  Created by Peter Shih on 4/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HeaderCell.h"

#define MARGIN_X 5.0

#define NAME_FONT [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0]
#define SMALL_ITALIC_FONT [UIFont fontWithName:@"HelveticaNeue-Italic" size:12.0]

static UIImage *_bgImage = nil;

@implementation HeaderCell

+ (void)initialize {
  _bgImage = [[UIImage imageNamed:@"bg-table-header.png"] retain];
}

- (id)initWithFrame:(CGRect)frame{
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor colorWithPatternImage:_bgImage];
    
    _userNameLabel = [[UILabel alloc] init];
    _timestampLabel = [[UILabel alloc] init];
    
    _userNameLabel.backgroundColor = [UIColor clearColor];
    _timestampLabel.backgroundColor = [UIColor clearColor];
    
    _userNameLabel.font = NAME_FONT;
    _userNameLabel.textColor = [UIColor whiteColor];
    
    _timestampLabel.font = SMALL_ITALIC_FONT;
    _timestampLabel.textColor = FB_COLOR_VERY_LIGHT_BLUE;
    
    _timestampLabel.textAlignment = UITextAlignmentRight;
    
    [self addSubview:_userNameLabel];
    [self addSubview:_timestampLabel];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  CGFloat top = 0;
  CGFloat left = MARGIN_X;
  CGFloat textWidth = self.width - MARGIN_X * 2;
  CGSize desiredSize = CGSizeZero;
  
  desiredSize = [UILabel sizeForText:_timestampLabel.text width:textWidth font:_timestampLabel.font numberOfLines:1 lineBreakMode:_timestampLabel.lineBreakMode];
  _timestampLabel.width = desiredSize.width;
  _timestampLabel.height = self.height;
  _timestampLabel.top = top;
  _timestampLabel.left = self.width - _timestampLabel.width - MARGIN_X;
  
  desiredSize = [UILabel sizeForText:_userNameLabel.text width:(textWidth - _timestampLabel.width - MARGIN_X) font:_userNameLabel.font numberOfLines:1 lineBreakMode:_userNameLabel.lineBreakMode];
  _userNameLabel.width = desiredSize.width;
  _userNameLabel.height = self.height;
  _userNameLabel.top = top;
  _userNameLabel.left = left;
}

- (void)fillCellWithObject:(id)object {
  Photo *photo = (Photo *)object;
  
  _userNameLabel.text = photo.fromName;
  _timestampLabel.text = [NSDate stringForDisplayFromDate:photo.timestamp];
}

- (void)dealloc {
  RELEASE_SAFELY(_timestampLabel);
  RELEASE_SAFELY(_userNameLabel);
  [super dealloc];
}

@end
