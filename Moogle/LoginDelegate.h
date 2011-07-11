//
//  LoginDelegate.h
//  Moogle
//
//  Created by Peter Shih on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol LoginDelegate <NSObject>
- (void)userDidLogin:(NSDictionary *)userInfo;
- (void)userDidLogout;
@end
