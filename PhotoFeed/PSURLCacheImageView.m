//
//  PSURLCacheImageView.m
//  PhotoFeed
//
//  Created by Peter Shih on 5/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PSURLCacheImageView.h"
#import "PSImageCache.h"
#import "UIImage+ScalingAndCropping.h"
#import "NSString+URLEncoding+PS.h"

static dispatch_queue_t _urlCacheImageViewQueue = nil;

@implementation PSURLCacheImageView

@synthesize urlPath = _urlPath;

+ (void)initialize {
  _urlCacheImageViewQueue = dispatch_queue_create("com.sevenminutelabs.urlCacheImageViewQueue", NULL);
}

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageCacheDidLoad:) name:kPSImageCacheDidCacheImage object:nil];
  }
  return self;
}

//- (void)setUrlPath:(NSString *)urlPath {
//  [_urlPath autorelease];
//  _urlPath = [urlPath copy];
//}

- (void)loadImageAndDownload:(BOOL)download {
  if (_urlPath) {
    NSString *urlPath = [[_urlPath copy] autorelease];
    dispatch_async(_urlCacheImageViewQueue, ^{
      UIImage *image = [[PSImageCache sharedCache] imageForURLPath:urlPath shouldDownload:download withDelegate:nil];
      dispatch_async(dispatch_get_main_queue(), ^{
        if (image) { 
          self.image = image;
        } else {
          self.image = _placeholderImage;
        }
      });
    });
  }
}

- (void)unloadImage {
  self.image = _placeholderImage;
  self.urlPath = nil;
}

- (void)imageCacheDidLoad:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  NSString *urlPath = [userInfo objectForKey:@"urlPath"];
  NSData *imageData = [userInfo objectForKey:@"imageData"];
  if ([urlPath isEqualToString:_urlPath]) {
    if (imageData) {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [UIImage imageWithData:imageData];
        dispatch_async(dispatch_get_main_queue(), ^{
          if (image && ![image isEqual:self.image]) {
            self.image = image;
          }
        });
      });
    }
  }
}

#pragma mark - PSImageCacheDelegate
- (void)imageCacheDidLoad:(NSData *)imageData forURLPath:(NSString *)urlPath {
  if ([urlPath isEqualToString:_urlPath]) {
    if (imageData) {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [UIImage imageWithData:imageData];
        dispatch_async(dispatch_get_main_queue(), ^{
          if (image && ![image isEqual:self.image]) {
            [self setImage:image];
            //            self.image = image;
          }
        });
      });
    }
  }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kPSImageCacheDidCacheImage object:nil];
  RELEASE_SAFELY(_urlPath);
  [super dealloc];
}

@end