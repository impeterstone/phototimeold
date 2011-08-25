//
//  PhotoViewController.h
//  PhotoTime
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSCoreDataTableViewController.h"
#import "PhotoCellDelegate.h"
#import "UploadDelegate.h"

@class Album;
@class Photo;
@class PSZoomView;
@class PSRollupView;
@class PSTextField;

@interface PhotoViewController : PSCoreDataTableViewController <PhotoCellDelegate, UploadDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate> {
  Album *_album;
  Photo *_photoToComment;
  PSRollupView *_taggedFriendsView;
  PSZoomView *_zoomView;
  NSString *_sortKey;
  UIImage *_uploadImage;
  PSTextField *_commentField;
  UIButton *_cancelButton;
  UIView *_commentView;
}

@property (nonatomic, assign) Album *album;
@property (nonatomic, retain) NSString *sortKey;

- (UIBarButtonItem *)rightBarButton;

- (void)getTaggedFriends;

- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up;

@end
