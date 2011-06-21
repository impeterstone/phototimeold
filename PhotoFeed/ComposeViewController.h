//
//  ComposeViewController.h
//  Orca
//
//  Created by Peter Shih on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardViewController.h"
#import "ComposeDelegate.h"
#import "PSTextView.h"
#import "ComposeDataCenter.h"

@interface ComposeViewController : CardViewController <UITextViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
  NSString *_photoId;
  
  // Caption Bubble
  UIView *_composeView;
  UIView *_headerView;
  PSTextView *_message;
  
  // Header View
  UIButton *_send;
  UIButton *_cancel;
  UILabel *_heading;
  
  // Snapped Photo
  UIButton *_attachPhoto;
  UIImageView *_paperclipView;
  UIImage *_pickedImage;
  
  id <ComposeDelegate> _delegate;
}

@property (nonatomic, copy) NSString *photoId;
@property (nonatomic, assign) id <ComposeDelegate> delegate;

- (void)attachPhoto;
- (void)send;
- (void)cancel;

- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up;

@end
