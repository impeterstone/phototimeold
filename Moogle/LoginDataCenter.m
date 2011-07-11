//
//  LoginDataCenter.m
//  Moogle
//
//  Created by Peter Shih on 3/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LoginDataCenter.h"

@implementation LoginDataCenter

+ (LoginDataCenter *)defaultCenter {
  static LoginDataCenter *defaultCenter = nil;
  if (!defaultCenter) {
    defaultCenter = [[self alloc] init];
  }
  return defaultCenter;
}

- (void)getMe {
  NSURL *meUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/me", FB_GRAPH]];
  
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  [params setValue:@"id,name,friends" forKey:@"fields"];
  
  [self sendRequestWithURL:meUrl andMethod:GET andHeaders:nil andParams:params andUserInfo:nil];
}

- (void)getFriends {
  NSURL *friendsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/me/friends", FB_GRAPH]];
  
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  
  [self sendRequestWithURL:friendsUrl andMethod:GET andHeaders:nil andParams:params andUserInfo:[NSDictionary dictionaryWithObject:@"friends" forKey:@"loginRequestType"]];
}

#pragma mark -
#pragma mark Request finished
- (void)dataCenterRequestFinished:(ASIHTTPRequest *)request {
  id response = [[request responseData] JSONValue];
  
  // Inform Delegate
  if (_delegate && [_delegate respondsToSelector:@selector(dataCenterDidFinish:withResponse:)]) {
    [_delegate performSelector:@selector(dataCenterDidFinish:withResponse:) withObject:request withObject:response];
  }
}

- (void)dataCenterRequestFailed:(ASIHTTPRequest *)request {
  // Inform Delegate
  if (_delegate && [_delegate respondsToSelector:@selector(dataCenterDidFail:withError:)]) {
    [_delegate performSelector:@selector(dataCenterDidFail:withError:) withObject:request withObject:[request error]];
  }
}

@end