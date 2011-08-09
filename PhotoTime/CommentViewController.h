//
//  CommentViewController.h
//  PhotoTime
//
//  Created by Peter Shih on 5/24/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSTableViewController.h"

@class Photo;

@interface CommentViewController : PSTableViewController {
  Photo *_photo;
}

@property (nonatomic, assign) Photo *photo;

- (void)loadComments;
- (void)unloadComments;

@end
