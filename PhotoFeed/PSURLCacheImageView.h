//
//  PSURLCacheImageView.h
//  PhotoFeed
//
//  Created by Peter Shih on 5/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSImageViewDelegate.h"
#import "ASIHTTPRequest.h"
#import "Constants.h"

@interface PSURLCacheImageView : UIImageView <PSImageViewDelegate> {
  NSString *_urlPath;
  UIActivityIndicatorView *_loadingIndicator;
  UIImage *_placeholderImage;
  
  BOOL _shouldScale;
  BOOL _shouldAuth;
  
  ASIHTTPRequest *_request;
  id <PSImageViewDelegate> _delegate;
}

@property (nonatomic, copy) NSString *urlPath;
@property (nonatomic, retain) UIImage *placeholderImage;
@property (nonatomic, assign) BOOL shouldScale;
@property (nonatomic, assign) BOOL shouldAuth;
@property (nonatomic, assign) id <PSImageViewDelegate> delegate;

- (void)loadImage;
- (void)loadImageIfCached;
- (void)unloadImage;
- (void)imageDidLoad;

- (void)requestFinished:(ASIHTTPRequest *)request;
- (void)requestFailed:(ASIHTTPRequest *)request withError:(NSError *)error;

@end