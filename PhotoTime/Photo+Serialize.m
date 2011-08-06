//
//  Photo+Serialize.m
//  PhotoTime
//
//  Created by Peter Shih on 4/26/11.
//  Copyright 2011 Seven Minute Labs, Inc.. All rights reserved.
//

#import "Photo+Serialize.h"
#import "NSDate+Helper.h"

@implementation Photo (Serialize)

#pragma mark -
#pragma mark Transient Properties
- (NSString *)fromPicture {
  return [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=square", self.fromId];
}

#pragma mark -
#pragma mark Create/Update
+ (Photo *)addPhotoWithDictionary:(NSDictionary *)dictionary forAlbumId:(NSString *)albumId inContext:(NSManagedObjectContext *)context {
  if (dictionary) {
    
    if (![dictionary valueForKey:@"width"] || ![dictionary valueForKey:@"height"]) {
      // width or height was not provided, this is a bogus picture
      return nil;
    }
    
    Photo *newPhoto = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
    
    // AlbumId
    newPhoto.albumId = albumId;
    
    // Basic
    // Coerce ID to string
    id entityId = [dictionary valueForKey:@"id"];
    if ([entityId isKindOfClass:[NSNumber class]]) {
      entityId = [entityId stringValue];
    }
    newPhoto.id = entityId;
    newPhoto.name = [dictionary valueForKey:@"name"];
    newPhoto.position = [dictionary valueForKey:@"position"];
    
    // Photo
    newPhoto.picture = [dictionary valueForKey:@"picture"];
    newPhoto.source = [dictionary valueForKey:@"source"];
    
    // Dimensions
    // Apparently this can be nil
    newPhoto.width = [dictionary valueForKey:@"width"];
    newPhoto.height = [dictionary valueForKey:@"height"];
    
    // Author/From
    NSDictionary *from = [dictionary valueForKey:@"from"];
    // Coerce ID to string
    id fromId = [from valueForKey:@"id"];
    if ([fromId isKindOfClass:[NSNumber class]]) {
      fromId = [fromId stringValue];
    }
    newPhoto.fromId = fromId;
    newPhoto.fromName = [from valueForKey:@"name"];
    
    // Timestamp
    if ([dictionary valueForKey:@"updated_time"]) {
      newPhoto.timestamp = [NSDate dateWithTimeIntervalSince1970:[[dictionary valueForKey:@"updated_time"] longLongValue]];
    } else if ([dictionary valueForKey:@"created_time"]) {
      newPhoto.timestamp = [NSDate dateWithTimeIntervalSince1970:[[dictionary valueForKey:@"created_time"] longLongValue]];
    } else {
      newPhoto.timestamp = [NSDate distantPast];
    }
    
    return newPhoto;
  } else {
    return nil;
  }
}

- (Photo *)updatePhotoWithDictionary:(NSDictionary *)dictionary forAlbumId:(NSString *)albumId {  
  if (dictionary) {
    // Photos don't really update unless position changes
    if ([self.position isEqualToNumber:[dictionary valueForKey:@"position"]]) {
      return self;
    }
    
    // Basic
    self.name = [dictionary valueForKey:@"name"];
    self.position = [dictionary valueForKey:@"position"];
    
    // Photo
    self.picture = [dictionary valueForKey:@"picture"];
    self.source = [dictionary valueForKey:@"source"];
    
    // Dimensions
    self.width = [dictionary valueForKey:@"width"];
    self.height = [dictionary valueForKey:@"height"];
    
    // Author/From
    NSDictionary *from = [dictionary valueForKey:@"from"];
    // Coerce ID to string
    id fromId = [from valueForKey:@"id"];
    if ([fromId isKindOfClass:[NSNumber class]]) {
      fromId = [fromId stringValue];
    }
    self.fromId = fromId;
    self.fromName = [from valueForKey:@"name"];
    
    // Timestamp
    if ([dictionary valueForKey:@"updated_time"]) {
      self.timestamp = [NSDate dateWithTimeIntervalSince1970:[[dictionary valueForKey:@"updated_time"] longLongValue]];
    } else if ([dictionary valueForKey:@"created_time"]) {
      self.timestamp = [NSDate dateWithTimeIntervalSince1970:[[dictionary valueForKey:@"created_time"] longLongValue]];
    } else {
      self.timestamp = [NSDate distantPast];
    }
    
    return self;
  } else {
    return nil;
  }
}

@end
