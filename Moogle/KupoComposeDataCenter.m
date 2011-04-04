//
//  KupoComposeDataCenter.m
//  Moogle
//
//  Created by Peter Shih on 4/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "KupoComposeDataCenter.h"
#import "MoogleLocation.h"

@implementation KupoComposeDataCenter

- (void)sendKupoComposeWithPlaceId:(NSString *)placeId andComment:(NSString *)comment andImage:(UIImage *)image andVideo:(NSData *)video {
  NSURL *kupoComposeUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/kupos/new", MOOGLE_BASE_URL]];
  
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  
  BOOL hasImage = NO;
  
  [params setValue:@"1" forKey:@"kupo_type"];
  
  if ([comment length] > 0) {
    [params setValue:comment forKey:@"comment"];
  }
  
  if (image) {
    hasImage = YES;
    [params setValue:image forKey:@"image"];
    if (video) {
      [params setValue:video forKey:@"video"];
    }
  }
  
  [params setValue:placeId forKey:@"place_id"];
  
  [self sendOperationWithURL:kupoComposeUrl andMethod:POST andHeaders:nil andParams:params isFormData:hasImage];
}

- (void)sendCheckinComposeWithPlaceId:(NSString *)placeId andComment:(NSString *)comment andImage:(UIImage *)image andVideo:(NSData *)video {
  // params[:message], params[:place], params[:lat], params[:lng], params[:tags]
  
  NSURL *checkinComposeUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/checkins/new", MOOGLE_BASE_URL]];
  
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  
  BOOL hasImage = NO;
  
  [params setValue:@"0" forKey:@"kupo_type"];
  
  if ([comment length] > 0) {
    [params setValue:comment forKey:@"comment"];
  }

  if (image) {
    hasImage = YES;
    [params setValue:image forKey:@"image"];
    if (video) {
      [params setValue:video forKey:@"video"];
    }
  }
  
  [params setValue:placeId forKey:@"place_id"];
  
  // Location
  CGFloat lat = [[MoogleLocation sharedInstance] latitude];
  CGFloat lng = [[MoogleLocation sharedInstance] longitude];
  [params setObject:[NSString stringWithFormat:@"%f", lat] forKey:@"lat"];
  [params setObject:[NSString stringWithFormat:@"%f", lng] forKey:@"lng"];
  
  [self sendOperationWithURL:checkinComposeUrl andMethod:POST andHeaders:nil andParams:params isFormData:hasImage];
}

- (void)dataCenterFinishedWithOperation:(LINetworkOperation *)operation {
  [super dataCenterFinishedWithOperation:operation];
}

- (void)dataCenterFailedWithOperation:(LINetworkOperation *)operation {
  [super dataCenterFailedWithOperation:operation];
}

@end