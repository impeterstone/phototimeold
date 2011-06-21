//
//  PSAlertCenter.h
//  Orca
//
//  Created by Peter Shih on 6/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSObject.h"

@interface PSAlertCenter : PSObject {
  UIAlertView *_alertView;
  NSTimer *_alertTimer;
}

+ (PSAlertCenter *)defaultCenter;

- (void)postAlertWithTitle:(NSString *)title andMessage:(NSString *)message andDelegate:(id)delegate;

- (void)dismissAlertFromTimer:(NSTimer*)theTimer;

@end
