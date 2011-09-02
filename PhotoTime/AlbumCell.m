//
//  AlbumCell.m
//  PhotoTime
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import "AlbumCell.h"

#define ALBUM_CELL_HEIGHT 120.0
#define ALBUM_CELL_HEIGHT_ZOOMED 144.0 // 120 * 1.2

#define RIBBON_FONT [UIFont fontWithName:@"HelveticaNeue-Bold" size:10.0]

static UIImage *_ribbonImage = nil;
static UIImage *_disclosureImage = nil;

@implementation AlbumCell

+ (void)initialize {
  _ribbonImage = [[[UIImage imageNamed:@"ribbon.png"] stretchableImageWithLeftCapWidth:30 topCapHeight:0] retain];
  _disclosureImage = [[UIImage imageNamed:@"disclosure_indicator_white_bordered.png"] retain];
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
    _fromLabel = [[UILabel alloc] init];
    _locationLabel = [[UILabel alloc] init];
    _countLabel = [[UILabel alloc] init];
    _dateLabel = [[UILabel alloc] init];
    
    // Background Color
    _nameLabel.backgroundColor = [UIColor clearColor];
    _fromLabel.backgroundColor = [UIColor clearColor];
    _locationLabel.backgroundColor = [UIColor clearColor];
    _countLabel.backgroundColor = [UIColor clearColor];
    _dateLabel.backgroundColor = [UIColor clearColor];
    
    // Font
    _nameLabel.font = TITLE_FONT;
    _fromLabel.font = SUBTITLE_FONT;
    _locationLabel.font = SUBTITLE_FONT;
    _countLabel.font = RIBBON_FONT;
    _dateLabel.font = TIMESTAMP_FONT;
    
    // Text Color
    _nameLabel.textColor = [UIColor whiteColor];
    _fromLabel.textColor = FB_COLOR_VERY_LIGHT_BLUE;
    _locationLabel.textColor = FB_COLOR_VERY_LIGHT_BLUE;
    _countLabel.textColor = [UIColor whiteColor];
    _dateLabel.textColor = FB_COLOR_VERY_LIGHT_BLUE;
    
    // Text Alignment
    _fromLabel.textAlignment = UITextAlignmentRight;
    _locationLabel.textAlignment = UITextAlignmentRight;
    _countLabel.textAlignment = UITextAlignmentRight;
    _dateLabel.textAlignment = UITextAlignmentRight;
    
    // Line Break Mode
    _nameLabel.lineBreakMode = UILineBreakModeTailTruncation;
    _fromLabel.lineBreakMode = UILineBreakModeTailTruncation;
    _locationLabel.lineBreakMode = UILineBreakModeTailTruncation;
    _countLabel.lineBreakMode = UILineBreakModeTailTruncation;
    _dateLabel.lineBreakMode = UILineBreakModeTailTruncation;
    
    // Number of Lines
    _nameLabel.numberOfLines = 1;
    _fromLabel.numberOfLines = 1;
    _locationLabel.numberOfLines = 1;
    _countLabel.numberOfLines = 1;
    _dateLabel.numberOfLines = 1;
    
    // Shadows
    _nameLabel.shadowColor = [UIColor blackColor];
    _nameLabel.shadowOffset = CGSizeMake(0, -1);
    _fromLabel.shadowColor = [UIColor blackColor];
    _fromLabel.shadowOffset = CGSizeMake(0, -1);
    _countLabel.shadowColor = [UIColor blackColor];
    _countLabel.shadowOffset = CGSizeMake(1, 1);
    
    // Photo    
    _photoView = [[PSURLCacheImageView alloc] initWithFrame:CGRectZero];
    _photoView.shouldScale = YES;
    _photoView.shouldAnimate = NO;
    _photoView.delegate = self;
//    _photoView.placeholderImage = [UIImage imageNamed:@"album-placeholder.png"];
//    _photoView = [[PSImageView alloc] initWithFrame:CGRectZero];
    
    // Overlay
    _overlayView = [[UIView alloc] initWithFrame:CGRectZero];
    _overlayView.backgroundColor = [UIColor clearColor];
    
    // Disclosure
    _disclosureView = [[UIImageView alloc] initWithImage:_disclosureImage];
    _disclosureView.contentMode = UIViewContentModeCenter;
    _disclosureView.alpha = 0.6;

    // Ribbon
    _ribbonView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 68, 24)];
    UIImageView *ribbonImageView = [[[UIImageView alloc] initWithImage:_ribbonImage] autorelease];
    ribbonImageView.frame = _ribbonView.bounds;
    [_ribbonView addSubview:ribbonImageView];
    _countLabel.frame = _ribbonView.bounds;
    [_ribbonView addSubview:_countLabel];
    
    // Add to contentView
    [self.contentView addSubview:_photoView];
    [self.contentView addSubview:_overlayView];
    [self.contentView addSubview:_ribbonView];
    [self.contentView addSubview:_disclosureView];
    
    // Add labels
    [self.contentView addSubview:_nameLabel];
    [self.contentView addSubview:_fromLabel];
    [self.contentView addSubview:_locationLabel];
    [self.contentView addSubview:_dateLabel];
  }
  return self;
}

