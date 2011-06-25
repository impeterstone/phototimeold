//
//  ComposeDelegate.h
//  Orca
//
//  Created by Peter Shih on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol ComposeDelegate <NSObject>

@optional
- (void)composeDidSendWithUserInfo:(NSDictionary *)userInfo;

@end
