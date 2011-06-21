//
//  AlbumCell.m
//  PhotoFeed
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AlbumCell.h"
#import "UIImage+ScalingAndCropping.h"

#define ALBUM_CELL_HEIGHT 120.0
#define ALBUM_CELL_HEIGHT_ZOOMED 144.0 // 120 * 1.2

#define NAME_FONT [UIFont fontWithName:@"HelveticaNeue-Bold" size:16.0]
#define CAPTION_FONT [UIFont fontWithName:@"HelveticaNeue" size:10.0]
#define SMALL_ITALIC_FONT [UIFont fontWithName:@"HelveticaNeue" size:10.0]
#define RIBBON_FONT [UIFont fontWithName:@"HelveticaNeue-Bold" size:10.0]

static UIImage *_ribbonImage = nil;
static UIImage *_overlayImage = nil;

@implementation AlbumCell

+ (void)initialize {
  _ribbonImage = [[[UIImage imageNamed:@"ribbon.png"] stretchableImageWithLeftCapWidth:30 topCapHeight:0] retain];
  _overlayImage = [[UIImage imageNamed:@"overlay_2_320x120.png"] retain];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.clipsToBounds = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    _isAnimating = NO;
    _photoWidth = 0;
    _photoHeight = 0;
    
    _nameLabel = [[UILabel alloc] init];
    _captionLabel = [[UILabel alloc] init];
    _fromLabel = [[UILabel alloc] init];
    _locationLabel = [[UILabel alloc] init];
    _countLabel = [[UILabel alloc] init];
    
    // Background Color
    _nameLabel.backgroundColor = [UIColor clearColor];
    _captionLabel.backgroundColor = [UIColor clearColor];
    _fromLabel.backgroundColor = [UIColor clearColor];
    _locationLabel.backgroundColor = [UIColor clearColor];
    _countLabel.backgroundColor = [UIColor clearColor];
    
    // Font
    _nameLabel.font = NAME_FONT;
    _captionLabel.font = CAPTION_FONT;
    _fromLabel.font = SMALL_ITALIC_FONT;
    _locationLabel.font = SMALL_ITALIC_FONT;
    _countLabel.font = RIBBON_FONT;
    
    // Text Color
    _nameLabel.textColor = [UIColor whiteColor];
    _captionLabel.textColor = FB_COLOR_VERY_LIGHT_BLUE;
    _fromLabel.textColor = FB_COLOR_VERY_LIGHT_BLUE;
    _locationLabel.textColor = FB_COLOR_VERY_LIGHT_BLUE;
    _countLabel.textColor = [UIColor whiteColor];
    
    // Text Alignment
    _fromLabel.textAlignment = UITextAlignmentRight;
    _locationLabel.textAlignment = UITextAlignmentRight;
    _countLabel.textAlignment = UITextAlignmentRight;
    
    // Line Break Mode
    _nameLabel.lineBreakMode = UILineBreakModeTailTruncation;
    _captionLabel.lineBreakMode = UILineBreakModeTailTruncation;
    _fromLabel.lineBreakMode = UILineBreakModeTailTruncation;
    _locationLabel.lineBreakMode = UILineBreakModeTailTruncation;
    _countLabel.lineBreakMode = UILineBreakModeTailTruncation;
    
    // Number of Lines
    _nameLabel.numberOfLines = 1;
    _captionLabel.numberOfLines = 1;
    _fromLabel.numberOfLines = 1;
    _locationLabel.numberOfLines = 1;
    _countLabel.numberOfLines = 1;
    
    // Shadows
    _nameLabel.shadowColor = [UIColor blackColor];
    _nameLabel.shadowOffset = CGSizeMake(0, -1);
    _captionLabel.shadowColor = [UIColor blackColor];
    _captionLabel.shadowOffset = CGSizeMake(0, -1);
    _fromLabel.shadowColor = [UIColor blackColor];
    _fromLabel.shadowOffset = CGSizeMake(0, -1);
    _countLabel.shadowColor = [UIColor blackColor];
    _countLabel.shadowOffset = CGSizeMake(1, 1);
    
    // Caption
    _captionView = [[UIView alloc] initWithFrame:CGRectZero];
    _captionView.backgroundColor = [UIColor blueColor];
    _captionView.layer.opacity = 0.0;
    
    // Photo
    _photoView = [[PSURLCacheImageView alloc] initWithFrame:CGRectMake(0, 0, 320, ALBUM_CELL_HEIGHT)];
    _photoView.shouldScale = YES;
    _photoView.shouldAnimate = NO;
    _photoView.delegate = self;
    _photoView.placeholderImage = [UIImage imageNamed:@"album-placeholder.png"];
//    _photoView = [[PSImageView alloc] initWithFrame:CGRectZero];
    
    // Overlay
    _overlayView = [[UIImageView alloc] initWithImage:_overlayImage];
    _overlayView.frame = CGRectMake(0, 0, 320, ALBUM_CELL_HEIGHT);

    // Ribbon
    _ribbonView = [[UIView alloc] initWithFrame:CGRectMake(320 - 68, 10, 68, 24)];
    UIImageView *ribbonImageView = [[[UIImageView alloc] initWithImage:_ribbonImage] autorelease];
    ribbonImageView.frame = _ribbonView.bounds;
    [_ribbonView addSubview:ribbonImageView];
    _countLabel.frame = _ribbonView.bounds;
    [_ribbonView addSubview:_countLabel];
    
    // Add to contentView
    [self.contentView addSubview:_photoView];
    [self.contentView addSubview:_overlayView];
    [self.contentView addSubview:_captionView];
    [self.contentView addSubview:_ribbonView];
    
    // Add labels
    [self.contentView addSubview:_nameLabel];
    [self.contentView addSubview:_captionLabel];
    [self.contentView addSubview:_fromLabel];
    [self.contentView addSubview:_locationLabel];
  }
  return self;
}

