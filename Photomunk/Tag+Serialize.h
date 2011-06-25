//
//  Tag+Serialize.h
//  Photomunk
//
//  Created by Peter Shih on 6/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tag.h"

@interface Tag (Serialize)

+ (Tag *)addTagWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;

@end
