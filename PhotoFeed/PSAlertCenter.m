//
//  PSAlertCenter.m
//  Orca
//
//  Created by Peter Shih on 6/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PSAlertCenter.h"


@implementation PSAlertCenter

+ (PSAlertCenter *)defaultCenter {
  static PSAlertCenter *defaultCenter = nil;
  if (!defaultCenter) {
    defaultCenter = [[self alloc] init];
  }
  return defaultCenter;
}

- (id)init {
  self = [super init];
  if (self) {
    _alertView = [[UIAlertView alloc] initWithTitle:nil message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
  }
  return self;
}

#pragma mark - Post Alert
- (void)postAlertWithTitle:(NSString *)title andMessage:(NSString *)message andDelegate:(id)delegate {
  if (!title && !message) return;
  if (_alertView && _alertView.visible) return;
  
  if (title) [_alertView setTitle:title];
  if (message) [_alertView setMessage:message];
  
  [_alertView show];
  
  // Fire a timer to dismiss alertView
//  if (_alertTimer && [_alertTimer isValid]) {
//    INVALIDATE_TIMER(_alertTimer);
//  }
//  
//  NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
//  [userInfo setObject:_alertView forKey:@"alertView"];
//  if (delegate) [userInfo setObject:delegate forKey:@"delegate"];
//  
//  _alertTimer = [[NSTimer timerWithTimeInterval:1.5 target:self selector:@selector(dismissAlertFromTimer:) userInfo:userInfo repeats:NO] retain];
//  [[NSRunLoop currentRunLoop] addTimer:_alertTimer forMode:NSDefaultRunLoopMode];
}

- (void)dismissAlertFromTimer:(NSTimer*)theTimer {
//  NSDictionary *userInfo = [theTimer userInfo];
//  UIAlertView *alertView = [userInfo objectForKey:@"alertView"];
//  [alertView dismissWithClickedButtonIndex:alertView.cancelButtonIndex animated:YES];
}

- (void)dealloc {
  RELEASE_SAFELY(_alertView);
  INVALIDATE_TIMER(_alertTimer);
  [super dealloc];
}

@end
