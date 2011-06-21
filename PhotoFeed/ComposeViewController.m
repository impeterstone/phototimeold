//
//  ComposeViewController.m
//  Orca
//
//  Created by Peter Shih on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <MobileCoreServices/UTCoreTypes.h>
#import "ComposeViewController.h"
#import "ComposeDataCenter.h"
#import "UIImage+ScalingAndCropping.h"
#import "PSAlertCenter.h"
#import "PSImageCache.h"

#define SPACING 4.0
#define PORTRAIT_HEIGHT 180.0
#define LANDSCAPE_HEIGHT 74.0

static UIImage *_paperclipImage = nil;
static UIImage *_imageBorderImage = nil;

@implementation ComposeViewController (PickerDelegateMethods)

// For responding to the user tapping Cancel.
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [[picker parentViewController] dismissModalViewControllerAnimated:YES];
  [picker release];
}

// For responding to the user accepting a newly-captured picture or movie
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
  
  // Handle a still image capture
  if (CFStringCompare((CFStringRef)mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
    UIImage *originalImage = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
    
    _pickedImage = [originalImage scaleProportionalToSize:CGSizeMake(640, 640)];
    [_pickedImage retain];
    [_attachPhoto setImage:[_pickedImage cropProportionalToSize:CGSizeMake(66, 66) withRuleOfThirds:NO] forState:UIControlStateNormal];
  }

  [[picker parentViewController] dismissModalViewControllerAnimated:YES];
  [picker release];
}

@end

@implementation ComposeViewController

@synthesize photoId = _photoId;
@synthesize delegate = _delegate;

+ (void)initialize {
  _paperclipImage = [[UIImage imageNamed:@"compose-paperclip.png"] retain]; // 79 x 34
  _imageBorderImage = [[UIImage imageNamed:@"compose-image-border.png"] retain]; // 84 x 79
}

- (id)init {
  self = [super init];
  if (self) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
  }
  return self;
}

- (void)loadView {
  [super loadView];
  
  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-weave.png"]];
  
  UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"texture-spotlight.png"]];
  backgroundView.frame = self.view.bounds;
  [self.view insertSubview:backgroundView atIndex:0];
  [backgroundView release];
  
  // Compose Caption Bubble
  _composeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
  _composeView.backgroundColor = [UIColor clearColor];
