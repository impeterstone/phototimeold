//
//  HeaderTabViewDelegate.h
//  Photomunk
//
//  Created by Peter Shih on 3/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol HeaderTabViewDelegate <NSObject>
@optional
- (void)tabSelectedAtIndex:(NSNumber *)index;
@end
