//
//  SearchTermDelegate.h
//  Moogle
//
//  Created by Peter Shih on 7/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol SearchTermDelegate <NSObject>

@optional
- (void)searchTermSelected:(NSString *)searchTerm;

@end
