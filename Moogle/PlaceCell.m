//
//  PlaceCell.m
//  Moogle
//
//  Created by Peter Shih on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PlaceCell.h"

#define NAME_FONT_SIZE 14.0
#define CELL_FONT_SIZE 12.0
#define TIMESTAMP_FONT_SIZE 12.0
#define ADDRESS_FONT_SIZE 12.0
#define UNREAD_WIDTH 13.0

static UIImage *_unreadImage = nil;

@implementation PlaceCell

+ (void)initialize {
  _unreadImage = [[UIImage imageNamed:@"unread.png"] retain];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
  }
  return self;
}

// Optimized cell rendering
- (void)drawRect:(CGRect)rect {
  [super drawRect:rect];

  [self drawContentView:rect];
}

- (void)drawContentView:(CGRect)r {
  [super drawContentView:r];
  
  CGFloat top = MARGIN_Y;
  CGFloat left =  MARGIN_X;
  CGFloat width = self.bounds.size.width - left - MARGIN_X;
  CGRect contentRect = CGRectMake(left, top, width, r.size.height);
  CGSize drawnSize = CGSizeZero;
  
  // Image View
  
  // Unread indicator
  if (![_place.isRead boolValue]) {
    [_unreadImage drawAtPoint:CGPointMake(left, floor(self.bounds.size.height / 2) - floor(_unreadImage.size.height / 2))];
  }
  
  _moogleFrameView.left = left + _unreadImage.size.width;
  _moogleImageView.left = left + _unreadImage.size.width + 10;
  
  left = _moogleFrameView.right;
  width = self.bounds.size.width - left - MARGIN_X;
  contentRect = CGRectMake(left, top, width, r.size.height);
  
  [[UIColor blackColor] set];
  
  if ([[_place.timestamp humanIntervalSinceNow] length] > 0) {
    drawnSize = [[_place.timestamp humanIntervalSinceNow] drawInRect:contentRect withFont:[UIFont fontWithName:@"HelveticaNeue-Italic" size:TIMESTAMP_FONT_SIZE] lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentRight];
    
    contentRect = CGRectMake(left, top, width - drawnSize.width - MARGIN_X, r.size.height);
  }
  
  if ([_place.name length] > 0) {
    drawnSize = [_place.name drawInRect:contentRect withFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:NAME_FONT_SIZE] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentLeft];
    
    top += drawnSize.height;
    contentRect.origin.y = top;
  }
  
  contentRect = CGRectMake(left, top, width, r.size.height);
  
  if ([_place.address length] > 0) {
    drawnSize = [_place.address drawInRect:contentRect withFont:[UIFont fontWithName:@"HelveticaNeue-Italic" size:ADDRESS_FONT_SIZE] lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentLeft];
    
    top += drawnSize.height;
    contentRect.origin.y = top;
  }
  
  // Last Activity
  NSString *lastActivity = nil;
  if ([_place.kupoType integerValue] == 0) {
    lastActivity = [NSString stringWithFormat:@"%@ checked in here", _place.authorName];
  } else if ([_place.kupoType integerValue] == 1) {
    if ([_place.hasPhoto boolValue]) {
      if ([_place.hasVideo boolValue]) {
        lastActivity = [NSString stringWithFormat:@"%@ shared a video", _place.authorName];
      } else {
        lastActivity = [NSString stringWithFormat:@"%@ shared a photo", _place.authorName];
      }
    } else {
      lastActivity = [NSString stringWithFormat:@"%@ posted a comment", _place.authorName];
    }
  }
  
  if ([lastActivity length] > 0) {
    drawnSize = [lastActivity drawInRect:contentRect withFont:[UIFont fontWithName:@"HelveticaNeue" size:CELL_FONT_SIZE] lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentLeft];
    
    top += drawnSize.height;
    contentRect.origin.y = top;
  }
  
  // Summary
  NSString *summary = [NSString stringWithFormat:@"Friends: %@", _place.friendFirstNames];
  if ([summary length] > 0) {
    drawnSize = [summary drawInRect:contentRect withFont:[UIFont fontWithName:@"HelveticaNeue" size:CELL_FONT_SIZE] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentLeft];
    
    top += drawnSize.height;
    contentRect.origin.y = top;
  }
  
  // Activity Count
  NSString *activity = [NSString stringWithFormat:@"%@ Kupos", _place.activityCount];
  if ([activity length] > 0) {
    drawnSize = [activity drawInRect:contentRect withFont:[UIFont fontWithName:@"HelveticaNeue" size:CELL_FONT_SIZE] lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentLeft];
    
    top += drawnSize.height;
    contentRect.origin.y = top;
  }
}
    
