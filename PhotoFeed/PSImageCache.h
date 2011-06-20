//
//  PSImageCache.h
//  PSNetworkStack
//
//  Created by Peter Shih on 3/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSImageCacheDelegate.h"
#import "PSObject.h"

@class ASIHTTPRequest;

@interface PSImageCache : PSObject <NSCacheDelegate> {
  NSCache *_buffer;
  NSString *_cachePath;
  NSSearchPathDirectory _cacheDirectory;
  NSMutableDictionary *_pendingRequests;
}

@property (nonatomic, retain) NSString *cachePath;
@property (nonatomic, assign) NSSearchPathDirectory cacheDirectory;

+ (PSImageCache *)sharedCache;
- (void)setupCachePathWithCacheDirectory:(NSSearchPathDirectory)cacheDirectory;

// Image Cache
- (void)cacheImage:(NSData *)imageData forURLPath:(NSString *)urlPath;
- (UIImage *)imageForURLPath:(NSString *)urlPath shouldDownload:(BOOL)shouldDownload withDelegate:(id)delegate;
- (BOOL)hasImageForURLPath:(NSString *)urlPath;

// Remote Request
- (void)downloadImageForURLPath:(NSString *)urlPath withDelegate:(id)delegate;
- (void)downloadImageRequestFinished:(ASIHTTPRequest *)request withDelegate:(id)delegate;
- (void)downloadImageRequestFailed:(ASIHTTPRequest *)request withDelegate:(id)delegate;

// Helpers
+ (NSString *)documentDirectory;
+ (NSString *)cachesDirectory;

@end
