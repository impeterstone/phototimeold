//
//  PhotoCellDelegate.h
//  PhotoTime
//
//  Created by Peter Shih on 5/22/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PhotoCell;

@protocol PhotoCellDelegate <NSObject>
@optional
- (void)addCommentForCell:(PhotoCell *)cell;
- (void)commentsSelectedForCell:(PhotoCell *)cell;
- (void)addRemoveLikeForCell:(PhotoCell *)cell;
- (void)pinchZoomTriggeredForCell:(PhotoCell *)cell;

@end