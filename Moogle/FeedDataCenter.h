//
//  FeedDataCenter.h
//  Moogle
//
//  Created by Peter Shih on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoogleDataCenter.h"

@interface FeedDataCenter : MoogleDataCenter {
}

- (void)loadFeedsFromFixture;

- (void)serializeFeedsWithDictionary:(NSDictionary *)dictionary;

/**
 Fetch Requests
 */
- (NSFetchRequest *)getFeedsFetchRequestForPod:(NSNumber *)podId;

@end
