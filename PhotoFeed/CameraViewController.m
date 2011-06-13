//
//  CameraViewController.m
//  PhotoFeed
//
//  Created by Peter Shih on 5/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CameraViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "CameraImageHelper.h"

@implementation CameraViewController (CameraDelegateMethods)

// For responding to the user tapping Cancel.
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  _shouldDismissOnAppear = YES;
  [[picker parentViewController] dismissModalViewControllerAnimated:YES];
  [picker release];
}

// For responding to the user accepting a newly-captured picture or movie
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
  
  if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
    _shouldSaveToAlbum = YES;
  } else {
    _shouldSaveToAlbum = NO;
  }
  
  // Handle a still image capture
  if (CFStringCompare((CFStringRef)mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
    _snappedImage = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
    [_snappedImage retain];
//    _selectedImage = [[originalImage scaleProportionalToSize:CGSizeMake(640, 640)] retain];
  }
  
  if (_snappedImage && _shouldSaveToAlbum) {
    UIImageWriteToSavedPhotosAlbum(_snappedImage, nil, nil, nil);
  }
  
  _shouldDismissOnAppear = NO;
  [[picker parentViewController] dismissModalViewControllerAnimated:YES];
  [picker release];
  
  // Push compose controller
//  ComposeViewController *cvc = [[ComposeViewController alloc] init];
//  cvc.snappedImage = _snappedImage; // set the snapped image ref
//  [self.navigationController pushViewController:cvc animated:YES];
//  [cvc release];
}

@end

@implementation CameraViewController

- (id)init {
  self = [super init];
  if (self) {
    _shouldSaveToAlbum = NO;
    _shouldDismissOnAppear = NO;
  }
  return self;
}

- (void)loadView {
  [super loadView];
  
  self.navigationController.navigationBarHidden = YES;
  self.view.backgroundColor = [UIColor blackColor];

//  [CameraImageHelper startRunning];
//  _previewBox = [CameraImageHelper previewWithBounds:self.view.bounds];
//  
//  [self.view addSubview:_previewBox];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  if (!_shouldDismissOnAppear) {
    [self showCamera];
  } else {
    [self dismissModalViewControllerAnimated:NO];
  }
}

- (void)showCamera {
  UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
  imagePicker.allowsEditing = NO;
  imagePicker.delegate = self;
  imagePicker.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
  } else {
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  }
  
  imagePicker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
  
  [self presentModalViewController:imagePicker animated:YES];
}

- (void)showPhotoLibrary {
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
  
  [self presentModalViewController:imagePicker animated:NO];
}

- (void)snap {

}

- (void)dealloc {
//  [CameraImageHelper stopRunning];
  RELEASE_SAFELY(_snappedImage);
  [super dealloc];
}

@end
