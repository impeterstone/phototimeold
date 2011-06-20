//
//  PSImageArrayView.m
//  PhotoFeed
//
//  Created by Peter Shih on 5/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PSImageArrayView.h"
#import "PSImageCache.h"
#import "UIImage+ScalingAndCropping.h"
#import <QuartzCore/QuartzCore.h>

@implementation PSImageArrayView

@synthesize urlPathArray = _urlPathArray;
@synthesize shouldScale = _shouldScale;

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _animateIndex = 0;
    _shouldScale = NO;
    _images = [[NSMutableDictionary alloc] init];
    _pendingRequests = [[NSMutableArray alloc] init];
    
    _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _loadingIndicator.hidesWhenStopped = YES;
    _loadingIndicator.frame = self.bounds;
    _loadingIndicator.contentMode = UIViewContentModeCenter;
    [_loadingIndicator startAnimating];
    [self addSubview:_loadingIndicator];
    self.backgroundColor = [UIColor blackColor];
  }
  return self;
}

- (void)setFrame:(CGRect)frame {
  [super setFrame:frame];
  _loadingIndicator.frame = self.bounds;
}

- (void)setImage:(UIImage *)image {
  [super setImage:[UIImage imageWithCGImage:image.CGImage scale:2 orientation:image.imageOrientation]];
}

#pragma mark Array of Images
- (void)getImageRequestWithUrlPath:(NSString *)urlPath {
  // Fire the request
  ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlPath]];
  
  // Request Completion Block
  [request setCompletionBlock:^{
    [self requestFinished:request];
  }];
  
  // Request Failed Block
  [request setFailedBlock:^{
    NSError *error = [request error];
    
    [self requestFailed:request withError:error];
  }];
  
  // Start the Request
  [request startAsynchronous];
  
  [_pendingRequests addObject:request];
}

- (void)loadImageArray {
  [self checkAndResetImageArray];
}

- (void)checkAndResetImageArray {
  // We need to check to see if we should reset the imageArray
  // If there are any pendingRequests, we should always reset
  if ([_pendingRequests count] > 0) {
    for (ASIHTTPRequest *request in _pendingRequests) {
      [request clearDelegatesAndCancel];
    }
    [_pendingRequests removeAllObjects];
  }
  
  // If there has been a change in the 5 images to show, we need to reset
  BOOL hasChanged = NO;
  for (NSString *urlPath in  _urlPathArray) {
    if (![_images objectForKey:urlPath]) {
      hasChanged = YES;
      break;
    }
  }
  if (hasChanged) {
    [_images removeAllObjects];
    INVALIDATE_TIMER(_animateTimer);
    
    if (_urlPathArray) {
      for (NSString *urlPath in _urlPathArray) {
        UIImage *image = [[PSImageCache sharedCache] imageForURLPath:urlPath shouldDownload:YES withDelegate:nil];
        if (image) {
          [_images setObject:image forKey:urlPath];
          [self prepareImageArray];
        } else {
          [_loadingIndicator startAnimating];
          [self getImageRequestWithUrlPath:urlPath];
        }
      }
    }
  }
}

- (void)animateImages {
  NSArray *imageArray = [_images allValues];
  self.image = [imageArray objectAtIndex:_animateIndex];
  
  CABasicAnimation *crossFade = [CABasicAnimation animationWithKeyPath:@"contents"];
  crossFade.duration = 3.0;
  crossFade.fromValue = (id)[[imageArray objectAtIndex:_animateIndex] CGImage];
  
  _animateIndex++;
  if (_animateIndex == [_images count]) {
    _animateIndex = 0;
  }
  
  crossFade.toValue = (id)[[imageArray objectAtIndex:(_animateIndex)] CGImage];
  [self.layer addAnimation:crossFade forKey:@"animateContents"];
  
  self.image = [imageArray objectAtIndex:_animateIndex];
  
//  self.animationImages = _imageArray;
//	self.animationDuration = [_imageArray count] * 3.0;
//	[self startAnimating];
}
                             
- (void)requestFinished:(ASIHTTPRequest *)request {
  UIImage *image = [UIImage imageWithData:[request responseData]];
  UIImage *newImage = nil;
  if (image) {
    if (_shouldScale) {
      newImage = [image cropProportionalToSize:self.bounds.size];
    } else {
      newImage = image;
    }
    [[PSImageCache sharedCache] cacheImage:UIImageJPEGRepresentation(newImage, 1.0) forURLPath:[[request originalURL] absoluteString]];
  }
  if (newImage) {
    [_images setObject:newImage forKey:[[request originalURL] absoluteString]];
    [self prepareImageArray];
  }
  [_pendingRequests removeObject:request];
}

- (void)requestFailed:(ASIHTTPRequest *)request withError:(NSError *)error {
  [_pendingRequests removeObject:request];
}

- (void)prepareImageArray {
  if ([_images count] >= [_urlPathArray count] && !_animateTimer) {
//    [self animateImages];
    [_loadingIndicator stopAnimating];
    _animateTimer = [[NSTimer timerWithTimeInterval:6.0 target:self selector:@selector(animateImages) userInfo:nil repeats:YES] retain];
    [[NSRunLoop currentRunLoop] addTimer:_animateTimer forMode:NSDefaultRunLoopMode];
    [_animateTimer fire];
  }
}

- (void)dealloc {
  RELEASE_SAFELY(_urlPathArray);
  RELEASE_SAFELY(_images);
  RELEASE_SAFELY(_pendingRequests);
  RELEASE_SAFELY(_loadingIndicator);
  INVALIDATE_TIMER(_animateTimer);
  
  [super dealloc];
}

@end
