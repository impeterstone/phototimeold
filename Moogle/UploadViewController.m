//
//  UploadViewController.m
//  Orca
//
//  Created by Peter Shih on 5/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UploadViewController.h"
#import "UIImage+SML.h"

@implementation UploadViewController

@synthesize uploadImage = _uploadImage;
@synthesize delegate = _delegate;

- (id)init {
  self = [super init];
  if (self) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    _isKeyboardShowing = NO;
    _isFullscreen = NO;
  }
  return self;
}

- (void)loadView {
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
  
  self.navigationItem.rightBarButtonItem = [self navButtonWithTitle:@"Upload" withTarget:self action:@selector(upload) buttonType:NavButtonTypeBlue];
  
  _navTitleLabel.text = @"Upload Photo";
  
  UIImageView *imageView = [[[UIImageView alloc] initWithImage:_uploadImage] autorelease];
//  imageView.autoresizingMask = self.view.autoresizingMask;
  imageView.contentMode = UIViewContentModeScaleAspectFit;
  imageView.frame = self.view.bounds;
  [self.view addSubview:imageView];
  
  [self setupCaption];
  
  UITapGestureRecognizer *dismissTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped)] autorelease];
  [self.view addGestureRecognizer:dismissTap];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
  
  RELEASE_SAFELY(_uploadImage);
  RELEASE_SAFELY(_captionField);
  RELEASE_SAFELY(_footerView);
  [super dealloc];
}

- (void)upload {
  NSString *caption = ([_captionField.text length] > 0) ? _captionField.text : nil;
  if (self.delegate && [self.delegate respondsToSelector:@selector(uploadPhotoWithData:caption:)]) {
    [self.delegate uploadPhotoWithData:UIImageJPEGRepresentation(_uploadImage, 0.8) caption:caption];
  }
  [self dismiss];
}

- (void)dismiss {
  [[self parentViewController] autorelease];
  [[self parentViewController] dismissModalViewControllerAnimated:YES];
}

- (void)imageTapped {
  if (_isKeyboardShowing) {
    [_captionField resignFirstResponder];
    return;
  }
  
  [UIView animateWithDuration:0.4
                   animations:^{
                     if (_isFullscreen) {
                       self.navigationController.navigationBar.alpha = 1.0;
                       _footerView.alpha = 1.0;
                       _isFullscreen = NO;
                     } else {
                       self.navigationController.navigationBar.alpha = 0.0;
                       _footerView.alpha = 0.0;
                       _isFullscreen = YES;
                     }
                   }
                   completion:^(BOOL finished) {
                   }];
}

#pragma mark - Footer
- (void)setupCaption {
  _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height - 44, self.view.width, 44)];
  _footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
  
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage stretchableImageNamed:@"bg_footer_44.png" withLeftCapWidth:1 topCapWidth:0]] autorelease];
  //  bg.top = -14;
  bg.width = _footerView.width;
  [_footerView insertSubview:bg atIndex:0];
  
  // Field
  _captionField = [[PSTextField alloc] initWithFrame:CGRectMake(5, 6, 310, 32) withInset:CGSizeMake(5, 7)];
  _captionField.delegate = self;
  //  _captionField.clearButtonMode = UITextFieldViewModeWhileEditing;
  //  _captionField.borderStyle = UITextBorderStyleNone;
  _captionField.background = [UIImage stretchableImageNamed:@"bg_textfield.png" withLeftCapWidth:12 topCapWidth:15];
  _captionField.font = BOLD_FONT;
  _captionField.placeholder = @"Add a caption...";
  _captionField.returnKeyType = UIReturnKeyDone;
//  [_captionField addTarget:self action:@selector(captionChanged:) forControlEvents:UIControlEventEditingChanged];
  [_footerView addSubview:_captionField];
    
  [self.view addSubview:_footerView];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

#pragma mark - UIKeyboard
- (void)keyboardWillShow:(NSNotification *)aNotification {
  [self moveTextViewForKeyboard:aNotification up:YES];
  _isKeyboardShowing = YES;
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
  [self moveTextViewForKeyboard:aNotification up:NO]; 
  _isKeyboardShowing = NO;
}

- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up {
  NSDictionary* userInfo = [aNotification userInfo];
  
  // Get animation info from userInfo
  NSTimeInterval animationDuration;
  UIViewAnimationCurve animationCurve;
  
  CGRect keyboardEndFrame;
  
  [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
  [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
  
  
  CGRect keyboardFrame = CGRectZero;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 30200
  // code for iOS below 3.2
  [[userInfo objectForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardEndFrame];
  keyboardFrame = keyboardEndFrame;
#else
  // code for iOS 3.2 ++
  [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
  keyboardFrame = [UIScreen convertRect:keyboardEndFrame toView:self.view];
#endif  
  
  // Animate up or down
  NSString *dir = up ? @"up" : @"down";
  [UIView beginAnimations:dir context:nil];
  [UIView setAnimationDuration:animationDuration];
  [UIView setAnimationCurve:animationCurve];
  
  if (up) {
    self.view.height = self.view.height - keyboardFrame.size.height;
  } else {
    self.view.height = self.view.height + keyboardFrame.size.height;
  }
  
  [UIView commitAnimations];
}

@end
