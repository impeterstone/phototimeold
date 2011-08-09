//
//  UploadViewController.h
//  PhotoTime
//
//  Created by Peter Shih on 5/9/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSBaseViewController.h"
#import "UploadDelegate.h"

@class PSTextField;

@interface UploadViewController : PSBaseViewController <UITextFieldDelegate> {
  UIImage *_uploadImage;
  PSTextField *_captionField;
  UIView *_footerView;
  
  BOOL _isKeyboardShowing;
  BOOL _isFullscreen;
  
  id <UploadDelegate> _delegate;
}

@property (nonatomic, retain) UIImage *uploadImage;
@property (nonatomic, assign) id <UploadDelegate> delegate;

- (void)setupCaption;
- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up;

- (void)upload;
- (void)dismiss;
- (void)imageTapped;

@end
