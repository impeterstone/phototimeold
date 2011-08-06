//
//  Photo+Serialize.h
//  PhotoTime
//
//  Created by Peter Shih on 4/26/11.
//  Copyright 2011 Seven Minute Labs, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Photo.h"

@interface Photo (Serialize)

- (NSString *)fromPicture;

+ (Photo *)addPhotoWithDictionary:(NSDictionary *)dictionary forAlbumId:(NSString *)albumId inContext:(NSManagedObjectContext *)context;

- (Photo *)updatePhotoWithDictionary:(NSDictionary *)dictionary forAlbumId:(NSString *)albumId;

@end