- (void)prepareForReuse {
  [super prepareForReuse];
  _nameLabel.text = nil;
  _captionLabel.text = nil;
  _fromLabel.text = nil;
  _locationLabel.text = nil;
  _photoView.frame = CGRectMake(0, 0, 320, ALBUM_CELL_HEIGHT);
  _photoView.image = nil;
  _photoView.urlPath = nil;
  _photoWidth = 0;
  _photoHeight = 0;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  // Photo
  
  // Check to see if there is a caption
//  if ([_captionLabel.text length] > 0) {
//    _captionView.frame = CGRectMake(0, ALBUM_CELL_HEIGHT - 34, 320, 34);
//  } else {
//    _captionView.frame = CGRectMake(0, ALBUM_CELL_HEIGHT - 22, 320, 22);
//  }
  _captionView.frame = CGRectMake(0, ALBUM_CELL_HEIGHT - 34, 320, 34);
  
  CGFloat top = _captionView.top;
  CGFloat left = MARGIN_X;
  CGFloat textWidth = self.contentView.width - MARGIN_X * 2;
  CGSize desiredSize = CGSizeZero;
  
  // Name
  desiredSize = [UILabel sizeForText:_nameLabel.text width:textWidth font:_nameLabel.font numberOfLines:1 lineBreakMode:_nameLabel.lineBreakMode];
  _nameLabel.top = top;
  _nameLabel.left = left;
  _nameLabel.width = desiredSize.width;
  _nameLabel.height = desiredSize.height;
  
  top = _nameLabel.bottom;
  
  // From/Author
  desiredSize = [UILabel sizeForText:_fromLabel.text width:(textWidth - 2) font:_fromLabel.font numberOfLines:1 lineBreakMode:_fromLabel.lineBreakMode];
  _fromLabel.top = top - 2;
  _fromLabel.left = left + 1;
  _fromLabel.width = desiredSize.width;
  _fromLabel.height = desiredSize.height;
  
  // Location
  desiredSize = [UILabel sizeForText:_locationLabel.text width:(textWidth - _fromLabel.width - MARGIN_X - 2) font:_locationLabel.font numberOfLines:1 lineBreakMode:_locationLabel.lineBreakMode];
  _locationLabel.top = top - 2;
  _locationLabel.left = self.contentView.width - desiredSize.width - MARGIN_X - 1;
  _locationLabel.width = desiredSize.width;
  _locationLabel.height = desiredSize.height;
  
//  if ([_captionLabel.text length] > 0) {    
//    // Caption
//    desiredSize = [UILabel sizeForText:_captionLabel.text width:textWidth font:_captionLabel.font numberOfLines:1 lineBreakMode:_captionLabel.lineBreakMode];
//    _captionLabel.top = top - 2; // -2
//    _captionLabel.left = left;
//    _captionLabel.width = desiredSize.width;
//    _captionLabel.height = desiredSize.height;
//  }
}


- (void)animateImage {
  // Don't animate it again
  if ([[_photoView.layer animationKeys] containsObject:@"kenBurnsAnimation"]) {
//    NSLog(@"animations: %@", [_photoView.layer animationKeys]);
    return;
  }
  
//  NSLog(@"photoView: %@", NSStringFromCGRect(_photoView.frame));
//  NSLog(@"layer: %@", NSStringFromCGRect(_photoView.layer.frame));
//  NSLog(@"actual w: %f, h: %f", _photoWidth, _photoHeight);
  
  CGFloat width = _photoView.width;
  CGFloat height = _photoView.height;
  
  
  // Zoom/Scale
  CABasicAnimation *zoomAnimation = [CABasicAnimation animationWithKeyPath:@"bounds.size"];
  if (width >= height) {
    zoomAnimation.fromValue = [NSValue valueWithCGSize:CGSizeMake(floor(width * 1.2), floor(height * 1.2))];
    zoomAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(floor(width), floor(height))];
  } else {
    zoomAnimation.fromValue = [NSValue valueWithCGSize:CGSizeMake(width, height)];
    zoomAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(floor(width * 1.2), floor(height * 1.2))];
  }
  
