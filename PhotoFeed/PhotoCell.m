//
//  PhotoCell.m
//  PhotoFeed
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PhotoCell.h"
#import "UIImage+ScalingAndCropping.h"
#import "Comment.h"

#define CAPTION_FONT [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0]
#define COMMENT_FONT [UIFont fontWithName:@"HelveticaNeue" size:12.0]

#define COMMENT_HEIGHT 31.0
#define DISCLOSURE_WIDTH 10.0

static UIImage *_commentBackground = nil;
static UIImage *_disclosureIndicator = nil;
static UIImage *_commentIcon = nil;

@implementation PhotoCell

@synthesize photoView = _photoView;
@synthesize captionLabel = _captionLabel;
@synthesize delegate = _delegate;

+ (void)initialize {
  _commentBackground = [[UIImage imageNamed:@"comment_cell_background.png"] retain];
  _disclosureIndicator = [[UIImage imageNamed:@"disclosure_indicator_white.png"] retain];
  _commentIcon = [[UIImage imageNamed:@"comment.png"] retain];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    _photoWidth = 0;
    _photoHeight = 0;
    
    _captionLabel = [[UILabel alloc] init];
    _commentLabel = [[UILabel alloc] initWithFrame:CGRectMake(MARGIN_X, 0, self.contentView.width - MARGIN_X * 2 - DISCLOSURE_WIDTH - MARGIN_X, COMMENT_HEIGHT)];
    
    // Background Color
    _captionLabel.backgroundColor = [UIColor clearColor];
    _commentLabel.backgroundColor = [UIColor clearColor];
    
    // Font
    _captionLabel.font = CAPTION_FONT;
    _commentLabel.font = COMMENT_FONT;
    
    // Text Color
    _captionLabel.textColor = FB_COLOR_VERY_LIGHT_BLUE;
    _commentLabel.textColor = [UIColor whiteColor];
    
    // Line Break Mode
    _captionLabel.lineBreakMode = UILineBreakModeWordWrap;
    _commentLabel.lineBreakMode = UILineBreakModeWordWrap;
    
    // Number of Lines
    _captionLabel.numberOfLines = 3;
    _commentLabel.numberOfLines = 0;
    
    // Shadows
    _captionLabel.shadowColor = [UIColor blackColor];
    _captionLabel.shadowOffset = CGSizeMake(0, 1);
//    _commentLabel.shadowColor = [UIColor blackColor];
//    _commentLabel.shadowOffset = CGSizeMake(0, 0);
    
    // Caption
    _captionView = [[UIView alloc] init];
    _captionView.backgroundColor = [UIColor clearColor];
    UIImageView *captionOverlay = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photo-caption-overlay.png"]] autorelease];
    captionOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_captionView addSubview:captionOverlay];
    _captionView.layer.opacity = 0.667;
    
    // Photo
    _photoView = [[PSURLCacheImageView alloc] initWithFrame:CGRectZero];
    _photoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _photoView.shouldAnimate = YES;
//    _photoView.placeholderImage = [UIImage imageNamed:@"photos-large.png"];
    //    _photoView.shouldScale = YES;
    //    _photoView.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    //    _photoView.layer.borderWidth = 1.0;
    
    // Comment
    
    _commentView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.contentView.width, 44)];
    _commentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_commentView addTarget:self action:@selector(commentsSelected) forControlEvents:UIControlEventTouchUpInside];
    [_commentView setBackgroundImage:_commentBackground forState:UIControlStateNormal];
//    _commentView.backgroundColor = [UIColor colorWithPatternImage:_commentBackground];
    
    // Add to contentView
    [self.contentView addSubview:_photoView];
    [self.contentView addSubview:_captionView];
    [self.contentView addSubview:_commentView];
    
    // Add labels
    [self.contentView addSubview:_captionLabel];
    [_commentView addSubview:_commentLabel];
    
    // Comment Icon
//    UIImageView *_commentIconView = [[UIImageView alloc] initWithImage:_commentIcon];
//    _commentIconView.frame = CGRectMake(MARGIN_X, 9, 15, 13);
//    [_commentView addSubview:_commentIconView];
    
    // Disclosure indicator for comment
    UIImageView *_disclosureView = [[[UIImageView alloc] initWithImage:_disclosureIndicator] autorelease];
    _disclosureView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    _disclosureView.contentMode = UIViewContentModeCenter;
    _disclosureView.frame = CGRectMake(self.contentView.width - MARGIN_X - DISCLOSURE_WIDTH, 0, DISCLOSURE_WIDTH, _commentView.height);
    [_commentView addSubview:_disclosureView];
    
    
    UIPinchGestureRecognizer *zoomGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchZoom:)];
    [self addGestureRecognizer:zoomGesture];
    [zoomGesture release];
  }
  return self;
}

- (void)commentsSelected {
  if (self.delegate && [self.delegate respondsToSelector:@selector(commentsSelectedForCell:)]) {
    [self.delegate performSelector:@selector(commentsSelectedForCell:) withObject:self];
  }
}

- (void)pinchZoom:(UIPinchGestureRecognizer *)sender {
  DLog(@"detected pinch gesture with state: %d", [sender state]);
  if (sender.state == UIGestureRecognizerStateBegan || sender.state == UIGestureRecognizerStateChanged) {
    CGFloat factor = [sender scale];
    DLog(@"scale: %f", [sender scale]);
    if (factor > 1.5) {
      // pinch triggered
    }
  } else if (sender.state == UIGestureRecognizerStateRecognized) {
    if ([sender scale] > 1.0) {
      [self triggerPinch];
    } else {
      // this is a shrink not a zoom
    }
  }
}

