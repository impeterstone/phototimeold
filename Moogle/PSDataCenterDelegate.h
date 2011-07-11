/*
 *  PSDataCenterDelegate.h
 *  Moogle
 *
 *  Created by Peter Shih on 2/22/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

@class ASIHTTPRequest;

@protocol PSDataCenterDelegate <NSObject>

@optional
- (void)dataCenterDidFinish:(ASIHTTPRequest *)request withResponse:(id)response;
- (void)dataCenterDidFail:(ASIHTTPRequest *)request withError:(NSError *)error;

@end