- (void)prepareForReuse {
  [super prepareForReuse];
  
  CGFloat cellHeight = 0.0;
  if (isDeviceIPad()) {
    cellHeight = 288.0;
  } else {
    cellHeight = 120.0;
  }
  
  _nameLabel.text = nil;
  _fromLabel.text = nil;
  _locationLabel.text = nil;
  _dateLabel.text = nil;
  _photoView.frame = CGRectMake(0, 0, self.contentView.width, cellHeight);
  _photoView.image = nil;
  _photoView.urlPath = nil;
  _photoWidth = 0;
  _photoHeight = 0;
  
  [self.layer removeAllAnimations];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  CGFloat cellHeight = 0.0;
  if (isDeviceIPad()) {
    cellHeight = 288.0;
  } else {
    cellHeight = 120.0;
  }
  
  // Set Frames
  _photoView.frame = CGRectMake(0, 0, self.contentView.width, cellHeight);
  _ribbonView.frame = CGRectMake(self.contentView.width - 68, 10, 68, 24);
  _disclosureView.frame = CGRectMake(self.contentView.width - _disclosureView.width - MARGIN_X, 0, _disclosureView.width, self.contentView.height);
  _overlayView.frame = CGRectMake(0, 0, self.contentView.width, cellHeight);
  
  [self animateImage];
  
  // Add Gradient Overlay
  if (![[[_overlayView.layer sublayers] lastObject] isKindOfClass:[CAGradientLayer class]]) {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = _overlayView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor clearColor] CGColor], (id)[RGBACOLOR(0, 0, 0, 0.9) CGColor], (id)[RGBACOLOR(0, 0, 0, 1.0) CGColor], nil];
    gradient.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.5], [NSNumber numberWithFloat:0.99], [NSNumber numberWithFloat:1.0], nil];
    [_overlayView.layer addSublayer:gradient];
  }
  
  CGFloat top = cellHeight - 34;
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
  _fromLabel.top = top - 3;
  _fromLabel.left = left + 1;
  _fromLabel.width = desiredSize.width;
  _fromLabel.height = desiredSize.height;
  
  // Date
  desiredSize = [UILabel sizeForText:_dateLabel.text width:(textWidth - _dateLabel.width - MARGIN_X - 2) font:_dateLabel.font numberOfLines:1 lineBreakMode:_dateLabel.lineBreakMode];
  _dateLabel.top = top - 3;
  _dateLabel.left = self.contentView.width - desiredSize.width - MARGIN_X - 1;
  _dateLabel.width = desiredSize.width;
  _dateLabel.height = desiredSize.height;
}

- (void)resumeAnimations {
  [self resumeLayer:_photoView.layer];
}

- (void)pauseAnimations {
  [self pauseLayer:_photoView.layer];
}

- (void)pauseLayer:(CALayer*)layer {
  if (layer.speed == 0.0) return;
  
  CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
  layer.speed = 0.0;
  layer.timeOffset = pausedTime;
}

- (void)resumeLayer:(CALayer*)layer {
  if (layer.speed == 1.0) return;
  
  CFTimeInterval pausedTime = [layer timeOffset];
  layer.speed = 1.0;
  layer.timeOffset = 0.0;
  layer.beginTime = 0.0;
  CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
  layer.beginTime = timeSincePause;
}

