//
//  Search+Serialize.m
//  PhotoTime
//
//  Created by Peter Shih on 7/12/11.
//  Copyright 2011 Seven Minute Labs, Inc.. All rights reserved.
//

#import "Search+Serialize.h"


@implementation Search (Serialize)

+ (Search *)addSearchWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context {
  if (dictionary) {
    Search *newSearch = [NSEntityDescription insertNewObjectForEntityForName:@"Search" inManagedObjectContext:context];
    
    newSearch.term = [dictionary objectForKey:@"term"];
    newSearch.count = [NSNumber numberWithInteger:1];
    newSearch.timestamp = [NSDate date];
    
    return newSearch;
  } else {
    return nil;
  }
}

- (Search *)updateSearchWithDictionary:(NSDictionary *)dictionary {
  if (dictionary) {
  }
  
  return self;
}

@end
