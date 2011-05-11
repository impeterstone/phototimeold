//
//  PSImageView.m
//  PSNetworkStack
//
//  Created by Peter Shih on 3/10/11.
//  Copyright 2011 Seven Minute Apps. All rights reserved.
//

#import "PSImageView.h"
#import "PSNetworkQueue.h"
#import "PSNetworkOperation.h"
#import "PSImageCache.h"
#import "UIImage+ScalingAndCropping.h"

@implementation PSImageView

@synthesize urlPath = _urlPath;
@synthesize placeholderImage = _placeholderImage;
@synthesize shouldScale = _shouldScale;
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _shouldScale = NO;
    
    _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _loadingIndicator.hidesWhenStopped = YES;
    _loadingIndicator.frame = self.bounds;
    _loadingIndicator.contentMode = UIViewContentModeCenter;
    [self addSubview:_loadingIndicator];
  }
  return self;
}

- (void)setFrame:(CGRect)frame {
  [super setFrame:frame];
  _loadingIndicator.frame = self.bounds;
}

// Override Setter
//- (void)setUrlPath:(NSString *)urlPath {
//  if (urlPath) {
//    NSString* urlPathCopy = [urlPath copy];
//    [_urlPath release];
//    _urlPath = urlPathCopy;
//    
//    // Image not found in cache, fire a request
//    PSNetworkOperation *op = [[PSNetworkOperation alloc] initWithURL:[NSURL URLWithString:_urlPath]];
//    op.delegate = self;
//    [op setQueuePriority:NSOperationQueuePriorityVeryLow];
//    [[PSNetworkQueue sharedQueue] addOperation:op];
//    [op release];
//  }
//}

- (void)loadImage {
  if (_urlPath) {
    UIImage *image = [[PSImageCache sharedCache] imageForURLPath:_urlPath];
    if (image) {
      self.image = image;
      [self imageDidLoad];
    } else {
      self.image = _placeholderImage;
      [_loadingIndicator startAnimating];
      if (_op) {
        [_op clearDelegatesAndCancel];
        RELEASE_SAFELY(_op);
      }
      _op = [[PSNetworkOperation alloc] initWithURL:[NSURL URLWithString:_urlPath]];
      _op.delegate = self;
      _op.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
      [_op setQueuePriority:NSOperationQueuePriorityVeryLow];
      [[PSNetworkQueue sharedQueue] addOperation:_op];
    }
  }
}

- (void)unloadImage {
  [_loadingIndicator stopAnimating];
  self.image = _placeholderImage;
  self.urlPath = nil;
}

- (void)imageDidLoad {
  [_loadingIndicator stopAnimating];
  if (self.delegate && [self.delegate respondsToSelector:@selector(imageDidLoad:)]) {
    [self.delegate imageDidLoad:self.image];
  }
}

#pragma mark PSNetworkOperationDelegate
- (void)networkOperationDidFinish:(PSNetworkOperation *)operation {
  UIImage *image = nil;
  if (_shouldScale) {
    image = [[UIImage imageWithData:[operation responseData]] cropProportionalToSize:self.bounds.size];
  } else {
    image = [UIImage imageWithData:[operation responseData]];
  }
  if (image) {
    [[PSImageCache sharedCache] cacheImage:image forURLPath:[[operation requestURL] absoluteString]];
    if ([self.urlPath isEqualToString:[[operation requestURL] absoluteString]]) {
      self.image = image;
      [self imageDidLoad];
    }
  }
  
  //  NSLog(@"Image width: %f, height: %f", image.size.width, image.size.height);
}

- (void)networkOperationDidFail:(PSNetworkOperation *)operation {
  self.image = _placeholderImage;
}

- (void)dealloc {
  if (_op) [_op clearDelegatesAndCancel];
  RELEASE_SAFELY(_op);
  RELEASE_SAFELY(_urlPath);
  RELEASE_SAFELY(_loadingIndicator);
  RELEASE_SAFELY(_placeholderImage);
  
  [super dealloc];
}
@end
