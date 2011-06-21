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

@synthesize containerView = _containerView;
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
    _photo = nil;
    self.backgroundColor = [UIColor clearColor];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.autoresizesSubviews = YES;
    
    _oldImageFrame = CGRectZero;
    
    _shadeView = [[UIView alloc] initWithFrame:frame];
    _shadeView.backgroundColor = [UIColor blackColor];
    _shadeView.alpha = 0.0;
    _shadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 408, 320, 72)];
    _captionLabel.backgroundColor = [UIColor clearColor];
    _captionLabel.font = CAPTION_FONT;
    _captionLabel.numberOfLines = 4;
    _captionLabel.textAlignment = UITextAlignmentCenter;
    _captionLabel.textColor = FB_COLOR_VERY_LIGHT_BLUE;
    _captionLabel.shadowColor = [UIColor blackColor];
    _captionLabel.shadowOffset = CGSizeMake(0, 1);
    _captionLabel.alpha = 0.0;
    
    _containerView = [[UIScrollView alloc] initWithFrame:frame];
    _containerView.delegate = self;
    _containerView.maximumZoomScale = 3.0;
    _containerView.minimumZoomScale = 1.0;
    _containerView.bouncesZoom = YES;
    _containerView.backgroundColor = [UIColor clearColor];
    
    _zoomImageView = [[PSImageView alloc] initWithFrame:_containerView.bounds];
    _zoomImageView.backgroundColor = [UIColor clearColor];
    _zoomImageView.contentMode = UIViewContentModeScaleAspectFit;
    _zoomImageView.userInteractionEnabled = YES;
    //    _zoomImageView.alpha = 0.0;
    _zoomImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_containerView addSubview:_zoomImageView];
    
    [self addSubview:_shadeView];
    [self addSubview:_containerView];
    [self addSubview:_captionLabel];
    
    // Gestures    
    UITapGestureRecognizer *removeTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeZoom)] autorelease];
    [self addGestureRecognizer:removeTap];
  }
  return self;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
  return _zoomImageView;
}

- (void)showZoom {
  _captionLabel.text = _caption;
  _captionLabel.height = _oldCaptionFrame.size.height;
  _captionLabel.top = 480 - _captionLabel.height;
  
  [[[UIApplication sharedApplication] keyWindow] addSubview:self];
  
  [UIView beginAnimations:@"ZoomImage" context:nil];
  [UIView setAnimationDelegate:nil];
  //  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
  [UIView setAnimationDuration:0.4]; // Fade out is configurable in seconds (FLOAT)
  _shadeView.alpha = 1.0;
  _captionLabel.alpha = 1.0;
//  _zoomImageView.alpha = 1.0;
  _containerView.center = [[[UIApplication sharedApplication] keyWindow] center];
  _zoomImageView.frame = _containerView.bounds;
  [UIView commitAnimations];
}

- (void)removeZoom {
  [_containerView setZoomScale:1.0 animated:NO];
//  _containerView.bounds = CGRectMake(0, 0, 320, 480);
  
  [UIView beginAnimations:@"ZoomImage" context:nil];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(removeZoomView)];
  //  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
  [UIView setAnimationDuration:0.4]; // Fade out is configurable in seconds (FLOAT)
  _shadeView.alpha = 0.0;
  _captionLabel.alpha = 0.0;
//  _zoomImageView.alpha = 0.0;
  _zoomImageView.frame = _oldImageFrame;
  
  [UIView commitAnimations];
}

- (void)removeZoomView {
  [self removeFromSuperview];
}

- (void)dealloc {
  RELEASE_SAFELY(_zoomImageView);
  RELEASE_SAFELY(_shadeView);
  RELEASE_SAFELY(_caption);
  RELEASE_SAFELY(_captionLabel);
  RELEASE_SAFELY(_containerView);
  [super dealloc];
}

@end
