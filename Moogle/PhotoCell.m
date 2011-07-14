//
//  PhotoCell.m
//  Moogle
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PhotoCell.h"
#import "Comment.h"
#import "PSRollupView.h"

static UIImage *_overlay = nil;
static UIImage *_comment = nil;

@implementation PhotoCell

@synthesize photoView = _photoView;
@synthesize captionLabel = _captionLabel;
@synthesize delegate = _delegate;

+ (void)initialize {
  _overlay = [[UIImage imageNamed:@"bg-gradient-overlay.png"] retain];
  _comment = [[UIImage imageNamed:@"button-comment.png"] retain];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    _photoWidth = 0;
    _photoHeight = 0;
    
    _captionLabel = [[UILabel alloc] init];
    
    // Background Color
    _captionLabel.backgroundColor = [UIColor clearColor];
    
    // Font
    _captionLabel.font = CAPTION_FONT;
    
    // Text Color
    _captionLabel.textColor = [UIColor whiteColor];
    
    // Line Break Mode
    _captionLabel.lineBreakMode = UILineBreakModeWordWrap;
    
    // Number of Lines
    _captionLabel.numberOfLines = 3;
    
    // Shadows
    _captionLabel.shadowColor = [UIColor blackColor];
    _captionLabel.shadowOffset = CGSizeMake(0, 1);
    
    // Photo
    _photoView = [[PSURLCacheImageView alloc] initWithFrame:CGRectZero];
    _photoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _photoView.shouldAnimate = NO;
    
    // Overlay Gradient
    _overlayView = [[UIImageView alloc] initWithImage:_overlay];
    _overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    // Comment Button
    _commentButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_commentButton addTarget:self action:@selector(showComments) forControlEvents:UIControlEventTouchUpInside];
    [_commentButton setBackgroundImage:_comment forState:UIControlStateNormal];
    _commentButton.titleLabel.font = CAPTION_FONT;
    _commentButton.titleLabel.shadowColor = [UIColor blackColor];
    _commentButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
    _commentButton.titleEdgeInsets = UIEdgeInsetsMake(-5, 2, 0, 0);
    
    _commentButton.width = _comment.size.width;
    _commentButton.height = _comment.size.height;
    
    // Rollup
//    _taggedFriendsView = [[PSRollupView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.width, 0)];
//    [_taggedFriendsView setBackgroundImage:[UIImage stretchableImageNamed:@"bg-rollup.png" withLeftCapWidth:0 topCapWidth:0]];
//    _taggedFriendsView.hidden = YES;

//    _photoView.placeholderImage = [UIImage imageNamed:@"photos-large.png"];
    //    _photoView.shouldScale = YES;
    //    _photoView.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    //    _photoView.layer.borderWidth = 1.0;
    
    // Add to contentView
    [self.contentView addSubview:_photoView];
    [self.contentView addSubview:_overlayView];
    [self.contentView addSubview:_commentButton];
//    [self.contentView addSubview:_taggedFriendsView];
    
    // Add labels
    [self.contentView addSubview:_captionLabel];
        
    UIPinchGestureRecognizer *zoomGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchZoom:)];
    [self addGestureRecognizer:zoomGesture];
    [zoomGesture release];
  }
  return self;
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
//  _photoView.image = nil;
  _photoWidth = 0;
  _photoHeight = 0;
//  _taggedFriendsView.hidden = YES;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  // Photo
  _photoView.frame = CGRectMake(0, 0, self.contentView.width, floor(_photoHeight / (_photoWidth / self.contentView.width)));
  _overlayView.frame = CGRectMake(0, _photoView.bottom - _overlayView.height, _overlayView.width, _overlayView.height);
  
  CGFloat bottom = _photoView.bottom;
  CGFloat left = MARGIN_X;
  CGFloat textWidth = self.contentView.width - MARGIN_X * 2;
  CGSize desiredSize = CGSizeZero;
  
  // Rollup
//  if ([_photo.tags count] > 0) {
//    _taggedFriendsView.hidden = NO;
//    NSArray *taggedFriendNames = [[_photo.tags valueForKeyPath:@"@distinctUnionOfObjects.fromName"] allObjects];
//    
//    [_taggedFriendsView setHeaderText:[NSString stringWithFormat:@"In this photo: %@", [taggedFriendNames componentsJoinedByString:@", "]]];
//    [_taggedFriendsView layoutIfNeeded];
//    _taggedFriendsView.top = 0;
//  } else {
//    _taggedFriendsView.hidden = YES;
//  }
  
  // Comment Button
  _commentButton.top = MARGIN_Y;
  _commentButton.left = self.contentView.width - _commentButton.width - MARGIN_X;
  
  // Caption Label
  if ([_captionLabel.text length] > 0) {    
    _captionLabel.hidden = NO;
    // Caption
    desiredSize = [UILabel sizeForText:_captionLabel.text width:textWidth font:_captionLabel.font numberOfLines:3 lineBreakMode:_captionLabel.lineBreakMode];
    _captionLabel.width = desiredSize.width;
    _captionLabel.height = desiredSize.height;
    _captionLabel.top = bottom - _captionLabel.height - MARGIN_Y;
    _captionLabel.left = left;
    
  } else {
    _captionLabel.hidden = YES;
  }
}

+ (CGFloat)rowHeightForObject:(id)object forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  Photo *photo = (Photo *)object;
  
  CGFloat rowWidth = [[self class] rowWidthForInterfaceOrientation:interfaceOrientation];
//  CGSize desiredSize = CGSizeZero;
//  CGFloat textWidth = rowWidth - MARGIN_X * 2; // minus image
  
  //  CGFloat cellWidth = [[self class] rowWidthForInterfaceOrientation:interfaceOrientation];
  CGFloat desiredHeight = 0;
  
  // Photo
  CGFloat photoWidth = [photo.width floatValue];
  CGFloat photoHeight = [photo.height floatValue];  
  
  desiredHeight += floor(photoHeight / (photoWidth / rowWidth));
  
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
  
  // Comments
  NSString *comments = [photo.comments count] > 0 ? [NSString stringWithFormat:@"%d",[photo.comments count]] : @"+";
  [_commentButton setTitle:comments forState:UIControlStateNormal];
  
  // Caption
  _captionLabel.text = photo.name;
}

- (void)loadPhoto {
  [_photoView loadImageAndDownload:YES];
}

- (void)showComments {
  if (self.delegate && [self.delegate respondsToSelector:@selector(commentsSelectedForCell:)]) {
    [self.delegate commentsSelectedForCell:self];
  }
}

- (void)dealloc {
  RELEASE_SAFELY(_photoView);
  RELEASE_SAFELY(_captionLabel);
  RELEASE_SAFELY(_overlayView);
  RELEASE_SAFELY(_commentButton);
//  RELEASE_SAFELY(_taggedFriendsView);
  [super dealloc];
}

@end
