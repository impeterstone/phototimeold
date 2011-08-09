//
//  ZoomViewController.m
//  PhotoTime
//
//  Created by Peter Shih on 8/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ZoomViewController.h"

@implementation ZoomViewController

@synthesize imageView = _imageView;

- (id)init {
  self = [super init];
  if (self) {
    self.wantsFullScreenLayout = YES;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  }
  return self;
}

- (void)dealloc {
  RELEASE_SAFELY(_containerView);
  RELEASE_SAFELY(_imageView);
  [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)loadView {
  [super loadView];
  
  _containerView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
  _containerView.autoresizingMask = ~UIViewAutoresizingNone;
  _containerView.delegate = self;
  _containerView.maximumZoomScale = 3.0;
  _containerView.minimumZoomScale = 1.0;
  _containerView.bouncesZoom = YES;
  _containerView.backgroundColor = [UIColor clearColor];
  
  _imageView = [[PSImageView alloc] initWithFrame:_containerView.bounds];
  _imageView.autoresizingMask = ~UIViewAutoresizingNone;
  _imageView.backgroundColor = [UIColor clearColor];
  _imageView.contentMode = UIViewContentModeScaleAspectFit;
  _imageView.userInteractionEnabled = YES;
  //    _imageView.alpha = 0.0;
  _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [_containerView addSubview:_imageView];
  
  [self.view addSubview:_containerView];
  
  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
  [_containerView addGestureRecognizer:tapGesture];
  [tapGesture release];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
  return _imageView;
}

- (void)dismiss {
  [self dismissModalViewControllerAnimated:YES];
}

-(void) receivedRotate: (NSNotification *) notification {
  
  UIDeviceOrientation interfaceOrientation = [[UIDevice currentDevice] orientation];
  
  [UIView animateWithDuration:0.4
                   animations:^{
                     if(interfaceOrientation == UIDeviceOrientationPortrait) {
                       self.view.transform = CGAffineTransformMakeRotation(RADIANS(0));
                       self.view.bounds = CGRectMake(0, 0, 320, 480);
                     }
                     else if(interfaceOrientation == UIDeviceOrientationLandscapeLeft) {
                       self.view.transform = CGAffineTransformMakeRotation(RADIANS(90));
                       self.view.bounds = CGRectMake(0, 0, 480, 320);
                     }
                     else if(interfaceOrientation == UIDeviceOrientationLandscapeRight) {
                       self.view.transform = CGAffineTransformMakeRotation(RADIANS(-90));
                       self.view.bounds = CGRectMake(0, 0, 480, 320);
                     }
                   }
                   completion:^(BOOL finished) {
                   }];
}

@end
