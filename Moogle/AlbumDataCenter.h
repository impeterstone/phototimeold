//
//  AlbumDataCenter.h
//  Moogle
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSDataCenter.h"

@interface AlbumDataCenter : PSDataCenter {
  NSMutableArray *_pendingResponses;
  NSUInteger _pendingRequestsToParse;
  NSUInteger _totalAlbumsToParse;
  NSUInteger _parseIndex;
}

+ (AlbumDataCenter *)defaultCenter;

/**
 Get albums from Server
 */
- (void)getAlbums;
- (void)getAlbumsForFriendIds:(NSArray *)friendIds;

/**
 Serialize server response into Album entities
 */
- (void)serializeAlbumsWithArray:(NSArray *)array inContext:(NSManagedObjectContext *)context;

- (void)parsePendingResponses;

@end
