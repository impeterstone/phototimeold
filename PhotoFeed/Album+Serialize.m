//
//  Album+Serialize.m
//  PhotoFeed
//
//  Created by Peter Shih on 4/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Album+Serialize.h"
#import "NSDate+Helper.h"

@implementation Album (Serialize)

#pragma mark -
#pragma mark Transient Properties
- (NSString *)daysAgo {
  //  NSInteger day = 24 * 60 * 60;
  //  
  //  NSInteger delta = [self.timestamp timeIntervalSinceNow];
  //  delta *= -1;
  //  
  //  if (delta < 1 * day) {
  //    return @"Today";
  //  } else {
  //    return [NSString stringWithFormat:@"%d days ago", delta / day];
  //  }
  
  //  return [self.timestamp stringDaysAgoAgainstMidnight:YES];
  return [NSDate stringForDisplayFromDate:self.timestamp];
}

- (NSString *)lastViewedDaysAgo {
  return [NSDate stringForDisplayFromDate:self.lastViewed];
}

+ (NSString *)fromNameForFromId:(NSString *)fromId {
  static NSString *facebookId = nil;
  static NSString *facebookName = nil;
  static NSDictionary *facebookFriends = nil;
  
  // This is a hack for logging out
  BOOL hasCachedFriends = [[NSUserDefaults standardUserDefaults] boolForKey:@"hasCachedFriends"];
  
  if (!hasCachedFriends) {
    if (facebookId) [facebookId release], facebookId = nil;
    if (facebookName) [facebookName release], facebookName = nil;
    if (facebookFriends) [facebookFriends release], facebookFriends = nil;
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasCachedFriends"];
  }
  
  if (!facebookId) {
    facebookId = [[[NSUserDefaults standardUserDefaults] stringForKey:@"facebookId"] copy];
  }
  if (!facebookName) {
    facebookName = [[[NSUserDefaults standardUserDefaults] stringForKey:@"facebookName"] copy];
  }
  if (!facebookFriends) {
    facebookFriends = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"facebookFriends"] copy];
  }

  // My own ID
  if ([fromId isEqualToString:facebookId]) {
    return facebookName;
  } else {
    // This does a facebook id => name lookup in the local friends dict
    NSString *friendName = [facebookFriends valueForKey:fromId];
    return friendName ? friendName : @"Anonymous";
  }
}

#pragma mark -
#pragma mark Create/Update
+ (Album *)addAlbumWithDictionary:(NSDictionary *)dictionary andCover:(NSString *)cover inContext:(NSManagedObjectContext *)context {
  /*
   // BAD
   aid = "100002385998437_-3";
   "can_upload" = 0;
   "cover_pid" = 0;
   created = "<null>";
   description = "";
   location = "";
   modified = "<null>";
   "modified_major" = "<null>";
   name = "Profile Pictures";
   owner = 100002385998437;
   size = 0;
   type = profile;
   
   // GOOD
   aid = "100002412788438_4071";
   "can_upload" = 0;
   "cover_pid" = "100002412788438_14137";
   created = 1305365273;
   description = "";
   location = "";
   modified = 1305365273;
   "modified_major" = 1305365273;
   name = "Webcam Photos";
   owner = 100002412788438;
   size = 1;
   type = wall;
   */
  
  if (dictionary) {
    // Check for invalid albums, if found ignore them
    if ([[dictionary valueForKey:@"size"] integerValue] == 0) {
      return nil;
    }
    
    Album *newAlbum = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext:context];
    
    // Basic
    id objectId = [dictionary valueForKey:@"object_id"];
    if ([objectId isKindOfClass:[NSNumber class]]) {
      newAlbum.objectId = objectId; // this is used as index/sortkey (int64)
      newAlbum.id = [objectId stringValue];
    } else if ([objectId isKindOfClass:[NSString class]]) {
      // this should never happen
      NSLog(@"### serious error, object_id is a string ###");
      newAlbum.objectId = [NSNumber numberWithInteger:[objectId integerValue]];
      newAlbum.id = objectId;
    }
    
    newAlbum.aid = [dictionary valueForKey:@"aid"]; // used for sorting/indexing/serializing
    newAlbum.name = [dictionary valueForKey:@"name"];
    newAlbum.type = [dictionary valueForKey:@"type"];
    
    // Can-be-empty
    newAlbum.coverPhoto = cover ? cover : nil;
    
    // Some albums may not have a cover photo
//    if (![dictionary valueForKey:@"cover_pid"]) {
//      NSLog(@"uh oh, no cover photo for: %@", [dictionary valueForKey:@"object_id"]);
//    }
    
    newAlbum.caption = [dictionary valueForKey:@"description"] ? [dictionary valueForKey:@"description"] : nil;
    newAlbum.location = [dictionary valueForKey:@"location"] ? [dictionary valueForKey:@"location"] : nil;
    
    // Counts
    newAlbum.count = [dictionary valueForKey:@"size"] ? [dictionary valueForKey:@"size"] : [NSNumber numberWithInteger:0];
    
    // Author/From
    id ownerId = [dictionary valueForKey:@"owner"];
    if ([ownerId isKindOfClass:[NSNumber class]]) {
      ownerId = [ownerId stringValue];
    }
    newAlbum.fromId = ownerId;
    newAlbum.fromName = [Album fromNameForFromId:ownerId];
    
    // Can Upload
    newAlbum.canUpload = [dictionary valueForKey:@"can_upload"];
    
    // Timestamp
    if ([dictionary valueForKey:@"modified_major"]) {
      newAlbum.timestamp = [NSDate dateWithTimeIntervalSince1970:[[dictionary valueForKey:@"modified_major"] longLongValue]];
    } else if ([dictionary valueForKey:@"created"]) {
      newAlbum.timestamp = [NSDate dateWithTimeIntervalSince1970:[[dictionary valueForKey:@"created"] longLongValue]];
    } else if ([dictionary valueForKey:@"modified"]) {
      newAlbum.timestamp = [NSDate dateWithTimeIntervalSince1970:[[dictionary valueForKey:@"modified"] longLongValue]];
    } else {
      newAlbum.timestamp = [NSDate distantPast];
    }
    
    return newAlbum;
  } else {
    return nil;
  }
}

