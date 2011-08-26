//
//  FriendSelectDelegate.h
//  PhotoTime
//
//  Created by Peter Shih on 8/19/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FriendSelectDelegate <NSObject>
@optional
- (void)didSelectFriends:(NSArray *)friends withTitle:(NSString *)title;
@end