- (void)layoutSubviews {
  [super layoutSubviews];

}

- (void)prepareForReuse {
  [super prepareForReuse];
  [_moogleImageView unloadImage];
}

#pragma mark -
#pragma mark Fill and Height
+ (CGFloat)rowHeightForObject:(id)object {
  Place *place = (Place *)object;
  
  CGFloat top = MARGIN_Y;
  CGFloat left = MARGIN_X + _unreadImage.size.width + 60; // image + unread dot
  CGFloat width = [[self class] rowWidth] - left - MARGIN_X;
  CGSize constrainedSize = CGSizeZero;
  CGSize size = CGSizeZero;
  
  CGFloat desiredHeight = top;

  constrainedSize = CGSizeMake(width, 300);
  
  size = [[place.timestamp humanIntervalSinceNow] sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Italic" size:TIMESTAMP_FONT_SIZE] constrainedToSize:constrainedSize lineBreakMode:UILineBreakModeTailTruncation];
  
  constrainedSize = CGSizeMake(width - size.width - MARGIN_X, 300);
  
  size = [place.name sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:NAME_FONT_SIZE] constrainedToSize:constrainedSize lineBreakMode:UILineBreakModeWordWrap];
  
  desiredHeight += size.height;
  
  constrainedSize = CGSizeMake(width, 300);
  
  size = [place.address sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Italic" size:ADDRESS_FONT_SIZE] constrainedToSize:constrainedSize lineBreakMode:UILineBreakModeTailTruncation];
  
  desiredHeight += size.height;
  
  // Last Activity
  NSString *lastActivity = nil;
  if ([place.kupoType integerValue] == 0) {
    lastActivity = [NSString stringWithFormat:@"%@ checked in here", place.authorName];
  } else if ([place.kupoType integerValue] == 1) {
    if ([place.hasPhoto boolValue]) {
      if ([place.hasVideo boolValue]) {
        lastActivity = [NSString stringWithFormat:@"%@ shared a video", place.authorName];
      } else {
        lastActivity = [NSString stringWithFormat:@"%@ shared a photo", place.authorName];
      }
    } else {
      lastActivity = [NSString stringWithFormat:@"%@ posted a comment", place.authorName];
    }
  }
  
  size = [lastActivity sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:CELL_FONT_SIZE] constrainedToSize:constrainedSize lineBreakMode:UILineBreakModeTailTruncation];
  
  desiredHeight += size.height;
  
  size = [[NSString stringWithFormat:@"Friends: %@", place.friendFirstNames] sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:CELL_FONT_SIZE] constrainedToSize:constrainedSize lineBreakMode:UILineBreakModeWordWrap];
  
  desiredHeight += size.height;
  
  size = [[NSString stringWithFormat:@"%@ Kupos", place.activityCount] sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:CELL_FONT_SIZE] constrainedToSize:constrainedSize lineBreakMode:UILineBreakModeTailTruncation];
  
  desiredHeight += size.height;
  
  desiredHeight += MARGIN_Y;
  
//  NSLog(@"desired height calc: %f", desiredHeight);
  
  return desiredHeight;
}

- (void)fillCellWithObject:(id)object {
  Place *place = (Place *)object;
  _place = [place retain];
  
//  _moogleImageView.urlPath = place.pictureUrl;
  _moogleImageView.urlPath = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=square", place.authorId];
  
}

+ (MoogleCellType)cellType {
  return MoogleCellTypePlain;
}

- (void)dealloc {
  RELEASE_SAFELY(_place);
  [super dealloc];
}

@end
