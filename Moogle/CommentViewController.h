//
//  CommentViewController.h
//  Moogle
//
//  Created by Peter Shih on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardCoreDataTableViewController.h"

@class Photo;
@class PSImageView;
@class PSTextField;

@interface CommentViewController : CardCoreDataTableViewController <UIGestureRecognizerDelegate> {
  Photo *_photo;
  CGFloat _photoOffset;
  PSImageView *_photoView;
  PSTextField *_commentField;
//  UIButton *_sendCommentButton;
  UIButton *_cancelButton;
  
  BOOL _composeOnAppear;
}

@property (nonatomic, assign) Photo *photo;
@property (nonatomic, assign) CGFloat photoOffset;
@property (nonatomic, retain) PSImageView *photoView;
@property (nonatomic, assign) BOOL composeOnAppear;

- (void)setupFooter;
- (void)commentChanged:(UITextField *)textField;
- (void)sendComment;

- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up;

@end
