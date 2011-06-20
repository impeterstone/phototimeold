//
//  PSURLCacheImageView.h
//  PhotoFeed
//
//  Created by Peter Shih on 5/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSImageView.h"
#import "PSImageCacheDelegate.h"

@interface PSURLCacheImageView : PSImageView <PSImageCacheDelegate> {
  NSString *_urlPath;
}

@property (nonatomic, copy) NSString *urlPath;

- (void)loadImageAndDownload:(BOOL)download;
- (void)unloadImage;

// Image cache loaded from notification
- (void)imageCacheDidLoad:(NSNotification *)notification;

@end