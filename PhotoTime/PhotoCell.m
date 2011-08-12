//
//  PhotoCell.m
//  PhotoTime
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import "PhotoCell.h"
#import "Comment.h"
#import "PSRollupView.h"
#import "CommentView.h"
#import "UIButton+SML.h"

#define CAPTION_HEIGHT 40.0

static UIImage *_comment = nil;
static UIImage *_like = nil;

@implementation PhotoCell

@synthesize photoView = _photoView;
@synthesize delegate = _delegate;

+ (void)initialize {
  _comment = [[UIImage imageNamed:@"comment_indicator.png"] retain];
  _like = [[UIImage imageNamed:@"icon_like.png"] retain];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.clipsToBounds = YES;
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
    _captionLabel.shadowOffset = CGSizeMake(1, 1);
    
    // Photo
    _photoView = [[PSURLCacheImageView alloc] initWithFrame:CGRectZero];
    _photoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _photoView.shouldAnimate = YES;
    
    // Comment Button
    _commentButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_commentButton addTarget:self action:@selector(showComments) forControlEvents:UIControlEventTouchUpInside];
    [_commentButton setBackgroundImage:_comment forState:UIControlStateNormal];
    _commentButton.titleLabel.font = [UIFont systemFontOfSize:10];
    [_commentButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//    _commentButton.titleLabel.shadowColor = [UIColor whiteColor];
//    _commentButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
    _commentButton.titleEdgeInsets = UIEdgeInsetsMake(-3, 1, 0, 0);
    
    _commentButton.width = _comment.size.width;
    _commentButton.height = _comment.size.height;
    
    // Like Button
    _likeButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_likeButton addTarget:self action:@selector(addRemoveLike) forControlEvents:UIControlEventTouchUpInside];
    [_likeButton setBackgroundImage:_like forState:UIControlStateNormal];
    
    _likeButton.width = _like.size.width;
    _likeButton.height = _like.size.height;
    
    _commentsFrame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_comment.png"]];
    
    _commentsView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _commentsView.clipsToBounds = NO;
    _commentsView.backgroundColor = [UIColor clearColor];
    _commentsView.scrollsToTop = NO;
    _commentsView.showsVerticalScrollIndicator = NO;
    _commentsView.showsHorizontalScrollIndicator = NO;
    _commentsView.pagingEnabled = YES;
    
    // Rollup
//    _taggedFriendsView = [[PSRollupView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.width, 0)];
//    [_taggedFriendsView setBackgroundImage:[UIImage stretchableImageNamed:@"bg_rollup.png" withLeftCapWidth:0 topCapWidth:0]];
//    _taggedFriendsView.hidden = YES;

    //    _photoView.shouldScale = YES;
    //    _photoView.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    //    _photoView.layer.borderWidth = 1.0;
    
    // Caption
    _captionView = [[UIView alloc] initWithFrame:CGRectZero];
    UIImageView *cbg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_caption.png"]] autorelease];
    _captionView.backgroundColor = [UIColor clearColor];
    cbg.frame = _captionView.bounds;
    cbg.autoresizingMask = ~UIViewAutoresizingNone;
    [_captionView addSubview:cbg];
    [_captionView addSubview:_captionLabel];
    [_captionView addSubview:_commentButton];
    
    // Add to contentView
    [self.contentView addSubview:_photoView];