//  zoomAnimation.fillMode = kCAFillModeForwards;
//  resizeAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//  zoomAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
//  zoomAnimation.repeatCount = HUGE_VALF;
//  zoomAnimation.autoreverses = YES;
//  zoomAnimation.duration = 10.0;
  
  // Move/Position
  CABasicAnimation *moveAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
  CGPoint startPt = CGPointMake(160, floor(height / 2));
  CGPoint endPt = CGPointMake(160, floor(height / 3));
  moveAnimation.fromValue = [NSValue valueWithCGPoint:startPt];
  moveAnimation.toValue = [NSValue valueWithCGPoint:endPt];
  
//  NSLog(@"start: %@, end: %@", NSStringFromCGPoint(startPt), NSStringFromCGPoint(endPt));
  
//  
//  CGPoint startPt = CGPointMake(320 / 2, 0);
//  CGPoint endPt = CGPointMake(320 / 2, 120);
//  CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
//  anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
//  anim.fromValue = [NSValue valueWithCGPoint:startPt];
//  anim.toValue = [NSValue valueWithCGPoint:endPt];
//  anim.repeatCount = HUGE_VALF;
//  anim.autoreverses = YES;
//  anim.duration = 8.0;
//  [_photoView.layer addAnimation:anim forKey:@"position"];
  
  // Animation Group
  CAAnimationGroup *group = [CAAnimationGroup animation]; 
  group.fillMode = kCAFillModeForwards;
  group.removedOnCompletion = NO;
  group.duration = 15.0;
  group.delegate = self;
  group.autoreverses = YES;
  group.repeatCount = HUGE_VALF;
  group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  [group setAnimations:[NSArray arrayWithObjects:zoomAnimation, moveAnimation, nil]];
  [group setValue:_photoView forKey:@"imageViewBeingAnimated"];
  [_photoView.layer addAnimation:group forKey:@"kenBurnsAnimation"];
  
//  NSLog(@"animations: %@", [_photoView.layer animationKeys]);
  // Add animation
//  [_photoView.layer addAnimation:resizeAnimation forKey:@"bounds.size"];
  
}

#pragma mark -
#pragma mark Fill and Height
+ (CGFloat)rowHeightForObject:(id)object forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return ALBUM_CELL_HEIGHT;
}

- (void)fillCellWithObject:(id)object {
  Album *album = (Album *)object;
  _album = album;
  
  // Labels
  _nameLabel.text = album.name;
  _captionLabel.text = album.caption;
  _fromLabel.text = [NSString stringWithFormat:@"by %@", album.fromName];
  _locationLabel.text = [NSString stringWithFormat:@"%@", album.location];
  _countLabel.text = [NSString stringWithFormat:@"%@ photos ", album.count];
}

- (void)loadPhoto {
  // Photo
  if (_album.coverPhoto) {
    _photoView.urlPath = _album.coverPhoto;
    [_photoView loadImageAndDownload:YES];
  } else {
    // Placeholder Image, no cover photo
    _photoView.image = [UIImage imageNamed:@"lnkd.png"];
    _photoView.urlPath = nil;
  }
  
//  if (_album.coverPhoto) {
//    [_photoView loadImageAndDownload:YES];
//  }
}

- (void)imageDidLoad:(UIImage *)image {
  // this is divided by 2 because we are using retina @2x dimensions
  _photoWidth = image.size.width;
  _photoHeight = image.size.height;
  CGFloat desiredWidth = self.contentView.width;
  CGFloat desiredHeight = floor((self.contentView.width / _photoWidth) * _photoHeight);
  if (desiredHeight < ALBUM_CELL_HEIGHT_ZOOMED) { // 120 * 1.2
    desiredHeight = ALBUM_CELL_HEIGHT_ZOOMED;
    desiredWidth = floor((desiredHeight / _photoHeight) * _photoWidth);
  }
  _photoView.width = desiredWidth;
  _photoView.height = desiredHeight;
  [self animateImage];
}

- (void)dealloc {
  RELEASE_SAFELY(_photoView);
  RELEASE_SAFELY(_overlayView);
  RELEASE_SAFELY(_captionView);
  RELEASE_SAFELY(_ribbonView);
  
  RELEASE_SAFELY(_nameLabel);
  RELEASE_SAFELY(_captionLabel);
  RELEASE_SAFELY(_fromLabel);
  RELEASE_SAFELY(_locationLabel);
  RELEASE_SAFELY(_countLabel);
  [super dealloc];
}

@end
