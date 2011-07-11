//
//  UINavigationBar+Custom.m
//  Moogle
//
//  Created by Peter Shih on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UINavigationBar+Custom.h"
#import <QuartzCore/QuartzCore.h>

@implementation UINavigationBar (Custom)

//- (void)drawRect:(CGRect)rect {
//  UIImage *image = [[UIImage imageNamed:@"bg-navigation.png"] retain];
//	[image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height + 14)];
//}

- (void)willMoveToWindow:(UIWindow *)newWindow{
  [super willMoveToWindow:newWindow];
  [self applyDropShadow];
}

- (void)applyDropShadow {
  // add the drop shadow
  self.layer.masksToBounds = NO;
  self.layer.shadowColor = [[UIColor blackColor] CGColor];
  self.layer.shadowOffset = CGSizeMake(0.0, 3.0);
  self.layer.shadowOpacity = 0.25;
}

@end
