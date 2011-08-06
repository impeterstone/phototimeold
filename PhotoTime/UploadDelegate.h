//
//  UploadDelegate.h
//  PhotoTime
//
//  Created by Peter Shih on 7/18/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol UploadDelegate <NSObject>

@optional
- (void)uploadPhotoWithData:(NSData *)data caption:(NSString *)caption;

@end