//  _composeView.layer.cornerRadius = 5.0;
//  _composeView.layer.masksToBounds = YES;
  _composeView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.view addSubview:_composeView];
  
  // Compose BG
  UIImageView *composeBackground = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"compose-bg.png"]] autorelease];
  composeBackground.frame = _composeView.bounds;
  composeBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [_composeView addSubview:composeBackground];

  // Header View
  _headerView = [[UIView alloc] initWithFrame:CGRectMake(5, 13, 310, 40)];
  _headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  _cancel = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  [_cancel addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
  [_cancel setBackgroundImage:[[UIImage imageNamed:@"compose-cancel.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:0] forState:UIControlStateNormal];
  [_cancel setBackgroundImage:[[UIImage imageNamed:@"compose-cancel-pressed.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:0] forState:UIControlStateHighlighted];
  [_cancel setTitle:@"Cancel" forState:UIControlStateNormal];
  [_cancel setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
  [_cancel setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
  _cancel.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0];
  _cancel.titleLabel.shadowOffset = CGSizeMake(0, 1);
  _cancel.frame = CGRectMake(5, 5, 60, 30);
  _cancel.alpha = 0.0;
  [_headerView addSubview:_cancel];
  
  _send = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  [_send addTarget:self action:@selector(send) forControlEvents:UIControlEventTouchUpInside];
  [_send setBackgroundImage:[[UIImage imageNamed:@"compose-send.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:0] forState:UIControlStateNormal];
  [_send setBackgroundImage:[[UIImage imageNamed:@"compose-send-pressed.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:0] forState:UIControlStateHighlighted];
  [_send setTitle:@"Send" forState:UIControlStateNormal];
  [_send setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [_send setTitleShadowColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
  _send.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0];
  _send.titleLabel.shadowOffset = CGSizeMake(0, -1);
  _send.frame = CGRectMake(310 - 5 - 60, 5, 60, 30);
  _send.alpha = 0.0;
  _send.enabled = NO;
  [_headerView addSubview:_send];
  
  _heading = [[UILabel alloc] initWithFrame:CGRectMake(70, 5, 170, 30)];
  _heading.backgroundColor = [UIColor clearColor];
  _heading.text = @"Say Something...";
  _heading.textColor = [UIColor darkGrayColor];
  _heading.textAlignment = UITextAlignmentCenter;
  _heading.shadowColor = [UIColor whiteColor];
  _heading.shadowOffset = CGSizeMake(0, 1);
  _heading.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0];
  _heading.alpha = 0.0;
  [_headerView addSubview:_heading];
  
  // Message Field
  _message = [[PSTextView alloc] initWithFrame:CGRectMake(5, _headerView.bottom + 3, 226, 20)];
  _message.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_message.returnKeyType = UIReturnKeyDefault;
	_message.font = [UIFont fontWithName:@"HelveticaNeue" size:16.0];
	_message.delegate = self;
  _message.placeholder = @"Write a message...";
  _message.placeholderColor = [UIColor lightGrayColor];
  
  // Attach Photo
  _attachPhoto = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  [_attachPhoto addTarget:self action:@selector(attachPhoto) forControlEvents:UIControlEventTouchUpInside];
  _attachPhoto.frame = CGRectMake(0, 0, _imageBorderImage.size.width, _imageBorderImage.size.height);
  _attachPhoto.left = _composeView.width - 5 - _attachPhoto.width;
  _attachPhoto.top = _headerView.bottom + 13;
  [_attachPhoto setBackgroundImage:_imageBorderImage forState:UIControlStateNormal];
  _attachPhoto.alpha = 0.0;
  
  // Paperclip
  _paperclipView = [[UIImageView alloc] initWithImage:_paperclipImage];
  _paperclipView.left = _composeView.width - _paperclipView.width;
  _paperclipView.top = _headerView.bottom + 3;
  _paperclipView.alpha = 0.0;
  
  [_composeView addSubview:_headerView];
  [_composeView addSubview:_message];
  [_composeView addSubview:_attachPhoto];
  [_composeView addSubview:_paperclipView];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
//  [[ComposeDataCenter sharedInstance] setDelegate:self];
  
  // Subclass should implement
  [_message becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
//  [[ComposeDataCenter sharedInstance] setDelegate:nil];
}

- (void)attachPhoto {
  UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
  imagePicker.allowsEditing = NO;
  imagePicker.delegate = self;
  imagePicker.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  
  // Source Type
  imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  
  // Media Types
  //  imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
  imagePicker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
  //  imagePicker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
  
  [self presentModalViewController:imagePicker animated:YES];
}

- (void)send {
  if (![_message hasText]) {
    [[PSAlertCenter defaultCenter] postAlertWithTitle:@"Whoops!" andMessage:@"You tried to send an empty message..." andDelegate:nil];
    return;
  }
  
  _send.enabled = NO;
  
  
  
  if (self.delegate && [self.delegate respondsToSelector:@selector(composeDidSendWithUserInfo:)]) {
    [self.delegate performSelector:@selector(composeDidSendWithUserInfo:) withObject:nil];
  }
  
  [self cancel];
}

- (void)cancel {
  [_message resignFirstResponder];
}

#pragma mark -
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  
}

#pragma mark UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
  if ([_message hasText]) {
    _send.enabled = YES;
  } else {
    _send.enabled = NO;
  }
}

#pragma mark UIKeyboard
- (void)keyboardWillShow:(NSNotification *)aNotification {
  [self moveTextViewForKeyboard:aNotification up:YES];
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
  [self moveTextViewForKeyboard:aNotification up:NO]; 
}

- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL) up {
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
  
//  if (up) {
//    self.view.height = self.view.height - keyboardFrame.size.height;
//  } else {
//    self.view.height = self.view.height + keyboardFrame.size.height;
//  }
  
  if (up) {
//    _composeView.height = self.view.bounds.size.height - keyboardFrame.size.height;
    _composeView.height = 222;
    _message.height = 140;
    _cancel.alpha = 1.0;
    _send.alpha = 1.0;
    _heading.alpha = 1.0;
    _attachPhoto.alpha = 1.0;
    _paperclipView.alpha = 1.0;
  } else {
//    _composeView.height = self.view.bounds.size.height - 40 + keyboardFrame.size.height;
    _composeView.height = 40;
    _message.height = 20;
    _message.placeholder = nil; // weird placeholder animation bug when shrinking
    _cancel.alpha = 0.0;
    _send.alpha = 0.0;
    _heading.alpha = 0.0;
    _attachPhoto.alpha = 0.0;
    _paperclipView.alpha = 0.0;
  }

  [UIView commitAnimations];
  
  if ([dir isEqualToString:@"down"]) {
    [self dismissModalViewControllerAnimated:YES];
  }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
  
  RELEASE_SAFELY(_photoId);
  RELEASE_SAFELY(_composeView);
  RELEASE_SAFELY(_headerView);
  RELEASE_SAFELY(_cancel);
  RELEASE_SAFELY(_send);
  RELEASE_SAFELY(_heading);
  RELEASE_SAFELY(_attachPhoto);
  RELEASE_SAFELY(_paperclipView);
  RELEASE_SAFELY(_message);
  RELEASE_SAFELY(_pickedImage);
  [super dealloc];
}

@end