- (void)triggerPinch {
  if (self.delegate && [self.delegate respondsToSelector:@selector(pinchZoomTriggeredForCell:)]) {
    [self.delegate performSelector:@selector(pinchZoomTriggeredForCell:) withObject:self];
  }
}

- (void)prepareForReuse {
  [super prepareForReuse];
  _captionLabel.text = nil;
  _commentLabel.text = nil;
  _photoView.image = nil;
  _photoWidth = 0;
  _photoHeight = 0;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  // Photo
  _photoView.frame = CGRectMake(0, 0, self.contentView.width, floor(_photoHeight / (_photoWidth / self.contentView.width)));
  
  CGFloat top = _photoView.bottom;
  CGFloat left = MARGIN_X;
  CGFloat textWidth = self.contentView.width - MARGIN_X * 2;
  CGSize desiredSize = CGSizeZero;
  
  // Caption Label
  if ([_captionLabel.text length] > 0) {    
    _captionView.hidden = NO;
    // Caption
    desiredSize = [UILabel sizeForText:_captionLabel.text width:textWidth font:_captionLabel.font numberOfLines:3 lineBreakMode:_captionLabel.lineBreakMode];
    _captionLabel.top = top + MARGIN_Y;
    _captionLabel.left = left;
    _captionLabel.width = desiredSize.width;
    _captionLabel.height = desiredSize.height;
    
    // Caption View
    _captionView.top = top;
    _captionView.left = 0;
    _captionView.height = _captionLabel.height + MARGIN_Y * 2;
    _captionView.width = self.contentView.width;
    
    // Move Captions up
    _captionView.top -= _captionView.height;
    _captionLabel.top -= _captionView.height;
  } else {
    _captionView.hidden = YES;
  }
  
  // Add Comment View
  desiredSize = [UILabel sizeForText:_commentLabel.text width:(textWidth - DISCLOSURE_WIDTH - MARGIN_X) font:_commentLabel.font numberOfLines:_commentLabel.numberOfLines lineBreakMode:_commentLabel.lineBreakMode];
  _commentView.top = _photoView.bottom;
//  _commentView.left = 0.0;
//  _commentView.width = self.contentView.width;
  _commentView.height = desiredSize.height + MARGIN_Y * 2;
  _commentLabel.height = desiredSize.height + MARGIN_Y * 2;
//  _commentView.height = COMMENT_HEIGHT;
  
  //  NSLog(@"layout");
}

+ (CGFloat)rowHeightForObject:(id)object forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  Photo *photo = (Photo *)object;
  
  CGFloat rowWidth = [[self class] rowWidthForInterfaceOrientation:interfaceOrientation];
  CGSize desiredSize = CGSizeZero;
  CGFloat textWidth = rowWidth - MARGIN_X * 2; // minus image
  
  //  CGFloat cellWidth = [[self class] rowWidthForInterfaceOrientation:interfaceOrientation];
  CGFloat desiredHeight = 0;
  
  // Photo
  CGFloat photoWidth = [photo.width floatValue];
  CGFloat photoHeight = [photo.height floatValue];  
  
  desiredHeight += floor(photoHeight / (photoWidth / rowWidth));
  
  // Comments
  //  desiredHeight += COMMENT_HEIGHT;
  
  // Comments with name
  NSMutableSet *commenters = [NSMutableSet set];
  for (Comment *comment in photo.comments) {
    [commenters addObject:comment.fromName];
  }
  
  NSString *commentString = [NSString stringWithFormat:@"Show %d comments from %@", [photo.comments count], [[commenters allObjects] componentsJoinedByString:@", "]];
  
  desiredSize = [UILabel sizeForText:commentString width:(textWidth - DISCLOSURE_WIDTH - MARGIN_X) font:COMMENT_FONT numberOfLines:0 lineBreakMode:UILineBreakModeWordWrap];
  desiredHeight += desiredSize.height + MARGIN_Y * 2;
  
  // Caption
  //  if ([photo.name length] > 0) {
  //    desiredHeight += [UILabel sizeForText:photo.name width:(cellWidth - MARGIN_X * 2) font:CAPTION_FONT numberOfLines:2 lineBreakMode:UILineBreakModeWordWrap].height;
  //    desiredHeight += MARGIN_Y * 2;
  //  }
  
  return desiredHeight;
}

- (void)fillCellWithObject:(id)object {
  Photo *photo = (Photo *)object;
  _photo = photo;
  
  _photoWidth = [photo.width integerValue];
  _photoHeight = [photo.height integerValue];
  
  // Photo
  _photoView.urlPath = photo.source;
  [_photoView loadImageAndDownload:NO];
  
//  if (photo.imageData) {
//    UIImage *cachedImage = [UIImage imageWithData:photo.imageData];
//    _photoView.image = cachedImage;
//  } else {
//    [[PSCoreDataImageCache sharedCache] cacheImageWithURLPath:photo.source forEntity:photo];
//    _photoView.image = nil;
//  }
  
  // Caption
  _captionLabel.text = photo.name;
  
  // Comment
  NSMutableSet *commenters = [NSMutableSet set];
  for (Comment *comment in photo.comments) {
    [commenters addObject:comment.fromName];
  }
  _commentLabel.text = [NSString stringWithFormat:@"Show %d comments from %@", [photo.comments count], [[commenters allObjects] componentsJoinedByString:@", "]];
}

- (void)loadPhoto {
  [_photoView loadImageAndDownload:YES];
}

- (void)dealloc {
  RELEASE_SAFELY(_photoView);
  RELEASE_SAFELY(_captionView);
  RELEASE_SAFELY(_captionLabel);
  RELEASE_SAFELY(_commentView);
  RELEASE_SAFELY(_commentLabel);
  [super dealloc];
}

@end
