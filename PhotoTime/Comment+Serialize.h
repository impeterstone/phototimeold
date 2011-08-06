//
//  Comment+Serialize.h
//  PhotoTime
//
//  Created by Peter Shih on 5/24/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Comment.h"

@interface Comment (Serialize)

+ (Comment *)addCommentWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;

@end