- (void)animateImage {
  // Don't animate it again
  if ([[_photoView.layer animationKeys] containsObject:@"kenBurnsAnimation"]) {
//    NSLog(@"animations: %@", [_photoView.layer animationKeys]);
    return;
  }
  
//  CGFloat cellHeight = 0.0;
//  if (isDeviceIPad()) {
//    cellHeight = 288.0;
//  } else {
//    cellHeight = 120.0;
//  }
  
//  NSLog(@"photoView: %@", NSStringFromCGRect(_photoView.frame));
//  NSLog(@"layer: %@", NSStringFromCGRect(_photoView.layer.frame));
//  NSLog(@"actual w: %f, h: %f", _photoWidth, _photoHeight);
  
  CGFloat width = _photoView.image.size.width;
  CGFloat height = _photoView.image.size.height;
  
//  if (width == height == 0) return;
  
  // Zoom/Scale
  CABasicAnimation *zoomAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
  // Move/Position
  CABasicAnimation *moveAnimation = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
  
  zoomAnimation.fromValue = [NSNumber numberWithFloat:1.0];
  zoomAnimation.toValue = [NSNumber numberWithFloat:1.2];
  
  moveAnimation.fromValue = [NSNumber numberWithFloat:15];
  moveAnimation.toValue = [NSNumber numberWithFloat:floorf(-15)];
  
//  if (width >= height) {
//    zoomAnimation.fromValue = [NSNumber numberWithFloat:1.0];
//    zoomAnimation.toValue = [NSNumber numberWithFloat:1.2];
//    
//    moveAnimation.fromValue = [NSNumber numberWithFloat:-15];
//    moveAnimation.toValue = [NSNumber numberWithFloat:floorf(15)];
//  } else {
//    zoomAnimation.fromValue = [NSNumber numberWithFloat:1.0];
//    zoomAnimation.toValue = [NSNumber numberWithFloat:1.2];
//    
//    moveAnimation.fromValue = [NSNumber numberWithFloat:-50];
//    moveAnimation.toValue = [NSNumber numberWithFloat:floorf(50)];
//  }
  
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
  
}

#pragma mark -
#pragma mark Fill and Height
+ (CGFloat)rowHeightForObject:(id)object forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  CGFloat cellHeight = 0.0;
  if (isDeviceIPad()) {
    cellHeight = 288.0;
  } else {
    cellHeight = 120.0;
  }
  
  return cellHeight;
}

- (void)fillCellWithObject:(id)object {
  Album *album = (Album *)object;
  _album = album;
  
  // Labels
  _nameLabel.text = album.name;
  _fromLabel.text = [NSString stringWithFormat:@"by %@", album.fromName];
//  _locationLabel.text = [NSString stringWithFormat:@"%@", album.location];
  _dateLabel.text = [NSDate stringForDisplayFromDate:album.timestamp];
  _countLabel.text = [NSString stringWithFormat:@"%@ photos ", album.count];
}

- (void)loadPhoto {
  // Photo
  if (_album.coverPhoto) {
    _photoView.urlPath = _album.coverPhoto;
    [_photoView loadImageAndDownload:YES];
  } else {
    // Placeholder Image, no cover photo
    _photoView.image = [UIImage imageNamed:@"bg_no_cover.png"];
    _photoView.urlPath = nil;
  }
  
//  if (_album.coverPhoto) {
//    [_photoView loadImageAndDownload:YES];
//  }
}

- (void)imageDidLoad:(UIImage *)image {
  CGFloat cellHeight = 0.0;
  if (isDeviceIPad()) {
    cellHeight = 288.0;
  } else {
    cellHeight = 120.0;
  }
  
  // this is divided by 2 because we are using retina @2x dimensions
  _photoWidth = image.size.width;
  _photoHeight = image.size.height;
  CGFloat desiredWidth = self.contentView.width;
  CGFloat desiredHeight = floorf((self.contentView.width / _photoWidth) * _photoHeight);
  if (desiredHeight < ceil(cellHeight * 1.2)) { // 120 * 1.2
    desiredHeight = ceil(cellHeight * 1.2);
    desiredWidth = floorf((desiredHeight / _photoHeight) * _photoWidth);
  }
  _photoView.width = desiredWidth;
  _photoView.height = desiredHeight;
}

- (void)dealloc {
  RELEASE_SAFELY(_photoView);
  RELEASE_SAFELY(_overlayView);
  RELEASE_SAFELY(_ribbonView);
  RELEASE_SAFELY(_disclosureView);
  
  RELEASE_SAFELY(_nameLabel);
  RELEASE_SAFELY(_fromLabel);
  RELEASE_SAFELY(_locationLabel);
  RELEASE_SAFELY(_countLabel);
  RELEASE_SAFELY(_dateLabel);
  [super dealloc];
}

@end
