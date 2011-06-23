//
//  UINavigationBar+Custom.m
//  PhotoFeed
//
//  Created by Peter Shih on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UINavigationBar+Custom.h"


@implementation UINavigationBar (Custom)

- (void)drawRect:(CGRect)rect {
  UIImage *image = [[UIImage imageNamed:@"bg-navigation.png"] retain];
	[image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height + 14)];
}

@end
