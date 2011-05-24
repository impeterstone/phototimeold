//
//  PSZoomView.m
//  PhotoFeed
//
//  Created by Peter Shih on 5/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PSZoomView.h"
#import "Photo.h"

#define CAPTION_FONT [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0]

@implementation PSZoomView

@synthesize zoomImageView = _zoomImageView;
@synthesize shadeView = _shadeView;
@synthesize captionLabel = _captionLabel;
@synthesize caption = _caption;
@synthesize oldImageFrame = _oldImageFrame;
@synthesize oldCaptionFrame = _oldCaptionFrame;
@synthesize photo = _photo;

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
#warning change this to manual rotation instead of uiview rotation
    _photo = nil;
    self.backgroundColor = [UIColor clearColor];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
//    self.autoresizesSubviews = YES;
    
    _oldImageFrame = CGRectZero;
    _zoomImageView = [[PSImageView alloc] initWithFrame:frame];
    _zoomImageView.contentMode = UIViewContentModeScaleAspectFit;
    _zoomImageView.userInteractionEnabled = YES;
    _zoomImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    _shadeView = [[UIView alloc] initWithFrame:frame];
    _shadeView.backgroundColor = [UIColor blackColor];
    _shadeView.alpha = 0.0;
    _shadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    _captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 408, 320, 72)];
    _captionLabel.backgroundColor = [UIColor clearColor];
    _captionLabel.font = CAPTION_FONT;
    _captionLabel.numberOfLines = 4;
    _captionLabel.textAlignment = UITextAlignmentCenter;
    _captionLabel.textColor = FB_COLOR_VERY_LIGHT_BLUE;
    _captionLabel.shadowColor = [UIColor blackColor];
    _captionLabel.shadowOffset = CGSizeMake(0, 1);
    _captionLabel.alpha = 0.0;
    _captionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    [self addSubview:_shadeView];
    [self addSubview:_zoomImageView];
    [self addSubview:_captionLabel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPhoto:) name:kImageCached object:nil];
    
    // Gestures
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pinchGesture.delegate = self;
    [_zoomImageView addGestureRecognizer:pinchGesture];
    [pinchGesture release];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    panGesture.maximumNumberOfTouches = 2;
    [_zoomImageView addGestureRecognizer:panGesture];
    [panGesture release];
  }
  return self;
}

#pragma mark -
#pragma mark Gestures
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)gestureRecognizer {
  
  if([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
    // Reset the last scale, necessary if there are multiple objects with different scales
    _lastScale = [gestureRecognizer scale];
  }
  
  if ([gestureRecognizer state] == UIGestureRecognizerStateBegan ||
      [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
    
    CGFloat currentScale = [[[gestureRecognizer view].layer valueForKeyPath:@"transform.scale"] floatValue];
    
    // Constants to adjust the max/min values of zoom
    const CGFloat kMaxScale = 2.0;
    const CGFloat kMinScale = 1.0;
    
    CGFloat newScale = 1 -  (_lastScale - [gestureRecognizer scale]); // new scale is in the range (0-1)
    newScale = MIN(newScale, kMaxScale / currentScale);
    newScale = MAX(newScale, kMinScale / currentScale);
    CGAffineTransform transform = CGAffineTransformScale([[gestureRecognizer view] transform], newScale, newScale);
    [gestureRecognizer view].transform = transform;
    
    _lastScale = [gestureRecognizer scale];  // Store the previous scale factor for the next pinch gesture call
  }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
  UIView *piece = [gestureRecognizer view];
  
  if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
    CGPoint translation = [gestureRecognizer translationInView:[piece superview]];
    
    [piece setCenter:CGPointMake([piece center].x + translation.x, [piece center].y + translation.y)];
    [gestureRecognizer setTranslation:CGPointZero inView:[piece superview]];
  }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  return YES;
}

- (void)reloadPhoto:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  if ([[userInfo objectForKey:@"entity"] isEqual:_photo]) {
    _zoomImageView.image = [UIImage imageWithData:_photo.imageData];
  }
}

- (void)zoom {
  _captionLabel.text = _caption;
  _captionLabel.height = _oldCaptionFrame.size.height;
  _captionLabel.top = 480 - _captionLabel.height;
  
  [UIView beginAnimations:@"ZoomImage" context:nil];
  [UIView setAnimationDelegate:nil];
  //  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
  [UIView setAnimationDuration:0.4]; // Fade out is configurable in seconds (FLOAT)
  _shadeView.alpha = 1.0;
  _captionLabel.alpha = 1.0;
  self.zoomImageView.center = [[[UIApplication sharedApplication] keyWindow] center];
  [UIView commitAnimations];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kImageCached object:nil];
  RELEASE_SAFELY(_zoomImageView);
  RELEASE_SAFELY(_shadeView);
  RELEASE_SAFELY(_caption);
  RELEASE_SAFELY(_captionLabel);
  [super dealloc];
}

@end
