//
//  PhotoDataCenter.h
//  Moogle
//
//  Created by Peter Shih on 4/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSDataCenter.h"

@class Photo;

@interface PhotoDataCenter : PSDataCenter {
}

+ (PhotoDataCenter *)defaultCenter;

/**
 Get photos from Server
 */
- (void)getPhotosForAlbumId:(NSString *)albumId;

/**
 Like a photo
 */
- (void)addLikeForPhotoId:(NSString *)photoId;

/**
 Un-Like a photo
 */
- (void)removeLikeForPhotoId:(NSString *)photoId;

/**
 Serialize server response into Photo entities
 */
- (void)serializePhotosWithRequest:(ASIHTTPRequest *)request;
- (void)serializePhotosWithArray:(NSArray *)array forAlbumId:(NSString *)albumId inContext:(NSManagedObjectContext *)context;

/**
 Serialize comments
 */
- (void)serializeCommentsWithDictionary:(NSDictionary *)dictionary forPhoto:(Photo *)photo inContext:(NSManagedObjectContext *)context;

/**
 Serialize Tags
 */
- (void)serializeTagsWithDictionary:(NSDictionary *)dictionary forPhoto:(Photo *)photo inContext:(NSManagedObjectContext *)context;

/**
 Insert a comment (user-generated)
 */
- (void)insertCommentWithDictionary:(NSDictionary *)dictionary forPhoto:(Photo *)photo inContext:(NSManagedObjectContext *)context;

@end
