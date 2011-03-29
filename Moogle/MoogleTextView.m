//
//  MoogleTextView.m
//  Moogle
//
//  Created by Peter Shih on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MoogleTextView.h"


@implementation MoogleTextView

@synthesize backgroundView = _backgroundView;

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _backgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _backgroundView.image = [[UIImage imageNamed:@"textview_bg.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:15];
    [self insertSubview:_backgroundView atIndex:0];
    self.backgroundColor = [UIColor clearColor];
  }
  return self;
}

- (void)setContentOffset:(CGPoint)s {
	if(self.tracking || self.decelerating){
		//initiated by user...
		self.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
	} else {
    
		float bottomOffset = (self.contentSize.height - self.frame.size.height + self.contentInset.bottom);
		if(s.y < bottomOffset && self.scrollEnabled){
			self.contentInset = UIEdgeInsetsMake(0, 0, 8, 0); //maybe use scrollRangeToVisible?
		}
		
	}
	
	[super setContentOffset:s];
}

- (void)setContentInset:(UIEdgeInsets)s {
	UIEdgeInsets insets = s;
	
	if(s.bottom>8) insets.bottom = 0;
	insets.top = 0;
  
	[super setContentInset:insets];
}


- (void)dealloc {
  [_backgroundView release], _backgroundView = nil;
  [super dealloc];
}

@end
