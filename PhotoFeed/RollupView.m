//
//  RollupView.m
//  PhotoFeed
//
//  Created by Peter Shih on 6/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RollupView.h"
#import "PSURLCacheImageView.h"

#define MARGIN 5.0
#define PICTURE_SIZE 30.0

@implementation RollupView

@synthesize backgroundImage = _backgroundImage;
@synthesize pictureURLArray = _pictureURLArray;

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code
    _headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(MARGIN, MARGIN, self.width - MARGIN * 2, 20)];
    _headerLabel.backgroundColor = [UIColor clearColor];
    _headerLabel.font = NORMAL_FONT;
    _headerLabel.textColor = [UIColor whiteColor];
    
    _pictureScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(MARGIN, _headerLabel.bottom + MARGIN, self.width - MARGIN * 2, PICTURE_SIZE)];
    _pictureScrollView.scrollEnabled = YES;
    _pictureScrollView.showsHorizontalScrollIndicator = NO;
    _pictureScrollView.showsVerticalScrollIndicator = NO;
    
    _footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(MARGIN, _pictureScrollView.bottom + MARGIN, self.width - MARGIN * 2, 20)];
    _footerLabel.backgroundColor = [UIColor clearColor];
    _footerLabel.font = SUBTITLE_FONT;
    _footerLabel.textColor = [UIColor whiteColor];
    
    // Background Image
    _backgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self addSubview:_backgroundView];
    
    [self addSubview:_headerLabel];
    [self addSubview:_footerLabel];
    [self addSubview:_pictureScrollView];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
  [_backgroundImage autorelease];
  _backgroundImage = [backgroundImage retain];
  
  [_backgroundView setImage:_backgroundImage];
}

- (void)setHeaderText:(NSString *)headerText {
  _headerLabel.text = headerText;
  // resize
}

- (void)setFooterText:(NSString *)footerText {
  _footerLabel.text = footerText;
}

- (void)setPictureURLArray:(NSArray *)pictureURLArray {
  [_pictureURLArray autorelease];
  _pictureURLArray = [pictureURLArray retain];
  
  // Update pictureScrollView
  PSURLCacheImageView *profileImage = nil;
  int i = 0;
  for (NSString *pictureURLPath in _pictureURLArray) {
    profileImage = [[[PSURLCacheImageView alloc] initWithFrame:CGRectMake(0, 0, PICTURE_SIZE, PICTURE_SIZE)] autorelease];
    profileImage.urlPath = pictureURLPath;
    [profileImage loadImageAndDownload:YES];
    
    profileImage.left = (i * profileImage.width) + (i * MARGIN);
    [_pictureScrollView addSubview:profileImage];
    i++;
  }
  
  NSInteger numPictures = [pictureURLArray count];
  _pictureScrollView.contentSize = CGSizeMake(numPictures * PICTURE_SIZE + numPictures * MARGIN - MARGIN, _pictureScrollView.height);
}

- (void)dealloc {
  RELEASE_SAFELY(_backgroundView);
  RELEASE_SAFELY(_backgroundImage);
  RELEASE_SAFELY(_headerLabel);
  RELEASE_SAFELY(_footerLabel);
  RELEASE_SAFELY(_pictureScrollView);
  RELEASE_SAFELY(_pictureURLArray);
  [super dealloc];
}

@end
