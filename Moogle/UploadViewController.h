//
//  UploadViewController.h
//  Moogle
//
//  Created by Peter Shih on 5/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardViewController.h"

@class PSTextField;

@interface UploadViewController : CardViewController <UITextFieldDelegate> {
  UIImage *_uploadImage;
  PSTextField *_captionField;
  UIView *_footerView;
  
  BOOL _isKeyboardShowing;
  BOOL _isFullscreen;
}

@property (nonatomic, retain) UIImage *uploadImage;

- (void)setupCaption;
- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up;

- (void)upload;
- (void)dismiss;
- (void)imageTapped;

@end
