//
//  Search+Serialize.h
//  Moogle
//
//  Created by Peter Shih on 7/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Search.h"

@interface Search (Serialize)

+ (Search *)addSearchWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;

- (Search *)updateSearchWithDictionary:(NSDictionary *)dictionary;

@end