//    [self.contentView addSubview:_likeButton];
    [self.contentView addSubview:_captionView];
    [self.contentView addSubview:_commentsFrame];
    [self.contentView addSubview:_commentsView];
        
    UIPinchGestureRecognizer *zoomGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchZoom:)];
    [self addGestureRecognizer:zoomGesture];
    [zoomGesture release];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showComments)];
    tapGesture.delegate = self;
    [_captionView addGestureRecognizer:tapGesture];
    [tapGesture release];
  }
  return self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  if ([touch.view isKindOfClass:[UIButton class]]) {
    return NO;
  } else {
    return YES;
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
  _photoView.image = nil;
  _photoWidth = 0;
  _photoHeight = 0;
  [_commentsView removeSubviews];
  _commentsView.contentSize = _commentsView.bounds.size;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  // Photo
  _photoView.frame = CGRectMake(0, 0, self.contentView.width, floor(_photoHeight / (_photoWidth / self.contentView.width)));
  
  CGFloat top = 0;
  CGFloat bottom = _photoView.bottom;
//  CGFloat left = MARGIN_X;
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
  
  // Like Button
  _likeButton.top = MARGIN_Y * 2;
  _likeButton.left = MARGIN_X * 2;
  
  // Comment Button
  _commentButton.top = floorf((CAPTION_HEIGHT - _commentButton.height) / 2);
  _commentButton.left = self.contentView.width - _commentButton.width - MARGIN_X;
  
  // Caption Label
  if ([_captionLabel.text length] > 0) {    
    _captionLabel.hidden = NO;
    // Caption
    desiredSize = [UILabel sizeForText:_captionLabel.text width:(textWidth - _commentButton.width - MARGIN_X) font:_captionLabel.font numberOfLines:3 lineBreakMode:_captionLabel.lineBreakMode];
    _captionLabel.width = desiredSize.width;
    _captionLabel.height = CAPTION_HEIGHT - (MARGIN_Y * 2);
    _captionLabel.left = MARGIN_X;
    _captionLabel.top = MARGIN_Y;
  } else {
    _captionLabel.hidden = YES;
  }
  
  // Caption View
  _captionView.width = self.contentView.width;
  _captionView.height = CAPTION_HEIGHT;
  _captionView.left = 0;
  _captionView.top = bottom - _captionView.height;
  
  top = _photoView.bottom;
  
  _commentsFrame.top = top;
  _commentsFrame.left = 0;
  _commentsFrame.width = self.contentView.width;
  _commentsFrame.height = 60;
  
  _commentsView.top = top;
  _commentsView.left = 0;
  _commentsView.width = self.contentView.width - 20;
  _commentsView.height = 60;
  
  // If expanded, show comments    
  NSUInteger numComments = [_photo.comments count];
  if ([self isExpanded]) {
    if ([[_commentsView subviews] count] > 0) return;
    _commentsView.contentSize = CGSizeMake(_commentsView.width * (numComments + 1), _commentsView.height);
    // add Like and Comment Button
    UIButton *likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    likeButton.frame = CGRectMake(15, 15, 120, 29);
    [likeButton addTarget:self action:@selector(addRemoveLike) forControlEvents:UIControlEventTouchUpInside];
    [likeButton setBackgroundImage:[UIImage imageNamed:@"button_drawer.png"] forState:UIControlStateNormal];
    [likeButton setBackgroundImage:[UIImage imageNamed:@"button_drawer_highlighted.png"] forState:UIControlStateHighlighted];
    [likeButton setTitle:@"Like this Photo" forState:UIControlStateNormal];
    [likeButton setTitleColor:FB_COLOR_DARK_GRAY_BLUE forState:UIControlStateNormal];
    [likeButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [_commentsView addSubview:likeButton];
    
    UIButton *commentButton = [UIButton buttonWithType:UIButtonTypeCustom];
    commentButton.frame = CGRectMake(150, 15, 120, 29);
    [commentButton addTarget:self action:@selector(addComment) forControlEvents:UIControlEventTouchUpInside];
    [commentButton setBackgroundImage:[UIImage imageNamed:@"button_drawer.png"] forState:UIControlStateNormal];
    [commentButton setBackgroundImage:[UIImage imageNamed:@"button_drawer_highlighted.png"] forState:UIControlStateHighlighted];
    [commentButton setTitle:@"Add a Comment" forState:UIControlStateNormal];
    [commentButton setTitleColor:FB_COLOR_DARK_GRAY_BLUE forState:UIControlStateNormal];
    [commentButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [_commentsView addSubview:commentButton];
    
    int i = 1;
    for (Comment *comment in [_photo.comments allObjects]) {
      CommentView *c = [[CommentView alloc] initWithFrame:CGRectZero];
      c.width = _commentsView.width;
      c.height = _commentsView.height;
      c.left = i * c.width;
      [c loadCommentsWithObject:comment];
      [_commentsView addSubview:c];
      [c release];
      i++;
    }
  } else {
    [_commentsView removeSubviews];
  }
  
//  if (numComments > 0 && [self isExpanded]) {
//    if ([[_commentsView subviews] count] > 0) return;
//    _commentsView.contentSize = CGSizeMake(_commentsView.width * numComments, _commentsView.height);
//    int i = 0;
//    for (Comment *comment in [_photo.comments allObjects]) {
//      CommentView *c = [[CommentView alloc] initWithFrame:CGRectZero];
//      c.width = _commentsView.width;
//      c.height = _commentsView.height;
//      c.left = i * c.width;
//      [c loadCommentsWithObject:comment];
//      [_commentsView addSubview:c];
//      [c release];
//      i++;
//    }
//  } else {
//    [_commentsView removeSubviews];
//  }
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

+ (CGFloat)rowHeightForObject:(id)object expanded:(BOOL)expanded forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//  Photo *photo = (Photo *)object;
  
  CGFloat origHeight = [[self class] rowHeightForObject:object forInterfaceOrientation:interfaceOrientation];
  CGFloat desiredHeight = 0;

  desiredHeight += origHeight;
  
  // Add the comments table
  if (expanded) {
    desiredHeight += 60;
  }
  
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
  if ([photo.name length] > 0) {
    _captionLabel.text = photo.name;
  } else {
    _captionLabel.text = [NSString stringWithFormat:@"Photo uploaded on %@", [NSDate stringForDisplayFromDate:photo.timestamp]];
  }
}

- (void)loadPhoto {
  [_photoView loadImageAndDownload:YES];
}

- (void)addComment {
  if (self.delegate && [self.delegate respondsToSelector:@selector(addCommentForCell:)]) {
    [self.delegate addCommentForCell:self];
  }
}

- (void)showComments {
  if (self.delegate && [self.delegate respondsToSelector:@selector(commentsSelectedForCell:)]) {
    [self.delegate commentsSelectedForCell:self];
  }
}

- (void)addRemoveLike {
  if (self.delegate && [self.delegate respondsToSelector:@selector(addRemoveLikeForCell:)]) {
    [self.delegate addRemoveLikeForCell:self];
  }
}

- (void)dealloc {
  RELEASE_SAFELY(_photoView);
  RELEASE_SAFELY(_captionView);
  RELEASE_SAFELY(_captionLabel);
  RELEASE_SAFELY(_taggedLabel);
  RELEASE_SAFELY(_commentButton);
  RELEASE_SAFELY(_likeButton);
  RELEASE_SAFELY(_commentsView);
  RELEASE_SAFELY(_commentsFrame);
  [super dealloc];
}

@end
