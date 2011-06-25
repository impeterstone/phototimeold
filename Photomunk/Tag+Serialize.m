//
//  Tag+Serialize.m
//  Photomunk
//
//  Created by Peter Shih on 6/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Tag+Serialize.h"


@implementation Tag (Serialize)

/*
 {
 "id": "543612099",
 "name": "Alex Chan",
 "x": 43.8889,
 "y": 25.1852,
 "created_time": 1258748585
 }
 */

+ (Tag *)addTagWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context {
  if (dictionary) {
    Tag *newTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:context];
    
    // Basic
    newTag.fromId = [dictionary valueForKey:@"id"];
    newTag.fromName = [dictionary valueForKey:@"name"];
    newTag.x = [dictionary valueForKey:@"x"];
    newTag.y = [dictionary valueForKey:@"y"];
    
    // Timestamp
    if ([dictionary valueForKey:@"created_time"]) {
      newTag.timestamp = [NSDate dateWithTimeIntervalSince1970:[[dictionary valueForKey:@"created_time"] longLongValue]];
    } else {
      newTag.timestamp = [NSDate distantPast];
    }
    
    return newTag;
  } else {
    return nil;
  }
}

@end
