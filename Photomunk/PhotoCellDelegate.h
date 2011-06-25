//
//  PhotoCellDelegate.h
//  Photomunk
//
//  Created by Peter Shih on 5/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PhotoCell;

@protocol PhotoCellDelegate <NSObject>
@optional
- (void)commentsSelectedForCell:(PhotoCell *)cell;
- (void)pinchZoomTriggeredForCell:(PhotoCell *)cell;

@end