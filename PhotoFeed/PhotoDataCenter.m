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
  NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
  
  NSArray *sortedEntities = [array sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  
  NSMutableArray *sortedEntityIds = [NSMutableArray array];
  for (NSDictionary *entityDict in sortedEntities) {
    [sortedEntityIds addObject:[entityDict valueForKey:@"id"]];
  }
  
  NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
  [fetchRequest setEntity:[NSEntityDescription entityForName:@"Photo" inManagedObjectContext:context]];
  [fetchRequest setPredicate:[NSPredicate predicateWithFormat: @"(id IN %@)", sortedEntityIds]];
  [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"id" ascending:YES] autorelease]]];
  
  NSError *error = nil;
  NSArray *foundEntities = [context executeFetchRequest:fetchRequest error:&error];
  
  Photo *photo = nil;
  int i = 0;
  for (NSDictionary *entityDict in sortedEntities) {
    if ([foundEntities count] > 0 && i < [foundEntities count] && [[entityDict valueForKey:@"id"] isEqualToString:[[foundEntities objectAtIndex:i] id]]) {
      photo = [foundEntities objectAtIndex:i];
      //      DLog(@"found duplicated photo with id: %@", [[foundEntities objectAtIndex:i] id]);
      [photo updatePhotoWithDictionary:entityDict forAlbumId:albumId];
      i++;
    } else {
      // Insert
      photo = [Photo addPhotoWithDictionary:entityDict forAlbumId:albumId inContext:context];
    }
    
    // Serialize Comments
    if ([entityDict objectForKey:@"comments"]) {
      [self serializeCommentsWithDictionary:[entityDict objectForKey:@"comments"] forPhoto:photo inContext:context];
    }
    
    // Serialize Tags
    if ([entityDict objectForKey:@"tags"]) {
      [self serializeTagsWithDictionary:[entityDict objectForKey:@"tags"] forPhoto:photo inContext:context];
    }
  }
}

- (void)serializeCommentsWithDictionary:(NSDictionary *)dictionary forPhoto:(Photo *)photo inContext:(NSManagedObjectContext *)context {
  NSMutableSet *comments = [NSMutableSet set];
  
  // Check for dupes
  // photo may have existing comments, compare those with the new ones
  // comments don't ever get updated, no need to update, just insert new
  
  NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
  NSArray *existingComments = [photo.comments sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  
  NSArray *newComments = [[dictionary valueForKey:@"data"] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];

  int i = 0;
  for (NSDictionary *commentDict in newComments) {
    if ([existingComments count] > 0 && i < [existingComments count] && [[commentDict valueForKey:@"id"] isEqualToString:[[existingComments objectAtIndex:i] id]]) {
      // existing comment found
      VLog(@"found existing comment with id: %@", [[existingComments objectAtIndex:i] id]);
      i++;
    } else {
      [comments addObject:[Comment addCommentWithDictionary:commentDict inContext:context]];
    }
  }
  
  if ([comments count] > 0) {
    [photo addComments:comments];
  }
}

- (void)serializeTagsWithDictionary:(NSDictionary *)dictionary forPhoto:(Photo *)photo inContext:(NSManagedObjectContext *)context {
  NSMutableSet *tags = [NSMutableSet set];
  
  // Check for dupes
  // photo may have existing comments, compare those with the new ones
  // comments don't ever get updated, no need to update, just insert new
  
  NSArray *existingTags = [photo.tags sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"fromId" ascending:YES]]];
  
  NSArray *newTags = [[dictionary valueForKey:@"data"] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES]]];
  
  int i = 0;
  for (NSDictionary *tagDict in newTags) {
    if ([existingTags count] > 0 && i < [existingTags count] && [[tagDict valueForKey:@"id"] isEqualToString:[[existingTags objectAtIndex:i] fromId]]) {
      // existing comment found
      VLog(@"found existing tag with id: %@", [[existingTags objectAtIndex:i] fromId]);
      i++;
    } else {
      [tags addObject:[Tag addTagWithDictionary:tagDict inContext:context]];
    }
  }
  
  if ([tags count] > 0) {
    [photo addTags:tags];
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