- (Album *)updateAlbumWithDictionary:(NSDictionary *)dictionary andCover:(NSString *)cover {
  if (dictionary) {
    // Check for invalid albums, if found ignore them
    if ([[dictionary valueForKey:@"size"] integerValue] == 0) {
      return nil;
    }
    
    // For some reason, facebook's api is really bad about cover photos
//    if ([dictionary valueForKey:@"cover_pid"] && !self.coverPhoto) {
//      NSLog(@"cover photo recovered for: %@", [dictionary valueForKey:@"object_id"]);
//      self.coverPhoto = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", [dictionary valueForKey:@"cover_pid"]];
//    }
  
    // Check to see if this album has actually changed
    NSDate *newDate = nil;
    if ([dictionary valueForKey:@"modified_major"]) {
      newDate = [NSDate dateWithTimeIntervalSince1970:[[dictionary valueForKey:@"modified_major"] longLongValue]];
    } else if ([dictionary valueForKey:@"created"]) {
      newDate = [NSDate dateWithTimeIntervalSince1970:[[dictionary valueForKey:@"created"] longLongValue]];
    } else if ([dictionary valueForKey:@"modified"]) {
      newDate = [NSDate dateWithTimeIntervalSince1970:[[dictionary valueForKey:@"modified"] longLongValue]];
    } else {
      newDate = [NSDate distantPast];
    }
    
    if ([self.timestamp isEqualToDate:newDate]) {
      return self;
    } else {
      self.timestamp = newDate;
    }
   
    // If dates are not the same, then perform an update
    
    // Basic
    self.name = [dictionary valueForKey:@"name"];
    self.type = [dictionary valueForKey:@"type"];
    
    // Can-be-empty
    self.coverPhoto = cover ? cover : nil;
    
    self.caption = [dictionary valueForKey:@"description"] ? [dictionary valueForKey:@"description"] : nil;
    self.location = [dictionary valueForKey:@"location"] ? [dictionary valueForKey:@"location"] : nil;
    
    // Counts
    self.count = [dictionary valueForKey:@"size"] ? [dictionary valueForKey:@"size"] : [NSNumber numberWithInteger:0];
    
    // Author/From
    id ownerId = [dictionary valueForKey:@"owner"];
    if ([ownerId isKindOfClass:[NSNumber class]]) {
      ownerId = [ownerId stringValue];
    }
    self.fromId = ownerId;
    self.fromName = [Album fromNameForFromId:ownerId];
    
    // Can Upload
    self.canUpload = [dictionary valueForKey:@"can_upload"];
    
    return self;
  } else {
    return nil;
  }
}

@end
