//
//  PSImageCacheDelegate.h
//  Orca
//
//  Created by Peter Shih on 6/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol PSImageCacheDelegate <NSObject>

@optional
- (void)imageCacheDidLoad:(NSData *)imageData forURLPath:(NSString *)urlPath;

@end
