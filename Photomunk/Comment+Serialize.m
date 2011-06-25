//
//  Comment+Serialize.m
//  Photomunk
//
//  Created by Peter Shih on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Comment+Serialize.h"
#import "NSDate+Helper.h"

@implementation Comment (Serialize)

+ (Comment *)addCommentWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context {
  if (dictionary) {
    Comment *newComment = [NSEntityDescription insertNewObjectForEntityForName:@"Comment" inManagedObjectContext:context];
    
    // Basic
    // Coerce ID to string
    id entityId = [dictionary valueForKey:@"id"];
    if ([entityId isKindOfClass:[NSNumber class]]) {
      entityId = [entityId stringValue];
    }
    newComment.id = entityId;
    newComment.message = [dictionary valueForKey:@"message"];
    
    // Author/From
    NSDictionary *from = [dictionary valueForKey:@"from"];
    
    // Coerce ID to string
    id fromId = [from valueForKey:@"id"];
    if ([fromId isKindOfClass:[NSNumber class]]) {
      fromId = [fromId stringValue];
    }
    newComment.fromId = fromId;
    newComment.fromName = [from valueForKey:@"name"];
    
    // Timestamp
    if ([dictionary valueForKey:@"created_time"]) {
      newComment.timestamp = [NSDate dateWithTimeIntervalSince1970:[[dictionary valueForKey:@"created_time"] longLongValue]];
    } else {
      newComment.timestamp = [NSDate distantPast];
    }
    
    return newComment;
  } else {
    return nil;
  }
}

@end
