//
//  PhotoDataCenter.m
//  PhotoFeed
//
//  Created by Peter Shih on 4/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PhotoDataCenter.h"
#import "Photo.h"
#import "Photo+Serialize.h"
#import "Comment.h"
#import "Comment+Serialize.h"
#import "Tag.h"
#import "Tag+Serialize.h"

@implementation PhotoDataCenter

- (id)init {
  self = [super init];
  if (self) {
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coreDataDidReset) name:kCoreDataDidReset object:nil];
  }
  return self;
}

#pragma mark -
#pragma mark Prepare Request
- (void)getPhotosForAlbumId:(NSString *)albumId {
  NSURL *photosUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/photos", FB_GRAPH, albumId]];
  
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  [params setValue:@"0" forKey:@"limit"];
  [params setValue:@"U" forKey:@"date_format"]; // unix timestamp
  
  [self sendRequestWithURL:photosUrl andMethod:GET andHeaders:nil andParams:params andUserInfo:[NSDictionary dictionaryWithObject:albumId forKey:@"albumId"]];
}

#pragma mark -
#pragma mark Serialization
- (void)serializePhotosWithRequest:(ASIHTTPRequest *)request {
  NSManagedObjectContext *context = [PSCoreDataStack newManagedObjectContext];
  
  // Parse the JSON
  id response = [[request responseData] JSONValue];
  
  // AlbumId from the userInfo
  NSString *albumId = [request.userInfo valueForKey:@"albumId"];
  
  // Process the Response for Photos
  if ([response isKindOfClass:[NSDictionary class]]) {
    if ([response objectForKey:@"data"]) {
      [self serializePhotosWithArray:[response objectForKey:@"data"] forAlbumId:albumId inContext:context];
    }
  }

  // Save to Core Data
  [PSCoreDataStack saveInContext:context];
  [context release];
 
  [self performSelectorOnMainThread:@selector(serializePhotosFinishedWithRequest:) withObject:request waitUntilDone:NO];
}

- (void)serializePhotosFinishedWithRequest:(ASIHTTPRequest *)request {
  // Inform Delegate
  if (_delegate && [_delegate respondsToSelector:@selector(dataCenterDidFinish:withResponse:)]) {
    [_delegate performSelector:@selector(dataCenterDidFinish:withResponse:) withObject:request withObject:nil];
  }
}

#pragma mark Core Data Serialization
- (void)serializePhotosWithArray:(NSArray *)array forAlbumId:(NSString *)albumId inContext:(NSManagedObjectContext *)context {
  NSString *uniqueKey = @"id";
  NSString *entityName = @"Photo";
  
  // Find all existing Pods
  NSArray *newUniqueKeyArray = [array valueForKey:uniqueKey];
  NSFetchRequest *existingFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
  [existingFetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:context]];
  [existingFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(%K IN %@)", uniqueKey, newUniqueKeyArray]];
  [existingFetchRequest setPropertiesToFetch:[NSArray arrayWithObject:uniqueKey]];
  
  NSError *error = nil;
  NSArray *foundEntities = [context executeFetchRequest:existingFetchRequest error:&error];
  
  // Create a dictionary of existing pods
  NSMutableDictionary *existingEntities = [NSMutableDictionary dictionary];
  for (id foundEntity in foundEntities) {
    [existingEntities setObject:foundEntity forKey:[foundEntity valueForKey:uniqueKey]];
  }
  
  Photo *existingEntity = nil;
  for (NSDictionary *newEntity in array) {
    NSString *key = [newEntity valueForKey:uniqueKey];
    existingEntity = [existingEntities objectForKey:key];
    if (existingEntity) {
      // update
      [existingEntity updatePhotoWithDictionary:newEntity forAlbumId:albumId];
    } else {
      // insert
      existingEntity = [Photo addPhotoWithDictionary:newEntity forAlbumId:albumId inContext:context];
    }
    
    // Serialize Comments
    if ([newEntity objectForKey:@"comments"]) {
      [self serializeCommentsWithDictionary:[newEntity objectForKey:@"comments"] forPhoto:existingEntity inContext:context];
    }
    
    // Serialize Tags
    if ([newEntity objectForKey:@"tags"]) {
      [self serializeTagsWithDictionary:[newEntity objectForKey:@"tags"] forPhoto:existingEntity inContext:context];
    }
  }
}

- (void)serializeCommentsWithDictionary:(NSDictionary *)dictionary forPhoto:(Photo *)photo inContext:(NSManagedObjectContext *)context {
  // Check for dupes
  // photo may have existing comments, compare those with the new ones
  // comments don't ever get updated, no need to update, just insert new
  NSSet *existingCommentIds = [photo.comments valueForKey:@"id"];
  NSArray *newComments = [dictionary valueForKey:@"data"];
  
  // Add only new comments to a set
  NSMutableSet *comments = [NSMutableSet set];
  for (NSDictionary *newComment in newComments) {
    if (![existingCommentIds containsObject:[newComment objectForKey:@"id"]]) {
      [comments addObject:[Comment addCommentWithDictionary:newComment inContext:context]];
    }
  }

  if ([comments count] > 0) {
    [photo performSelector:@selector(addComments:) withObject:comments];
  }
}

- (void)serializeTagsWithDictionary:(NSDictionary *)dictionary forPhoto:(Photo *)photo inContext:(NSManagedObjectContext *)context {
  // Check for dupes
  // photo may have existing tags, compare those with the new ones
  // tags don't ever get updated, no need to update, just insert new
  NSSet *existingTagIds = [photo.tags valueForKey:@"fromId"];
  NSArray *newTags = [dictionary valueForKey:@"data"];
  
  // Add only new tags to a set
  NSMutableSet *tags = [NSMutableSet set];
  for (NSDictionary *newTag in newTags) {
    if (![existingTagIds containsObject:[newTag objectForKey:@"id"]]) {
      [tags addObject:[Tag addTagWithDictionary:newTag inContext:context]];
    }
  }
  
  if ([tags count] > 0) {
    [photo performSelector:@selector(addTags:) withObject:tags];
  }
}

#pragma mark -
#pragma mark PSDataCenterDelegate
- (void)dataCenterRequestFinished:(ASIHTTPRequest *)request {
  NSInvocationOperation *parseOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(serializePhotosWithRequest:) object:request];
  [[PSParserStack sharedParser] addOperation:parseOp];
  [parseOp release];
}

- (void)dataCenterRequestFailed:(ASIHTTPRequest *)request {
  // Inform Delegate
  if (_delegate && [_delegate respondsToSelector:@selector(dataCenterDidFail:withError:)]) {
    [_delegate performSelector:@selector(dataCenterDidFail:withError:) withObject:request withObject:[request error]];
  }
}

@end
