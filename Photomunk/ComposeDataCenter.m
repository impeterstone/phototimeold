//
//  ComposeDataCenter.m
//  Photomunk
//
//  Created by Peter Shih on 4/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ComposeDataCenter.h"

@implementation ComposeDataCenter

+ (ComposeDataCenter *)defaultCenter {
  static ComposeDataCenter *defaultCenter = nil;
  if (!defaultCenter) {
    defaultCenter = [[self alloc] init];
  }
  return defaultCenter;
}

- (void)sendCommentForPhotoId:(NSString *)photoId withMessage:(NSString *)message {
  NSURL *commentURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/comments", FB_GRAPH, photoId]];
  
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  [params setValue:message forKey:@"message"];
  
  [self sendRequestWithURL:commentURL andMethod:POST andHeaders:nil andParams:params andUserInfo:nil];
}
- (void)dataCenterRequestFinished:(ASIHTTPRequest *)request {
  id response = [[request responseData] JSONValue];
  if (_delegate && [_delegate respondsToSelector:@selector(dataCenterDidFinish:withResponse:)]) {
    [_delegate performSelector:@selector(dataCenterDidFinish:withResponse:) withObject:request withObject:response];
  }
}

- (void)dataCenterRequestFailed:(ASIHTTPRequest *)request {
  if (_delegate && [_delegate respondsToSelector:@selector(dataCenterDidFail:withError:)]) {
    [_delegate performSelector:@selector(dataCenterDidFail:withError:) withObject:request withObject:[request error]];
  }
}

@end
